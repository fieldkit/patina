use anyhow::Result;
use base64::Engine;
use chrono::{DateTime, Duration, Utc};
use std::{collections::HashMap, ops::Sub, sync::Arc, time::UNIX_EPOCH};
use sync::ServerEvent;
use tokio::{
    sync::{
        mpsc::{Receiver, Sender},
        Mutex,
    },
    time::Instant,
};
use tracing::*;

use discovery::{DeviceId, Discovered};
use query::device::{HttpReply, RawAndDecoded};

use crate::api::{
    DomainMessage, DownloadProgress, NearbyStation, RecordArchive, TransferProgress, TransferStatus,
};

#[derive(Debug)]
pub enum BackgroundMessage {
    Domain(DomainMessage),
    StationReply(DeviceId, HttpReply, String),
}

#[derive(Clone)]
pub struct NearbyDevices {
    publish_tx: Sender<BackgroundMessage>,
    devices: Arc<Mutex<HashMap<DeviceId, Querying>>>,
}

const ONE_SECOND: std::time::Duration = std::time::Duration::from_secs(1);

impl NearbyDevices {
    pub fn new(publish_tx: Sender<BackgroundMessage>) -> Self {
        Self {
            publish_tx,
            devices: Default::default(),
        }
    }

    pub async fn run(
        &self,
        mut rx: Receiver<Discovered>,
        mut transfer_events: Receiver<ServerEvent>,
    ) -> Result<()> {
        let maintain_discoveries = tokio::spawn({
            let nearby = self.clone();
            async move {
                while let Some(discovered) = rx.recv().await {
                    match nearby.discovered(discovered).await {
                        Err(e) => warn!("Error handling discovered: {}", e),
                        _ => {}
                    }
                }
            }
        });

        let query_stations = tokio::spawn({
            let nearby = self.clone();
            async move {
                loop {
                    match nearby.schedule_queries().await {
                        Err(e) => warn!("Error scheduling queries: {}", e),
                        Ok(false) => tokio::time::sleep(ONE_SECOND).await,
                        Ok(true) => {}
                    }
                }
            }
        });

        let handle_server_events = tokio::spawn({
            let publish_tx = self.publish_tx.clone();
            let nearby = self.clone();
            async move {
                let mut last_progress = None::<Instant>;
                while let Some(event) = transfer_events.recv().await {
                    match nearby
                        .handle_server_event(publish_tx.clone(), &mut last_progress, event)
                        .await
                    {
                        Err(e) => warn!("Error handling server event: {}", e),
                        Ok(_) => {}
                    }
                }
            }
        });

        tokio::select! {
            _ = maintain_discoveries => Ok(()),
            _ = query_stations => Ok(()),
            _ = handle_server_events => Ok(()),
        }
    }

    pub async fn get_connections(&self) -> Result<HashMap<DeviceId, Connection>> {
        let devices = self.devices.lock().await;
        Ok(devices
            .iter()
            .map(|(key, value)| (key.clone(), value.into()))
            .collect())
    }

    pub async fn discovered(&self, discovered: Discovered) -> Result<()> {
        if self.add_if_necessary(discovered).await? {
            Ok(self.publish().await?)
        } else {
            Ok(())
        }
    }

    pub async fn schedule_queries(&self) -> Result<bool> {
        match self.first_station_to_query().await? {
            Some(querying) => match self.query_station(&querying).await {
                Ok(_) => Ok(true),
                Err(e) => {
                    warn!("query station: {}", e);

                    match self.mark_retry(&querying.device_id).await? {
                        Connection::Connected => Ok(true),
                        Connection::Lost => Ok(self.publish().await.map(|_| true)?),
                    }
                }
            },
            None => Ok(false),
        }
    }

    async fn add_if_necessary(&self, discovered: Discovered) -> Result<bool> {
        let mut devices = self.devices.lock().await;
        let device_id = &discovered.device_id;
        if let Some(connected) = devices.get_mut(device_id) {
            if connected.is_disconnected() && connected.retry.is_none() {
                info!("bg:rediscovered: {:?}", connected);

                connected.attempted = None;
                connected.finished = None;
                connected.failures = 0;

                Ok(true)
            } else {
                Ok(false)
            }
        } else {
            info!("bg:discovered: {:?}", discovered);

            devices.insert(
                device_id.clone(),
                Querying {
                    device_id: device_id.clone(),
                    http_addr: format!(
                        "{}",
                        discovered
                            .http_addr
                            .ok_or(anyhow::anyhow!("Expected HTTP addr"))?
                    ),
                    busy: false,
                    discovered,
                    attempted: None,
                    finished: None,
                    retry: None,
                    failures: 0,
                },
            );

            Ok(true)
        }
    }

