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

pub async fn cache_firmware(
    portal_base_url: String,
    storage_path: String,
    publish_tx: Sender<DomainMessage>,
    tokens: Option<Tokens>,
) -> Result<FirmwareDownloadStatus> {
    tokio::task::spawn({
        async move {
            let cached = match check_cached_firmware(&storage_path).await {
                Err(e) => {
                    warn!("Error checking cached firmware: {:?}", e);

                    let message =
                        DomainMessage::FirmwareDownloadStatus(FirmwareDownloadStatus::Failed);

                    publish_tx
                        .send(message)
                        .await
                        .expect("Error sending firmware status");

                    return;
                }
                Ok(cached) => cached,
            };

            match cache_firmware_and_json_if_newer(
                &portal_base_url,
                tokens,
                &storage_path,
                cached,
                publish_tx.clone(),
            )
            .await
            {
                Err(e) => {
                    warn!("Error caching firmware: {:?}", e);

                    let message =
                        DomainMessage::FirmwareDownloadStatus(FirmwareDownloadStatus::Offline);

                    publish_tx
                        .send(message)
                        .await
                        .expect("Error sending final firmware status");

                    return;
                }
                Ok(_) => {}
            };
        }
    });

    Ok(FirmwareDownloadStatus::Checking)
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
    nearby.mark_busy(&device_id, true).await?;

    tokio::task::spawn({
        let path = PathBuf::from(&storage_path).join(format!("firmware-{}.bin", firmware.id));

        let client = query::device::Client::new()?;

        let device_id = device_id.clone();

        async move {
            match client.upgrade(&addr, &path, swap).await {
                Ok(mut stream) => {
                    let mut failed = false;

                    while let Some(res) = stream.next().await {
                        match res {
                            Ok(bytes) => {
                                publish_tx
                                    .send(DomainMessage::UpgradeProgress(UpgradeProgress {
                                        device_id: device_id.0.clone(),
                                        firmware_id: firmware.id,
                                        status: UpgradeStatus::Uploading(UploadProgress {
                                            bytes_uploaded: bytes.bytes_uploaded,
                                            total_bytes: bytes.total_bytes,
                                        }),
                                    }))
                                    .await
                                    .expect("Upgrade progress failed");
                            }
                            Err(_) => {
                                publish_tx
                                    .send(DomainMessage::UpgradeProgress(UpgradeProgress {
                                        device_id: device_id.0.clone(),
                                        firmware_id: firmware.id,
                                        status: UpgradeStatus::Failed,
                                    }))
                                    .await
                                    .expect("Upgrade progress failed");

                                failed = true;
                            }
                        }
                    }

                    if !failed {
                        if swap {
                            publish_tx
                                .send(DomainMessage::UpgradeProgress(UpgradeProgress {
                                    device_id: device_id.0.clone(),
                                    firmware_id: firmware.id,
                                    status: UpgradeStatus::Restarting,
                                }))
                                .await
                                .expect("Upgrade progress failed");

                            match wait_for_station_restart(&addr).await {
                                Ok(_) => {
                                    publish_tx
                                        .send(DomainMessage::UpgradeProgress(UpgradeProgress {
                                            device_id: device_id.0.clone(),
                                            firmware_id: firmware.id,
                                            status: UpgradeStatus::Completed,
                                        }))
                                        .await
                                        .expect("Upgrade progress failed");
                                }
                                Err(_) => {
                                    publish_tx
                                        .send(DomainMessage::UpgradeProgress(UpgradeProgress {
                                            device_id: device_id.0.clone(),
                                            firmware_id: firmware.id,
                                            status: UpgradeStatus::Failed,
                                        }))
                                        .await
                                        .expect("Upgrade progress failed");
                                }
                            }
                        } else {
                            publish_tx
                                .send(DomainMessage::UpgradeProgress(UpgradeProgress {
                                    device_id: device_id.0.clone(),
                                    firmware_id: firmware.id,
                                    status: UpgradeStatus::Completed,
                                }))
                                .await
                                .expect("Upgrade progress failed");
                        }
                    }

                    nearby
                        .mark_busy(&device_id, false)
                        .await
                        .expect("Mark busy failed");
                }
                Err(e) => {
                    warn!("Error: {:?}", e);

                    publish_tx
                        .send(DomainMessage::UpgradeProgress(UpgradeProgress {
                            device_id: device_id.0.clone(),
                            firmware_id: firmware.id,
                            status: UpgradeStatus::Failed,
                        }))
                        .await
                        .expect("Upgrade progress failed");

                    nearby
                        .mark_busy(&device_id, false)
                        .await
                        .expect("Mark busy failed");
                }
            }
        }
    });

    Ok(UpgradeProgress {
        device_id: device_id.0.clone(),
        firmware_id: firmware.id,
        status: UpgradeStatus::Starting,
    })
}

pub async fn wait_for_station_restart(addr: &str) -> Result<()> {
    let client = query::device::Client::new()?;

    tokio::time::sleep(std::time::Duration::from_secs(5)).await;

    for _i in 0..30 {
        info!("upgrade: Checking station");
        match client.query_status(addr).await {
            Err(e) => info!("upgrade: Waiting for station: {:?}", e),
            Ok(_) => {
                return Ok(());
            }
        }

        tokio::time::sleep(std::time::Duration::from_secs(1)).await;
    }

    Err(anyhow!("Station did not come back online."))
}

pub async fn check_cached_firmware(storage_path: &str) -> Result<Vec<Firmware>> {
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

pub async fn publish_available_firmware(
    storage_path: &str,
    publish_tx: Sender<DomainMessage>,
) -> Result<()> {
    use itertools::*;
    let firmware = check_cached_firmware(storage_path).await?;
    let local = firmware
        .into_iter()
        .map(|f| LocalFirmware {
            id: f.id,
            time: f.time.timestamp_millis(),
            label: f.version,
            module: f.module,
            profile: f.profile,
        })
        .sorted_unstable_by_key(|i| i.time)
        .rev()
        .collect();

    publish_tx
        .send(DomainMessage::AvailableFirmware(local))
        .await?;

    Ok(())
}

pub async fn query_available_firmware(
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

pub async fn cache_firmware_and_json_if_newer(
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

    publish_available_firmware(storage_path, publish_tx.clone()).await?;

    Ok(())
}
