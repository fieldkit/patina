use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::StreamSink;
use std::{
    io::Write,
    ops::Sub,
    sync::{Arc, Mutex as StdMutex},
    time::UNIX_EPOCH,
};
use sync::{Server, ServerEvent};
use thiserror::Error;
use tokio::runtime::Runtime;
use tokio::sync::{mpsc::Sender, oneshot, Mutex};
use tokio::time::{sleep, Duration, Instant};
use tracing::*;
use tracing_subscriber::{fmt::MakeWriter, EnvFilter};

use discovery::{DeviceId, Discovered, Discovery};
use query::portal::{decode_token, PortalError, StatusCode, Tokens as PortalTokens};
use store::Db;

use crate::nearby::{BackgroundMessage, Connection, NearbyDevices};

const ONE_SECOND: Duration = Duration::from_secs(1);

static SDK: StdMutex<Option<Sdk>> = StdMutex::new(None);
static RUNTIME: StdMutex<Option<Runtime>> = StdMutex::new(None);

// The convention for Rust identifiers is the snake_case,
// and they are automatically converted to camelCase on the Dart side.
pub fn rust_release_mode() -> bool {
    cfg!(not(debug_assertions))
}

/// Wrapper so that we can implement required Write and MakeWriter traits.
struct LogSink {
    sink: StreamSink<String>,
}

/// Write log lines to our Flutter's sink.
impl<'a> Write for &'a LogSink {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        let line = String::from_utf8_lossy(buf).to_string();
        self.sink.add(line);
        Ok(buf.len())
    }

    fn flush(&mut self) -> std::io::Result<()> {
        Ok(())
    }
}

impl<'a> MakeWriter<'a> for LogSink {
    type Writer = &'a LogSink;

    fn make_writer(&'a self) -> Self::Writer {
        self
    }
}

pub fn create_log_sink(sink: StreamSink<String>) -> Result<()> {
    fn get_rust_log() -> String {
        let mut original = std::env::var("RUST_LOG").unwrap_or_else(|_| "debug".into());

        for logger in [
            "hyper=",
            "reqwest=",
            "rusqlite_migration=",
            "rustls=",
            "h2=",
        ] {
            if !original.contains(logger) {
                original.push_str(&format!(",{}info", logger));
            }
        }

        original
    }

    if let Err(err) = tracing_subscriber::fmt()
        .with_max_level(tracing::Level::TRACE)
        .with_env_filter(EnvFilter::new(get_rust_log()))
        .with_writer(LogSink { sink })
        .try_init()
    {
        bail!("{}", err);
    }

    Ok(())
}

async fn handle_background_message(
    db: &Arc<Mutex<Db>>,
    publish_tx: Sender<DomainMessage>,
    bg: BackgroundMessage,
) -> Result<()> {
    match bg {
        BackgroundMessage::Domain(message) => Ok(publish_tx.send(message).await?),
        BackgroundMessage::StationReply(device_id, reply) => {
            let db = db.lock().await;
            let station = db.merge_reply(store::DeviceId(device_id.0), reply)?;
            Ok(publish_tx
                .send(DomainMessage::StationRefreshed(
                    StationAndConnection {
                        station,
                        connection: Some(Connection::Connected),
                    }
                    .try_into()?,
                    None,
                ))
                .await?)
        }
    }
}

async fn handle_server_event(
    nearby: &NearbyDevices,
    publish_tx: Sender<DomainMessage>,
    last_progress: &mut Option<Instant>,
    event: ServerEvent,
) -> Result<()> {
    match &event {
        ServerEvent::Began(device_id) => {
            info!("{:?}", &event);
            nearby.mark_busy_and_publish(device_id, true).await?;
            publish_tx
                .send(DomainMessage::TransferProgress(TransferProgress {
                    device_id: device_id.0.to_owned(),
                    status: TransferStatus::Starting,
                }))
                .await?;

            Ok(())
        }
        ServerEvent::Progress(device_id, started, progress) => {
            let publish_progress = match last_progress {
                Some(last_progress) => {
                    tokio::time::Instant::now().sub(*last_progress) > Duration::from_millis(500)
                }
                None => true,
            };

            if publish_progress {
                info!("{:?}", &event);
                let total = progress.total.as_ref().unwrap();
                publish_tx
                    .send(DomainMessage::TransferProgress(TransferProgress {
                        device_id: device_id.0.to_owned(),
                        status: TransferStatus::Transferring(DownloadProgress {
                            started: started.duration_since(UNIX_EPOCH)?.as_millis() as u64,
                            completed: total.completed,
                            total: total.total,
                            received: total.received,
                        }),
                    }))
                    .await?;

                *last_progress = Some(Instant::now());
            }

            Ok(())
        }
        ServerEvent::Completed(device_id) => {
            info!("{:?}", &event);
            nearby.mark_busy_and_publish(device_id, false).await?;
            publish_tx
                .send(DomainMessage::TransferProgress(TransferProgress {
                    device_id: device_id.0.to_owned(),
                    status: TransferStatus::Completed,
                }))
                .await?;

            Ok(())
        }
        ServerEvent::Failed(device_id) => {
            info!("{:?}", &event);
            nearby.mark_busy_and_publish(device_id, false).await?;
            publish_tx
                .send(DomainMessage::TransferProgress(TransferProgress {
                    device_id: device_id.0.to_owned(),
                    status: TransferStatus::Failed,
                }))
                .await?;

            Ok(())
        }
    }
}