    async fn first_station_to_query(&self) -> Result<Option<Querying>> {
        let mut devices = self.devices.lock().await;
        for (_, nearby) in devices.iter_mut() {
            trace!("{:?}", nearby);
            if nearby.should_query() {
                nearby.attempted = Some(Utc::now());
                nearby.finished = None;
                nearby.retry = None;
                return Ok(Some(nearby.clone()));
            }
        }

        Ok(None)
    }

    async fn get_nearby_stations(&self) -> Result<Vec<NearbyStation>> {
        let devices = self.devices.lock().await;
        Ok(devices
            .values()
            .filter(|q| !q.is_disconnected())
            .map(|q| NearbyStation {
                device_id: q.device_id.0.to_string(),
                busy: q.busy,
            })
            .collect())
    }

    async fn publish(&self) -> Result<()> {
        let nearby = self.get_nearby_stations().await?;

        match self
            .publish_tx
            .send(BackgroundMessage::Domain(DomainMessage::NearbyStations(
                nearby,
            )))
            .await
        {
            Ok(_) => Ok(()),
            Err(e) => {
                warn!("Send NearbyStations failed: {}", e);
                Ok(())
            }
        }
    }

    async fn mark_retry(&self, device_id: &DeviceId) -> Result<Connection> {
        let mut devices = self.devices.lock().await;
        let querying = devices.get_mut(device_id).expect("Whoa, no querying yet?");
        querying.failures += 1;
        if !querying.is_disconnected() {
            querying.retry = Some(
                Utc::now()
                    + Duration::try_seconds(1)
                        .ok_or_else(|| anyhow::anyhow!("Retry delay try_seconds"))?,
            );
        }

        Ok((&*querying).into())
    }

    async fn mark_finished(&self, device_id: &DeviceId) -> Result<()> {
        let mut devices = self.devices.lock().await;
        let querying = devices.get_mut(device_id).expect("Whoa, no querying yet?");
        querying.finished = Some(Utc::now());
        querying.failures = 0;

        Ok(())
    }

    pub(crate) async fn mark_finished_and_publish_reply(
        &self,
        device_id: &DeviceId,
        status: RawAndDecoded<HttpReply>,
    ) -> Result<()> {
        self.mark_finished(device_id).await?;

        use base64::engine::general_purpose::STANDARD;

        self.publish_tx
            .send(BackgroundMessage::StationReply(
                device_id.clone(),
                status.decoded,
                STANDARD.encode(status.bytes),
            ))
            .await?;

        Ok(())
    }

    async fn query_station(&self, querying: &Querying) -> Result<()> {
        let client = query::device::Client::new()?;
        let status = client.query_readings(&querying.http_addr).await?;
        Ok(self
            .mark_finished_and_publish_reply(&querying.device_id, status)
            .await?)
    }

    pub async fn mark_busy(&self, device_id: &DeviceId, busy: bool) -> Result<()> {
        let mut devices = self.devices.lock().await;
        let querying = devices.get_mut(device_id).expect("Whoa, no querying yet?");
        querying.busy = busy;
        Ok(())
    }

    pub async fn mark_busy_and_publish(&self, device_id: &DeviceId, busy: bool) -> Result<()> {
        self.mark_busy(device_id, busy).await?;
        self.publish().await
    }

    pub async fn get_discovered(&self, device_id: &DeviceId) -> Option<Discovered> {
        let devices = self.devices.lock().await;
        let querying = devices.get(device_id);
        querying.map(|q| q.discovered.clone())
    }

