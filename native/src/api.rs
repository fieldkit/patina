use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::StreamSink;
use std::collections::HashMap;
use std::io::Write;
use std::sync::Arc;
use tokio::runtime::Runtime;
use tokio::sync::mpsc::Sender;
use tokio::sync::{oneshot, Mutex};
use tokio::time::{sleep, Duration};
use tracing::*;
use tracing_subscriber::{fmt::MakeWriter, EnvFilter};

use discovery::{DeviceId, Discovered, Discovery};
use query::HttpReply;
use store::Db;

const ONE_SECOND: Duration = Duration::from_secs(1);

static SDK: std::sync::Mutex<Option<Sdk>> = std::sync::Mutex::new(None);
static RUNTIME: std::sync::Mutex<Option<Runtime>> = std::sync::Mutex::new(None);

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

        for logger in ["hyper=", "reqwest=", "rusqlite_migration="] {
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
            let station = db.synchronize_reply(store::DeviceId(device_id.0), reply)?;
            Ok(publish_tx
                .send(DomainMessage::StationRefreshed(station.try_into()?))
                .await?)
        }
    }
}

async fn create_sdk(publish_tx: Sender<DomainMessage>) -> Result<Sdk> {
    info!("startup:bg");

    let (bg_tx, mut bg_rx) = tokio::sync::mpsc::channel::<BackgroundMessage>(32);

    let sdk = Sdk::new(publish_tx.clone())?;

    sdk.open().await?;

    tokio::spawn({
        let db = sdk.db.clone();
        async move {
            loop {
                while let Some(bg) = bg_rx.recv().await {
                    handle_background_message(&db, publish_tx.clone(), bg)
                        .await
                        .expect("Background error:")
                }
            }
        }
    });

    tokio::spawn(async move { background_task(bg_tx).await });

    Ok(sdk)
}

#[derive(Debug)]
enum BackgroundMessage {
    Domain(DomainMessage),
    StationReply(discovery::DeviceId, HttpReply),
}

async fn background_task(publish_tx: Sender<BackgroundMessage>) {
    info!("bg:started");

    let (tx, mut rx) = tokio::sync::mpsc::channel::<Discovered>(32);
    let discovery = Discovery::default();

    let nearby = NearbyDevices::new(publish_tx);

    let maintain_discoveries = tokio::spawn({
        let nearby = nearby.clone();
        async move {
            while let Some(announce) = rx.recv().await {
                if nearby.add_if_necessary(announce).await {
                    match nearby.publish().await {
                        Ok(_) => {}
                        Err(e) => warn!("Publish nearby error: {}", e),
                    }
                }
            }
        }
    });

    let query_stations = tokio::spawn({
        async move {
            loop {
                sleep(ONE_SECOND).await;

                match nearby.first_station_to_query().await {
                    Ok(Some(querying)) => match nearby.query_station(&querying).await {
                        Ok(status) => {
                            match nearby
                                .mark_finished_and_publish_reply(&querying.device_id, status)
                                .await
                            {
                                Ok(_) => {}
                                Err(e) => warn!("Update station: {}", e),
                            }
                        }
                        Err(e) => warn!("Query station: {}", e),
                    },
                    Ok(None) => {}
                    Err(e) => warn!("Station to query error: {}", e),
                }
            }
        }
    });

    let ticks = tokio::spawn({
        async move {
            loop {
                trace!("bg:tick");
                sleep(ONE_SECOND).await;
            }
        }
    });

    tokio::select! {
        _ = discovery.run(tx) => {},
        _ = maintain_discoveries => {},
        _ = query_stations => {},
        _ = ticks => {},
    };
}

type ModelTime = DateTime<Utc>;

#[derive(Clone, Debug)]
struct Querying {
    pub device_id: DeviceId,
    pub http_addr: String,
    pub attempted: Option<ModelTime>,
    pub finished: Option<ModelTime>,
}

impl Querying {
    fn should_query(&self) -> bool {
        match self.attempted {
            Some(attempted) => {
                if Utc::now() - attempted > chrono::Duration::seconds(10) {
                    true
                } else {
                    false
                }
            }
            None => true,
        }
    }
}

#[derive(Clone)]
struct NearbyDevices {
    publish_tx: Sender<BackgroundMessage>,
    devices: Arc<Mutex<HashMap<discovery::DeviceId, Querying>>>,
}

impl NearbyDevices {
    fn new(publish_tx: Sender<BackgroundMessage>) -> Self {
        Self {
            publish_tx,
            devices: Default::default(),
        }
    }

    async fn add_if_necessary(&self, announce: discovery::Discovered) -> bool {
        let mut devices = self.devices.lock().await;
        let device_id = &announce.device_id;
        if !devices.contains_key(device_id) {
            info!("bg:announce: {:?}", announce);

            devices.insert(
                device_id.clone(),
                Querying {
                    device_id: device_id.clone(),
                    http_addr: format!("{}", announce.http_addr),
                    attempted: None,
                    finished: None,
                },
            );

            true
        } else {
            false
        }
    }