async fn create_sdk(storage_path: String, publish_tx: Sender<DomainMessage>) -> Result<Sdk> {
    info!("startup:bg");

    let (bg_tx, mut bg_rx) = tokio::sync::mpsc::channel::<BackgroundMessage>(32);

    let (transfer_publish, mut transfer_events) = tokio::sync::mpsc::channel::<ServerEvent>(32);

    let server = Arc::new(Server::new(transfer_publish));

    let nearby = NearbyDevices::new(bg_tx.clone());

    let sdk = Sdk::new(
        storage_path,
        nearby.clone(),
        server.clone(),
        publish_tx.clone(),
    )?;

    sdk.open().await?;

    tokio::spawn({
        let publish_tx = publish_tx.clone();
        let db = sdk.db.clone();
        async move {
            while let Some(bg) = bg_rx.recv().await {
                handle_background_message(&db, publish_tx.clone(), bg)
                    .await
                    .expect("Background error:")
            }
        }
    });

    tokio::spawn({
        let publish_tx = publish_tx.clone();
        let nearby = nearby.clone();
        async move {
            let mut last_progress = None::<Instant>;
            while let Some(event) = transfer_events.recv().await {
                handle_server_event(&nearby, publish_tx.clone(), &mut last_progress, event)
                    .await
                    .expect("Background error:")
            }
        }
    });

    tokio::spawn(async move { background_task(nearby, server).await });

    Ok(sdk)
}

async fn background_task(nearby: NearbyDevices, server: Arc<Server>) {
    info!("bg:started");

    let (tx, mut rx) = tokio::sync::mpsc::channel::<Discovered>(32);
    let discovery = Discovery::default();

    let maintain_discoveries = tokio::spawn({
        let nearby = nearby.clone();
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
        async move {
            loop {
                match nearby.schedule_queries().await {
                    Err(e) => warn!("Error scheduling queries: {}", e),
                    Ok(false) => sleep(ONE_SECOND).await,
                    Ok(true) => {}
                }
            }
        }
    });

    tokio::select! {
        _ = discovery.run(tx) => {},
        _ = server.run() => {},
        _ = maintain_discoveries => {},
        _ = query_stations => {},
    };
}

fn start_runtime() -> Result<Runtime> {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(3)
        .enable_all()
        .thread_name("fieldkit-client")
        .build()?;

    Ok(rt)
}

pub fn start_native(sink: StreamSink<DomainMessage>, storage_path: String) -> Result<()> {
    info!("startup:runtime");
    let rt = start_runtime()?;

    let (publish_tx, mut publish_rx) = tokio::sync::mpsc::channel(20);
    let sdk = rt.block_on(create_sdk(storage_path, publish_tx))?;

    // Consider moving this to using the above channel?
    sink.add(DomainMessage::PreAccount);

    let handle = rt.handle().clone();

    // I really wish there was a better way. There are _other_ ways, though I
    // dunno if they're better.
    {
        *SDK.lock().expect("Set sdk") = Some(sdk);
        *RUNTIME.lock().expect("Set runtime") = Some(rt);
    }

    info!("startup:pump");
    let (tx, rx) = oneshot::channel();
    // We are spawning an async task from a thread that is not managed by
    // Tokio runtime. For this to work we need to enter the handle.
    // Ref: https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html#method.current
    let _guard = handle.enter();
    tokio::spawn(async move {
        while let Some(e) = publish_rx.recv().await {
            trace!("sdk:publish");
            sink.add(e.into());
        }
        let _ = tx.send(());
    });
    info!("sdk:ready");

    let _ = rx.blocking_recv();
    info!("sdk:finished");

    Ok(())
}

#[allow(dead_code)]
struct Sdk {
    storage_path: String,
    db: Arc<Mutex<Db>>,
    nearby: NearbyDevices,
    server: Arc<Server>,
    publish_tx: Sender<DomainMessage>,
}

impl Sdk {
    fn new(
        storage_path: String,
        nearby: NearbyDevices,
        server: Arc<Server>,
        publish_tx: Sender<DomainMessage>,
    ) -> Result<Self> {
        Ok(Self {
            storage_path,
            db: Arc::new(Mutex::new(Db::new())),
            nearby,
            server,
            publish_tx,
        })
    }