    pub async fn handle_server_event(
        &self,
        publish_tx: Sender<BackgroundMessage>,
        last_progress: &mut Option<Instant>,
        event: ServerEvent,
    ) -> Result<()> {
        match &event {
            ServerEvent::Began(device_id) => {
                info!("{:?}", &event);
                self.mark_busy_and_publish(device_id, true).await?;
                publish_tx
                    .send(BackgroundMessage::Domain(DomainMessage::DownloadProgress(
                        TransferProgress {
                            device_id: device_id.0.to_owned(),
                            status: TransferStatus::Starting,
                        },
                    )))
                    .await?;

                Ok(())
            }
            ServerEvent::Transferring(device_id, started, progress) => {
                let publish_progress = match last_progress {
                    Some(last_progress) => {
                        tokio::time::Instant::now().sub(*last_progress)
                            > std::time::Duration::from_millis(200)
                    }
                    None => true,
                };

                if publish_progress {
                    info!("{:?}", &progress);
                    let total = progress.total.as_ref().unwrap();
                    publish_tx
                        .send(BackgroundMessage::Domain(DomainMessage::DownloadProgress(
                            TransferProgress {
                                device_id: device_id.0.to_owned(),
                                status: TransferStatus::Downloading(DownloadProgress {
                                    started: started.duration_since(UNIX_EPOCH)?.as_millis() as u64,
                                    completed: total.completed,
                                    total: total.total,
                                    received: total.received,
                                }),
                            },
                        )))
                        .await?;

                    *last_progress = Some(Instant::now());
                }

                Ok(())
            }
            ServerEvent::Processing(device_id) => {
                publish_tx
                    .send(BackgroundMessage::Domain(DomainMessage::DownloadProgress(
                        TransferProgress {
                            device_id: device_id.0.to_owned(),
                            status: TransferStatus::Processing,
                        },
                    )))
                    .await?;

                Ok(())
            }
            ServerEvent::Completed(device_id) => {
                info!("{:?}", &event);
                self.mark_busy_and_publish(device_id, false).await?;
                publish_tx
                    .send(BackgroundMessage::Domain(DomainMessage::DownloadProgress(
                        TransferProgress {
                            device_id: device_id.0.to_owned(),
                            status: TransferStatus::Completed,
                        },
                    )))
                    .await?;

                Ok(())
            }
            ServerEvent::Failed(device_id) => {
                info!("{:?}", &event);
                self.mark_busy_and_publish(device_id, false).await?;
                publish_tx
                    .send(BackgroundMessage::Domain(DomainMessage::DownloadProgress(
                        TransferProgress {
                            device_id: device_id.0.to_owned(),
                            status: TransferStatus::Failed,
                        },
                    )))
                    .await?;

                Ok(())
            }
            ServerEvent::Available(files) => {
                let files = files
                    .iter()
                    .map(|f| RecordArchive {
                        device_id: f.device_id.clone(),
                        generation_id: f.generation_id.clone(),
                        path: f.path.clone(),
                        head: f.meta.head,
                        tail: f.meta.tail,
                    })
                    .collect();
                publish_tx
                    .send(BackgroundMessage::Domain(DomainMessage::RecordArchives(
                        files,
                    )))
                    .await?;

                Ok(())
            }
        }
    }
}

type ModelTime = DateTime<Utc>;

#[derive(Clone, Debug)]
struct Querying {
    pub device_id: DeviceId,
    pub http_addr: String,
    pub discovered: Discovered,
    pub busy: bool,
    pub attempted: Option<ModelTime>,
    pub finished: Option<ModelTime>,
    pub retry: Option<ModelTime>,
    pub failures: i32,
}

impl Querying {
    fn should_query(&self) -> bool {
        if self.busy {
            return false;
        }

        let now = Utc::now();
        match self.attempted {
            Some(attempted) => {
                if now - attempted > Duration::try_seconds(10).expect("Requery try_seconds") {
                    true
                } else {
                    match self.retry {
                        Some(retry) => {
                            if now >= retry {
                                true
                            } else {
                                false
                            }
                        }
                        None => false,
                    }
                }
            }
            None => true,
        }
    }

    fn is_disconnected(&self) -> bool {
        self.failures >= 3
    }
}

#[derive(Clone, Debug)]
pub enum Connection {
    Connected,
    Lost,
}

impl Into<Connection> for &Querying {
    fn into(self) -> Connection {
        if self.is_disconnected() {
            Connection::Lost
        } else {
            Connection::Connected
        }
    }
}
