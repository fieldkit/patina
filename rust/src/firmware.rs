use anyhow::{Context, Result};
use discovery::DeviceId;
use query::{
    device::{self, UpgradeOptions},
    portal::{Firmware, FirmwareFilter, ModuleKind},
};
use std::path::PathBuf;
use thiserror::Error;
use tokio::{
    fs::OpenOptions,
    io::{AsyncReadExt, AsyncWriteExt},
    pin,
    sync::mpsc::{error::SendError, Sender},
};
use tokio_stream::StreamExt;
use tracing::*;

use crate::nearby::NearbyDevices;

use super::api::*;

pub struct CheckForAndCacheFirmware {
    portal_base_url: String,
    storage_path: String,
    publish_tx: Sender<DomainMessage>,
    tokens: Option<Tokens>,
}

impl CheckForAndCacheFirmware {
    async fn run(&self) -> Result<()> {
        let cached = match check_cached_firmware(&self.storage_path).await {
            Err(e) => {
                warn!("Error checking cached firmware: {:?}", e);

                self.publish_tx
                    .send(DomainMessage::FirmwareDownloadStatus(
                        FirmwareDownloadStatus::Failed,
                    ))
                    .await?;

                return Ok(());
            }
            Ok(cached) => cached,
        };

        match cache_firmware_and_json_if_newer(
            self.publish_tx.clone(),
            &self.portal_base_url,
            &self.storage_path,
            self.tokens.clone(),
            cached,
        )
        .await
        {
            Err(e) => {
                warn!("Error caching firmware: {:?}", e);

                self.publish_tx
                    .send(DomainMessage::FirmwareDownloadStatus(
                        FirmwareDownloadStatus::Offline,
                    ))
                    .await?;

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
    background: bool,
) -> Result<FirmwareDownloadStatus, PortalError> {
    let task = CheckForAndCacheFirmware {
        portal_base_url,
        storage_path,
        publish_tx,
        tokens,
    };
    info!(%background, "cache_firwmare");

    if background {
        tokio::task::spawn(async move {
            match task.run().await {
                Err(e) => warn!("Error caching firmware: {:?}", e),
                Ok(_) => {}
            }
        });

        Ok(FirmwareDownloadStatus::Checking)
    } else {
        match task.run().await {
            Err(e) => {
                warn!("Error caching firmware: {:?}", e);

                Ok(FirmwareDownloadStatus::Failed)
            }
            Ok(_) => Ok(FirmwareDownloadStatus::Completed),
        }
    }
}

pub struct FirmwareUpgrader {
    options: UpgradeOptions,
    publish_tx: Sender<DomainMessage>,
    storage_path: String,
    device_id: DeviceId,
    firmware: LocalFirmware,
    swap: bool,
    addr: String,
}

#[derive(Debug, Error)]
pub enum Error {
    #[error("upgrade error")]
    Upgrade(#[from] device::UpgradeError),
    #[error("send error")]
    Send,
    #[error("unknown error")]
    Unknown,
}

impl<T> From<SendError<T>> for Error {
    fn from(_value: SendError<T>) -> Self {
        Error::Send
    }
}

impl FirmwareUpgrader {
    async fn publish(&self, status: UpgradeStatus) -> Result<(), SendError<DomainMessage>> {
        self.publish_tx
            .send(DomainMessage::UpgradeProgress(UpgradeProgress {
                device_id: self.device_id.0.clone(),
                firmware_id: self.firmware.id,
                status,
            }))
            .await
    }

    async fn run(&self) -> Result<(), Error> {
        let path = PathBuf::from(&self.storage_path).join(self.firmware.file_name());

        debug!("upgrade: starting {:?}", self.firmware);

        let client = query::device::Client::new().map_err(|_| Error::Unknown)?;
        match client
            .upgrade(&self.addr, &path, self.options.clone())
            .await
        {
            Ok(mut stream) => {
                while let Some(res) = stream.next().await {
                    match res {
                        Ok(bytes) => {
                            if bytes.completed() {
                                self.publish(UpgradeStatus::Restarting {}).await?;
                            } else {
                                self.publish(UpgradeStatus::Uploading(UploadProgress {
                                    bytes_uploaded: bytes.bytes_uploaded,
                                    total_bytes: bytes.total_bytes,
                                }))
                                .await?;
                            }
                        }
                        Err(e) => {
                            return Err(e.into());
                        }
                    }
                }

                if self.swap {
                    debug!("upgrade: upload done, swapped");

                    self.publish(UpgradeStatus::Restarting).await?;

                    match self.wait_for_station_restart().await {
                        Ok(success) => {
                            if success {
                                self.publish(UpgradeStatus::Completed).await?;
                            } else {
                                self.publish(UpgradeStatus::ReconnectTimeout).await?;
                            }

                            Ok(())
                        }
                        Err(e) => Err(e),
                    }
                } else {
                    debug!("upgrade: upload done, completed");

                    self.publish(UpgradeStatus::Completed).await?;

                    Ok(())
                }
            }
            Err(e) => Err(e.into()),
        }
    }

    async fn wait_for_station_restart(&self) -> Result<bool, Error> {
        use std::time::Duration;
        use tokio::time::sleep;

        for i in 0..30 {
            sleep(Duration::from_secs(if i == 0 { 5 } else { 1 })).await;

            info!("upgrade: Checking station");
            let client = query::device::Client::new().map_err(|_| Error::Unknown)?;
            match client.query_status(&self.addr).await {
                Err(e) => info!("upgrade: Waiting for station: {:?}", e),
                Ok(_) => {
                    return Ok(true);
                }
            }
        }

        Ok(false)
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
    let options = UpgradeOptions {
        swap,
        limited: None,
    };
    let upgrader = FirmwareUpgrader {
        options,
        publish_tx: publish_tx.clone(),
        storage_path,
        device_id: device_id.clone(),
        firmware: firmware.clone(),
        swap,
        addr,
    };

    nearby.mark_busy(&device_id, true).await?;

    tokio::task::spawn({
        let device_id = device_id.clone();

        async move {
            match upgrader.run().await {
                Err(e) => {
                    warn!("Error upgrading: {:?}", e);
                    match upgrader
                        .publish(UpgradeStatus::Failed(Some(e.into())))
                        .await
                    {
                        Err(e) => warn!("Error published failure: {:?}", e),
                        Ok(_) => {}
                    }
                }
                Ok(_) => {}
            }

            match nearby.mark_busy(&device_id, false).await {
                Err(e) => warn!("Error marking ready: {:?}", e),
                Ok(_) => {}
            }
        }
    });

    info!("upgrade: starting");

    let starting = UpgradeProgress {
        device_id: device_id.0,
        firmware_id: firmware.id,
        status: UpgradeStatus::Starting,
    };

    match publish_tx
        .send(DomainMessage::UpgradeProgress(starting.clone()))
        .await
    {
        Err(e) => warn!("Error published start: {:?}", e),
        Ok(_) => {}
    }

    Ok(starting)
}

async fn check_cached_firmware(storage_path: &str) -> Result<Vec<Firmware>> {
    info!("check_cached_firmware");

    let mut found = Vec::new();
    let pattern = format!("{}/firmware*.json", storage_path);
    for path in glob::glob(&pattern)? {
        let mut reading = OpenOptions::new().read(true).open(&path?).await?;
        let mut buffer = String::new();
        reading.read_to_string(&mut buffer).await?;
        found.push(serde_json::from_str(&buffer)?);
    }

    info!("check_cached_firmware: {}", found.len());

    Ok(found)
}

async fn publish_available_firmware(
    storage_path: &str,
    publish_tx: Sender<DomainMessage>,
) -> Result<()> {
    use itertools::*;

    info!("publish_available_firmware");

    let firmware = check_cached_firmware(storage_path).await?;

    // There are two kinds of firmware, one is bootloader and the other is for
    // the core. This finds the matching bootloader firmware for each core
    // firmware and maps them to LocalFirmware instances. We do this because the
    // etag profile and time are the same for corresponding bootloader and core
    // firmware from the same build.
    let local = firmware
        .into_iter()
        .flat_map(|f| {
            f.etag
                .parts()
                .map(|parts| ((parts.profile, parts.stamp), f))
        })
        .sorted_by(|(a, _), (b, _)| a.cmp(b))
        .group_by(|(parts, _)| parts.clone())
        .into_iter()
        .map(|(_, group)| group.map(|(_, f)| f).collect::<Vec<_>>())
        .flat_map(|group| match group.as_slice() {
            [a, b] => match (a.module_kind(), b.module_kind()) {
                (Some(ModuleKind::Bootloader), Some(ModuleKind::Core)) => {
                    Some(LocalFirmware::new(b.clone(), Some(a.clone())))
                }
                (Some(ModuleKind::Core), Some(ModuleKind::Bootloader)) => {
                    Some(LocalFirmware::new(a.clone(), Some(b.clone())))
                }
                _ => None,
            },
            _ => None,
        })
        .collect::<Vec<_>>();

    publish_tx
        .send(DomainMessage::AvailableFirmware(local))
        .await?;

    Ok(())
}

async fn query_available_firmware(
    client: &query::portal::Client,
    tokens: Option<Tokens>,
    filter: Option<FirmwareFilter>,
) -> Result<Vec<Firmware>> {
    if let Some(tokens) = tokens {
        client
            .to_authenticated(tokens.into())?
            .available_firmware(filter)
            .await
    } else {
        client.available_firmware(filter).await
    }
}

async fn cache_firmware_and_json_if_newer(
    publish_tx: Sender<DomainMessage>,
    portal_base_url: &str,
    storage_path: &str,
    tokens: Option<Tokens>,
    cached: Vec<Firmware>,
) -> Result<()> {
    // Publish available before querying, since we may fail below if offline.
    publish_available_firmware(storage_path, publish_tx.clone()).await?;

    let client = query::portal::Client::new(portal_base_url)?;
    let firmwares = query_available_firmware(
        &client,
        tokens,
        Some(FirmwareFilter {
            module: None,
            profile: None,
            page: None,
            page_size: Some(30),
        }),
    )
    .await?;

    info!("{} firmware", firmwares.len());

    for firmware in firmwares.iter() {
        let has = cached.iter().any(|f| f.etag == firmware.etag);
        if has {
            info!(
                "firmware already cached {:?} ({})",
                firmware.etag, storage_path
            );
            continue;
        }

        info!("firmware! {:?}", firmware.etag);
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

    Ok(())
}