    async fn open(&self) -> Result<()> {
        let mut db = self.db.lock().await;
        db.open()?;

        Ok(())
    }

    async fn get_my_stations(&self) -> Result<Vec<StationConfig>> {
        let connections = self.nearby.get_connections().await?;
        let db = self.db.lock().await;
        let stations = db.get_stations()?;

        Ok(stations
            .into_iter()
            .map(|station| {
                let device_id = &DeviceId(station.device_id.clone().0);
                let connection = connections.get(&device_id).cloned();
                Ok(StationAndConnection {
                    station,
                    connection,
                }
                .try_into()?)
            })
            .collect::<Result<Vec<_>>>()?)
    }

    async fn authenticate_portal(&self, email: String, password: String) -> Result<Option<Tokens>> {
        let client = query::portal::Client::new()?;
        let tokens = client
            .login(query::portal::LoginPayload { email, password })
            .await?
            .ok_or_else(|| anyhow::anyhow!("Tokens are required."))?;
        let authenticated = client.to_authenticated(tokens.clone())?;
        let transmission = authenticated.issue_transmission_token().await?;

        Ok(Some(Tokens {
            token: tokens.token,
            transmission: Some(transmission).map(|t| TransmissionToken {
                token: t.token,
                url: t.url,
            }),
        }))
    }

    async fn validate_tokens(&self, tokens: Tokens) -> Result<Option<Tokens>> {
        let client = query::portal::Client::new()?;
        let client = client.to_authenticated(PortalTokens {
            token: tokens.token.clone(),
        })?;

        match client.query_ourselves().await {
            Ok(ourselves) => {
                info!("{:?} {:?}", tokens.refresh_token(), ourselves);
                Ok(Some(tokens))
            }
            Err(PortalError::HttpStatus(StatusCode::UNAUTHORIZED)) => {
                Ok(self.refresh_tokens(tokens).await?)
            }
            Err(e) => Err(e.into()),
        }
    }

    async fn refresh_tokens(&self, tokens: Tokens) -> Result<Option<Tokens>> {
        let refresh_token = tokens.refresh_token()?;
        let client = query::portal::Client::new()?;
        if true {
            Ok(None)
        } else {
            let tokens = client
                .use_refresh_token(&refresh_token)
                .await?
                .ok_or_else(|| anyhow::anyhow!("Tokens are required."))?;
            let authenticated = client.to_authenticated(tokens.clone())?;
            let transmission = authenticated.issue_transmission_token().await?;
            Ok(Some(Tokens {
                token: tokens.token,
                transmission: Some(transmission).map(|t| TransmissionToken {
                    token: t.token,
                    url: t.url,
                }),
            }))
        }
    }

    async fn start_download(&self, device_id: String) -> Result<TransferProgress> {
        info!("{:?} start download", &device_id);

        let discovered = self
            .nearby
            .get_discovered(&DeviceId(device_id.clone()))
            .await;

        if let Some(discovered) = discovered {
            self.server.sync(discovered).await?;
        } else {
            warn!("{:?} undiscovered!", &device_id);
        }

        Ok(TransferProgress {
            device_id,
            status: TransferStatus::Starting,
        })
    }

    async fn start_upload(&self, device_id: String) -> Result<TransferProgress> {
        info!("{:?} start upload", &device_id);

        Ok(TransferProgress {
            device_id,
            status: TransferStatus::Starting,
        })
    }
}

fn with_runtime<R>(cb: impl FnOnce(&Runtime, &mut Sdk) -> Result<R>) -> Result<R> {
    let mut sdk_guard = SDK.lock().expect("Get sdk");
    let sdk = sdk_guard.as_mut().expect("Sdk present");

    // We are calling async sdk methods from a thread that is not managed by
    // Tokio runtime. For this to work we need to enter the handle.
    // Ref: https://docs.rs/tokio/latest/tokio/runtime/struct.Handle.html#method.current
    let mut rt_guard = RUNTIME.lock().expect("Get runtime");
    let rt = rt_guard.as_mut().expect("Runtime present");
    let _guard = rt.enter();
    cb(rt, sdk)
}

#[allow(dead_code)]
fn with_sdk<R>(cb: impl FnOnce(&mut Sdk) -> Result<R>) -> Result<R> {
    with_runtime(|_rt, sdk| cb(sdk))
}

pub fn get_my_stations() -> Result<Vec<StationConfig>> {
    Ok(with_runtime(|rt, sdk| rt.block_on(sdk.get_my_stations()))?)
}

pub fn authenticate_portal(email: String, password: String) -> Result<Option<Tokens>> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.authenticate_portal(email, password))
    })?)
}

pub fn validate_tokens(tokens: Tokens) -> Result<Option<Tokens>> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.validate_tokens(tokens))
    })?)
}

