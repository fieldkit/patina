use anyhow::Result;
use chrono::{DateTime, Utc};
use std::collections::HashMap;
use std::sync::Arc;

use tokio::sync::mpsc::Sender;
use tokio::sync::Mutex;
use tracing::*;

use discovery::DeviceId;
use query::device::HttpReply;

use crate::api::{DomainMessage, NearbyStation};

#[derive(Debug)]
pub enum BackgroundMessage {
    Domain(DomainMessage),
    StationReply(discovery::DeviceId, HttpReply),
}

#[derive(Clone)]
pub struct NearbyDevices {
    publish_tx: Sender<BackgroundMessage>,
    devices: Arc<Mutex<HashMap<discovery::DeviceId, Querying>>>,
}

impl NearbyDevices {
    pub fn new(publish_tx: Sender<BackgroundMessage>) -> Self {
        Self {
            publish_tx,
            devices: Default::default(),
        }
    }

    pub async fn get_connections(&self) -> Result<HashMap<discovery::DeviceId, Connection>> {
        let devices = self.devices.lock().await;
        Ok(devices
            .iter()
            .map(|(key, value)| (key.clone(), value.into()))
            .collect())
    }

    pub async fn announced(&self, announce: discovery::Discovered) -> Result<()> {
        if self.add_if_necessary(announce).await {
            Ok(self.publish().await?)
        } else {
            Ok(())
        }
    }

    pub async fn schedule_queries(&self) -> Result<bool> {
        match self.first_station_to_query().await? {
            Some(querying) => match self.query_station(&querying).await {
                Ok(status) => Ok(self
                    .mark_finished_and_publish_reply(&querying.device_id, status)
                    .await
                    .map(|_| true)?),
                Err(e) => {
                    warn!("Query station: {}", e);

                    match self.mark_retry(&querying.device_id).await? {
                        Connection::Connected => Ok(true),
                        Connection::Lost => Ok(self.publish().await.map(|_| true)?),
                    }
                }
            },
            None => Ok(false),
        }
    }

    async fn add_if_necessary(&self, announce: discovery::Discovered) -> bool {
        let mut devices = self.devices.lock().await;
        let device_id = &announce.device_id;
        if let Some(connected) = devices.get_mut(device_id) {
            if connected.is_disconnected() && connected.retry.is_none() {
                info!("bg:announce: {:?}", connected);

                connected.attempted = None;
                connected.finished = None;
            }

            false
        } else {
            info!("bg:announce: {:?}", announce);

            devices.insert(
                device_id.clone(),
                Querying {
                    device_id: device_id.clone(),
                    http_addr: format!("{}", announce.http_addr),
                    attempted: None,
                    finished: None,
                    retry: None,
                    failures: 0,
                },
            );

            true
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

    async fn publish(&self) -> Result<()> {
        let devices = self.devices.lock().await;
        let nearby = devices
            .values()
            .filter(|q| !q.is_disconnected())
            .map(|q| NearbyStation {
                device_id: q.device_id.0.to_string(),
            })
            .collect();

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
        use chrono::Duration;

        let mut devices = self.devices.lock().await;
        let mut querying = devices.get_mut(device_id).expect("Whoa, no querying yet?");
        querying.failures += 1;
        if !querying.is_disconnected() {
            querying.retry = Some(Utc::now() + Duration::seconds(1));
        }

        Ok(querying.into())
    }

    async fn mark_finished(&self, device_id: &discovery::DeviceId) -> Result<()> {
        let mut devices = self.devices.lock().await;
        let mut querying = devices.get_mut(device_id).expect("Whoa, no querying yet?");
        querying.finished = Some(Utc::now());
        querying.failures = 0;

        Ok(())
    }

    async fn mark_finished_and_publish_reply(
        &self,
        device_id: &discovery::DeviceId,
        status: HttpReply,
    ) -> Result<()> {
        self.mark_finished(device_id).await?;

        self.publish_tx
            .send(BackgroundMessage::StationReply(device_id.clone(), status))
            .await?;

        Ok(())
    }

    async fn query_station(&self, querying: &Querying) -> Result<HttpReply> {
        let client = query::device::Client::new()?;
        Ok(client.query_status(&querying.http_addr).await?)
    }
}

type ModelTime = DateTime<Utc>;

#[derive(Clone, Debug)]
struct Querying {
    pub device_id: DeviceId,
    pub http_addr: String,
    pub attempted: Option<ModelTime>,
    pub finished: Option<ModelTime>,
    pub retry: Option<ModelTime>,
    pub failures: i32,
}

impl Querying {
    fn should_query(&self) -> bool {
        let now = Utc::now();
        match self.attempted {
            Some(attempted) => {
                if now - attempted > chrono::Duration::seconds(10) {
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

// TODO Blanket implementation?

impl Into<Connection> for &Querying {
    fn into(self) -> Connection {
        if self.is_disconnected() {
            Connection::Lost
        } else {
            Connection::Connected
        }
    }
}

impl Into<Connection> for &mut Querying {
    fn into(self) -> Connection {
        if self.is_disconnected() {
            Connection::Lost
        } else {
            Connection::Connected
        }
    }
}
