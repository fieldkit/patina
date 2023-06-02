use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::StreamSink;
use std::{
    io::Write,
    path::Path,
    sync::{Arc, Mutex as StdMutex},
};
use sync::{FilesRecordSink, Server, ServerEvent, UdpTransport};
use thiserror::Error;
use tokio::sync::{mpsc::Sender, oneshot, Mutex};
use tokio::{runtime::Runtime, sync::mpsc::Receiver};
use tracing::*;
use tracing_subscriber::{fmt::MakeWriter, EnvFilter};

use discovery::{DeviceId, Discovered, Discovery};
use query::portal::{DecodedToken, PortalError, StatusCode, Tokens as PortalTokens};
use store::Db;

use crate::nearby::{BackgroundMessage, Connection, NearbyDevices};

static SDK: StdMutex<Option<Sdk>> = StdMutex::new(None);
static RUNTIME: StdMutex<Option<Runtime>> = StdMutex::new(None);

struct MergeAndPublishReplies {
    db: Arc<Mutex<Db>>,
    publish_tx: Sender<DomainMessage>,
}

impl MergeAndPublishReplies {
    fn new(db: Arc<Mutex<Db>>, publish_tx: Sender<DomainMessage>) -> Self {
        Self { db, publish_tx }
    }

    async fn handle_background_message(&self, bg: BackgroundMessage) -> Result<()> {
        match bg {
            BackgroundMessage::Domain(message) => Ok(self.publish_tx.send(message).await?),
            BackgroundMessage::StationReply(device_id, reply) => {
                let station = {
                    let db = self.db.lock().await;
                    db.merge_reply(store::DeviceId(device_id.0), reply)?
                };
                Ok(self
                    .publish_tx
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

    async fn run(&self, mut bg_rx: Receiver<BackgroundMessage>) {
        while let Some(bg) = bg_rx.recv().await {
            match self.handle_background_message(bg).await {
                Err(e) => warn!("Errr handling background: {:?}", e),
                Ok(_) => {}
            }
        }
    }
}

async fn create_sdk(storage_path: String, publish_tx: Sender<DomainMessage>) -> Result<Sdk> {
    info!("startup:bg");

    let (bg_tx, bg_rx) = tokio::sync::mpsc::channel::<BackgroundMessage>(32);

    let nearby = NearbyDevices::new(bg_tx.clone());

    let server = Arc::new(Server::new(
        UdpTransport::new(),
        FilesRecordSink::new(&Path::new(&storage_path).join("fk-data")),
    ));

    let sdk = Sdk::new(
        storage_path,
        nearby.clone(),
        server.clone(),
        publish_tx.clone(),
    )?;

    let db = sdk.open().await?;

    let merge = MergeAndPublishReplies::new(db, publish_tx);

    tokio::spawn(async move { background_task(nearby, server, merge, bg_rx).await });

    Ok(sdk)
}

async fn background_task(
    nearby: NearbyDevices,
    server: Arc<Server<UdpTransport, FilesRecordSink>>,
    merge: MergeAndPublishReplies,
    bg_rx: Receiver<BackgroundMessage>,
) {
    info!("bg:started");

    let (transfer_publish, transfer_events) = tokio::sync::mpsc::channel::<ServerEvent>(32);

    let (discovery_tx, discovery_rx) = tokio::sync::mpsc::channel::<Discovered>(8);
    let discovery = Discovery::default();

    tokio::select! {
        _ = discovery.run(discovery_tx) => {},
        _ = nearby.run(discovery_rx, transfer_events) => {},
        _ = server.run(transfer_publish) => {},
        _ = merge.run(bg_rx) => {},
    };
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
    server: Arc<Server<UdpTransport, FilesRecordSink>>,
    publish_tx: Sender<DomainMessage>,
}

impl Sdk {
    fn new(
        storage_path: String,
        nearby: NearbyDevices,
        server: Arc<Server<UdpTransport, FilesRecordSink>>,
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

    async fn open(&self) -> Result<Arc<Mutex<Db>>> {
        let mut db = self.db.lock().await;
        db.open()?;

        Ok(self.db.clone())
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

        let decoded = tokens.decoded()?;
        info!(
            "expires={:?} ({} remaining) issued={:?}",
            decoded.issued(),
            decoded.remaining(),
            decoded.expires(),
        );

        match client.query_ourselves().await {
            Ok(_ourselves) => Ok(Some(tokens)),
            Err(PortalError::HttpStatus(StatusCode::UNAUTHORIZED)) => {
                Ok(self.refresh_tokens(tokens).await?)
            }
            Err(e) => {
                warn!("query error: {:?}", e);
                Err(e.into())
            }
        }
    }

    async fn refresh_tokens(&self, tokens: Tokens) -> Result<Option<Tokens>> {
        let refresh_token = tokens.refresh_token()?;
        let client = query::portal::Client::new()?;
        match client.use_refresh_token(&refresh_token).await {
            Ok(Some(refreshed)) => {
                let authenticated = client.to_authenticated(refreshed.clone())?;
                let transmission = authenticated.issue_transmission_token().await?;
                Ok(Some(Tokens {
                    token: refreshed.token,
                    transmission: Some(transmission).map(|t| TransmissionToken {
                        token: t.token,
                        url: t.url,
                    }),
                }))
            }
            Ok(None) => Ok(None),
            Err(_) => Ok(Some(tokens)),
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

fn start_runtime() -> Result<Runtime> {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(4)
        .enable_all()
        .thread_name("fieldkit-client")
        .build()?;

    Ok(rt)
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

#[derive(Debug)]
pub struct Tokens {
    pub token: String,
    pub transmission: Option<TransmissionToken>,
}

impl Tokens {
    fn decoded(&self) -> Result<DecodedToken, PortalError> {
        DecodedToken::decode(&self.token)
    }

    fn refresh_token(&self) -> Result<String> {
        Ok(self.decoded()?.refresh_token)
    }
}

#[derive(Debug)]
pub struct TransmissionToken {
    pub token: String,
    pub url: String,
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
    Processing,
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
