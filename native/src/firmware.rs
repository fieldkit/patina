use anyhow::{anyhow, Context, Result};
use discovery::DeviceId;
use query::portal::Firmware;
use std::path::PathBuf;
use tokio::{
    fs::OpenOptions,
    io::{AsyncReadExt, AsyncWriteExt},
    pin,
    sync::mpsc::Sender,
};
use tokio_stream::StreamExt;
use tracing::*;

use crate::nearby::NearbyDevices;

use super::api::*;

pub struct CheckForAndCacheFirmware {
    pub portal_base_url: String,
    pub storage_path: String,
    pub publish_tx: Sender<DomainMessage>,
    pub tokens: Option<Tokens>,
}

impl CheckForAndCacheFirmware {
    async fn run(&self) -> Result<()> {
        let cached = match check_cached_firmware(&self.storage_path).await {
            Err(e) => {
                warn!("Error checking cached firmware: {:?}", e);

                let message = DomainMessage::FirmwareDownloadStatus(FirmwareDownloadStatus::Failed);

                self.publish_tx.send(message).await?;

                return Ok(());
            }
            Ok(cached) => cached,
        };

        match cache_firmware_and_json_if_newer(
            &self.portal_base_url,
            self.tokens.clone(),
            &self.storage_path,
            cached,
            self.publish_tx.clone(),
        )
        .await
        {
            Err(e) => {
                warn!("Error caching firmware: {:?}", e);

                let message =
                    DomainMessage::FirmwareDownloadStatus(FirmwareDownloadStatus::Offline);

                self.publish_tx.send(message).await?;

                return Ok(());
            }
            Ok(_) => {}
        };

        Ok(())
    }
}

pub async fn cache_firmware(
    portal_base_url: String,
    storage_path: String,
    publish_tx: Sender<DomainMessage>,
    tokens: Option<Tokens>,
) -> Result<FirmwareDownloadStatus> {
    let task = CheckForAndCacheFirmware {
        portal_base_url,
        storage_path,
        publish_tx,
        tokens,
    };
    tokio::task::spawn(async move {
        match task.run().await {
            Err(e) => warn!("Error caching firmware: {:?}", e),
            Ok(_) => {}
        }
    });

    Ok(FirmwareDownloadStatus::Checking)
}

pub struct FirmwareUpgrader {
    nearby: NearbyDevices,
    publish_tx: Sender<DomainMessage>,
    storage_path: String,
    device_id: DeviceId,
    firmware: LocalFirmware,
    swap: bool,
    addr: String,
}

impl FirmwareUpgrader {
    async fn publish(&self, status: UpgradeStatus) -> Result<()> {
        Ok(self
            .publish_tx
            .send(DomainMessage::UpgradeProgress(UpgradeProgress {
                device_id: self.device_id.0.clone(),
                firmware_id: self.firmware.id,
                status,
            }))
            .await?)
    }

    async fn run(&self) -> Result<()> {
        let path =
            PathBuf::from(&self.storage_path).join(format!("firmware-{}.bin", self.firmware.id));

        let device_id = self.device_id.clone();
        let client = query::device::Client::new()?;
        match client.upgrade(&self.addr, &path, self.swap).await {
            Ok(mut stream) => {
                let mut failed = false;

                while let Some(res) = stream.next().await {
                    match res {
                        Ok(bytes) => {
                            self.publish(UpgradeStatus::Uploading(UploadProgress {
                                bytes_uploaded: bytes.bytes_uploaded,
                                total_bytes: bytes.total_bytes,
                            }))
                            .await?;
                        }
                        Err(_) => {
                            self.publish(UpgradeStatus::Failed).await?;

                            failed = true;
                        }
                    }
                }

                if !failed {
                    if self.swap {
                        self.publish(UpgradeStatus::Restarting).await?;

                        match wait_for_station_restart(&self.addr).await {
                            Ok(_) => {
                                self.publish(UpgradeStatus::Completed).await?;
                            }
                            Err(_) => {
                                self.publish(UpgradeStatus::Failed).await?;
                            }
                        }
                    } else {
                        self.publish(UpgradeStatus::Completed).await?;
                    }
                }

                self.nearby.mark_busy(&device_id, false).await?;

                Ok(())
            }
            Err(e) => {
                warn!("Error: {:?}", e);

                self.publish(UpgradeStatus::Failed).await?;

                self.nearby.mark_busy(&device_id, false).await?;

                Ok(())
            }
        }
    }
}