pub fn start_download(device_id: String) -> Result<TransferProgress> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.start_download(device_id))
    })?)
}

pub fn start_upload(device_id: String) -> Result<TransferProgress> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.start_upload(device_id))
    })?)
}

#[derive(Debug)]
pub struct Tokens {
    pub token: String,
    pub transmission: Option<TransmissionToken>,
}

#[derive(Debug)]
pub struct TransmissionToken {
    pub token: String,
    pub url: String,
}

impl Tokens {
    fn refresh_token(&self) -> Result<String> {
        Ok(decode_token(&self.token)?.refresh_token)
    }
}

#[derive(Debug)]
pub struct DownloadProgress {
    pub started: u64,
    pub completed: f32,
    pub total: usize,
    pub received: usize,
}

#[derive(Debug)]
#[allow(dead_code)]
pub enum TransferStatus {
    Starting,
    Transferring(DownloadProgress),
    Completed,
    Failed,
}

#[derive(Debug)]
pub struct TransferProgress {
    pub device_id: String,
    pub status: TransferStatus,
}

#[derive(Debug)]
pub enum DomainMessage {
    PreAccount,
    NearbyStations(Vec<NearbyStation>),
    StationRefreshed(StationConfig, Option<SensitiveConfig>),
    TransferProgress(TransferProgress),
}

#[derive(Clone, Debug)]
pub struct StreamInfo {
    pub size: u64,
    pub records: u64,
}

#[derive(Clone, Debug)]
pub struct BatteryInfo {
    pub percentage: f32,
    pub voltage: f32,
}

#[derive(Clone, Debug)]
pub struct SolarInfo {
    pub voltage: f32,
}

#[derive(Clone, Debug)]
pub struct StationConfig {
    pub device_id: String,
    pub name: String,
    pub last_seen: DateTime<Utc>,
    pub meta: StreamInfo,
    pub data: StreamInfo,
    pub battery: BatteryInfo,
    pub solar: SolarInfo,
    pub modules: Vec<ModuleConfig>,
}

#[derive(Clone, Debug)]
pub struct ModuleConfig {
    pub position: u32,
    pub module_id: String,
    pub key: String,
    pub sensors: Vec<SensorConfig>,
}

#[derive(Clone, Debug)]
pub struct SensorConfig {
    pub number: u32,
    pub key: String,
    pub full_key: String,
    pub calibrated_uom: String,
    pub uncalibrated_uom: String,
    pub value: Option<SensorValue>,
}

#[derive(Clone, Debug)]
pub struct SensorValue {
    pub time: DateTime<Utc>,
    pub value: f32,
    pub uncalibrated: f32,
}

#[derive(Clone, Debug)]
pub struct NearbyStation {
    pub device_id: String,
    pub busy: bool,
}

#[derive(Clone, Debug)]
pub struct SensitiveConfig {
    pub transmission: Option<TransmissionConfig>,
    pub networks: Vec<NetworkConfig>,
}

#[derive(Clone, Debug)]
pub struct NetworkConfig {
    pub ssid: String,
}

#[derive(Clone, Debug)]
pub struct TransmissionConfig {
    pub enabled: bool,
}

pub struct StationAndConnection {
    station: store::Station,
    #[allow(dead_code)]
    connection: Option<Connection>,
}

impl TryInto<StationConfig> for StationAndConnection {
    type Error = SdkMappingError;

    fn try_into(self) -> std::result::Result<StationConfig, Self::Error> {
        let station = self.station;

        Ok(StationConfig {
            device_id: station.device_id.0.to_owned(),
            name: station.name,
            last_seen: station.last_seen,
            meta: StreamInfo {
                size: station.meta.size,
                records: station.meta.records,
            },
            data: StreamInfo {
                size: station.data.size,
                records: station.data.records,
            },
            battery: BatteryInfo {
                percentage: station.battery.percentage,
                voltage: station.battery.voltage,
            },
            solar: SolarInfo {
                voltage: station.solar.voltage,
            },
            modules: station
                .modules
                .into_iter()
                .map(|module| ModuleConfig {
                    position: module.position,
                    module_id: module.hardware_id,
                    key: module.key.clone(),
                    sensors: module
                        .sensors
                        .into_iter()
                        .map(|sensor| SensorConfig {
                            number: sensor.number,
                            full_key: format!("{}.{}", &module.key, &sensor.key),
                            key: sensor.key,
                            calibrated_uom: sensor.calibrated_uom,
                            uncalibrated_uom: sensor.uncalibrated_uom,
                            value: sensor.value.map(|v| SensorValue {
                                time: v.time,
                                value: v.value,
                                uncalibrated: v.uncalibrated,
                            }),
                        })
                        .collect(),
                })
                .collect(),
        })
    }
}

#[derive(Error, Debug)]
pub enum SdkMappingError {}