    async fn first_station_to_query(&self) -> Result<Option<Querying>> {
        let mut devices = self.devices.lock().await;
        for (_, nearby) in devices.iter_mut() {
            trace!("{:?}", nearby);
            if nearby.should_query() {
                nearby.attempted = Some(Utc::now());
                nearby.finished = None;
                return Ok(Some(nearby.clone()));
            }
        }

        Ok(None)
    }

    async fn publish(&self) -> Result<()> {
        let devices = self.devices.lock().await;
        let nearby = devices
            .values()
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

    async fn mark_finished(&self, device_id: &discovery::DeviceId) -> Result<()> {
        let mut devices = self.devices.lock().await;
        let mut querying = devices.get_mut(device_id).expect("Whoa, no querying yet?");
        querying.finished = Some(Utc::now());

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
        let client = query::Client::new()?;
        Ok(client.query_status(&querying.http_addr).await?)
    }
}

fn start_runtime() -> Result<Runtime> {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(3)
        .enable_all()
        .thread_name("fieldkit-client")
        .build()?;

    Ok(rt)
}

pub fn start_native(sink: StreamSink<DomainMessage>) -> Result<()> {
    info!("startup:runtime");
    let rt = start_runtime()?;

    let (publish_tx, mut publish_rx) = tokio::sync::mpsc::channel(20);
    let sdk = rt.block_on(create_sdk(publish_tx))?;

    // Consider moving this to using the above channel?
    sink.add(DomainMessage::PreAccount);
    sink.add(DomainMessage::MyStations(vec![]));

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

struct Sdk {
    db: Arc<Mutex<Db>>,
    _publish_tx: Sender<DomainMessage>,
}

impl Sdk {
    fn new(publish_tx: Sender<DomainMessage>) -> Result<Self> {
        Ok(Self {
            db: Arc::new(Mutex::new(Db::new())),
            _publish_tx: publish_tx,
        })
    }

    async fn open(&self) -> Result<()> {
        let mut db = self.db.lock().await;
        db.open()?;
        Ok(())
    }

    async fn get_my_stations(&self) -> Result<Vec<StationConfig>> {
        let db = self.db.lock().await;
        let stations = db.get_stations()?;
        info!("my-stations: {:?}", stations);
        Ok(stations
            .into_iter()
            .map(|station| Ok(station.try_into()?))
            .collect::<Result<Vec<_>>>()?)
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

#[derive(Debug)]
pub enum DomainMessage {
    PreAccount,
    NearbyStations(Vec<NearbyStation>),
    StationRefreshed(StationConfig),
    MyStations(Vec<StationConfig>),
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
    pub last_seen: ModelTime,
    pub meta: StreamInfo,
    pub data: StreamInfo,
    pub battery: BatteryInfo,
    pub solar: SolarInfo,
    pub modules: Vec<ModuleConfig>,
}

#[derive(Clone, Debug)]
pub struct ModuleConfig {
    pub position: u32,
    pub key: String,
    pub sensors: Vec<SensorConfig>,
}

#[derive(Clone, Debug)]
pub struct SensorConfig {
    pub number: u32,
    pub key: String,
    pub calibrated_uom: String,
    pub uncalibrated_uom: String,
    pub value: Option<SensorValue>,
}

#[derive(Clone, Debug)]
pub struct SensorValue {
    pub value: f32,
    pub uncalibrated: f32,
}

#[derive(Clone, Debug)]
pub struct NearbyStation {
    pub device_id: String,
}

impl TryInto<StationConfig> for store::Station {
    type Error = SdkMappingError;

    fn try_into(self) -> std::result::Result<StationConfig, Self::Error> {
        Ok(StationConfig {
            device_id: self.device_id.0.to_owned(),
            name: self.name,
            last_seen: self.last_seen,
            meta: StreamInfo {
                size: self.meta.size,
                records: self.meta.records,
            },
            data: StreamInfo {
                size: self.data.size,
                records: self.data.records,
            },
            battery: BatteryInfo {
                percentage: self.battery.percentage,
                voltage: self.battery.voltage,
            },
            solar: SolarInfo {
                voltage: self.solar.voltage,
            },
            modules: self
                .modules
                .into_iter()
                .map(|module| ModuleConfig {
                    position: module.position,
                    key: module.name,
                    sensors: module
                        .sensors
                        .into_iter()
                        .map(|sensor| SensorConfig {
                            number: sensor.number,
                            key: sensor.key,
                            calibrated_uom: sensor.calibrated_uom,
                            uncalibrated_uom: sensor.uncalibrated_uom,
                            value: sensor.value.map(|v| SensorValue {
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

use thiserror::Error;

#[derive(Error, Debug)]
pub enum SdkMappingError {}