pub async fn upgrade(
    nearby: NearbyDevices,
    publish_tx: Sender<DomainMessage>,
    storage_path: String,
    device_id: DeviceId,
    firmware: LocalFirmware,
    swap: bool,
    addr: String,
) -> Result<UpgradeProgress> {
    let upgrader = FirmwareUpgrader {
        nearby: nearby.clone(),
        publish_tx,
        storage_path,
        device_id: device_id.clone(),
        firmware: firmware.clone(),
        swap,
        addr,
    };

    nearby.mark_busy(&device_id, true).await?;

    tokio::task::spawn(async move {
        match upgrader.run().await {
            Err(e) => warn!("Error upgrading: {:?}", e),
            Ok(_) => {}
        }
    });

    Ok(UpgradeProgress {
        device_id: device_id.0.clone(),
        firmware_id: firmware.id,
        status: UpgradeStatus::Starting,
    })
}

async fn wait_for_station_restart(addr: &str) -> Result<()> {
    use std::time::Duration;
    use tokio::time::sleep;

    for i in 0..30 {
        sleep(Duration::from_secs(if i == 0 { 5 } else { 1 })).await;

        info!("upgrade: Checking station");
        let client = query::device::Client::new()?;
        match client.query_status(addr).await {
            Err(e) => info!("upgrade: Waiting for station: {:?}", e),
            Ok(_) => {
                return Ok(());
            }
        }
    }

    Err(anyhow!("Station did not come back online."))
}

async fn check_cached_firmware(storage_path: &str) -> Result<Vec<Firmware>> {
    let mut found = Vec::new();
    let pattern = format!("{}/firmware*.json", storage_path);
    for path in glob::glob(&pattern)? {
        let mut reading = OpenOptions::new().read(true).open(&path?).await?;
        let mut buffer = String::new();
        reading.read_to_string(&mut buffer).await?;
        found.push(serde_json::from_str(&buffer)?);
    }

    Ok(found)
}

async fn publish_available_firmware(
    storage_path: &str,
    publish_tx: Sender<DomainMessage>,
) -> Result<()> {
    use itertools::*;

    let firmware = check_cached_firmware(storage_path).await?;
    let local = firmware
        .into_iter()
        .map(|f| f.into())
        .collect::<Vec<LocalFirmware>>()
        .into_iter()
        .sorted_unstable_by_key(|i| i.time)
        .rev()
        .collect();

    publish_tx
        .send(DomainMessage::AvailableFirmware(local))
        .await?;

    Ok(())
}

impl From<Firmware> for LocalFirmware {
    fn from(value: Firmware) -> Self {
        Self {
            id: value.id,
            time: value.time.timestamp_millis(),
            label: value.version,
            module: value.module,
            profile: value.profile,
        }
    }
}

async fn query_available_firmware(
    client: &query::portal::Client,
    tokens: Option<Tokens>,
) -> Result<Vec<Firmware>> {
    if let Some(tokens) = tokens {
        client
            .to_authenticated(tokens.into())?
            .available_firmware()
            .await
    } else {
        client.available_firmware().await
    }
}

async fn cache_firmware_and_json_if_newer(
    portal_base_url: &str,
    tokens: Option<Tokens>,
    storage_path: &str,
    cached: Vec<Firmware>,
    publish_tx: Sender<DomainMessage>,
) -> Result<()> {
    let client = query::portal::Client::new(portal_base_url)?;
    let firmwares = query_available_firmware(&client, tokens).await?;

    for firmware in firmwares.iter() {
        let has = cached.iter().any(|f| f.etag == firmware.etag);
        if has {
            info!(
                "Firmware already cached {:?} ({})",
                firmware.etag, storage_path
            );
            continue;
        }

        info!("New firmware! {:?}", firmware.etag);
        let path = PathBuf::from(storage_path).join(format!("firmware-{}.bin", firmware.id));
        let stream = client.download_firmware(firmware, &path).await?;

        pin!(stream);

        while let Some(Ok(bytes)) = stream.next().await {
            publish_tx
                .send(DomainMessage::FirmwareDownloadStatus(
                    FirmwareDownloadStatus::Downloading(DownloadProgress {
                        started: 0,
                        completed: 0.0,
                        total: bytes.total_bytes as usize,
                        received: bytes.bytes_downloaded as usize,
                    }),
                ))
                .await?;
        }

        let path = PathBuf::from(storage_path).join(format!("firmware-{}.json", firmware.id));
        let mut writing = OpenOptions::new()
            .write(true)
            .create(true)
            .truncate(true)
            .open(&path)
            .await
            .with_context(|| format!("Creating {:?}", &path))?;

        writing.write_all(&serde_json::to_vec(firmware)?).await?;

        publish_available_firmware(storage_path, publish_tx.clone()).await?;
    }

    if firmwares.is_empty() {
        publish_available_firmware(storage_path, publish_tx.clone()).await?;
    }

    Ok(())
}
