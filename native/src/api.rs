use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::StreamSink;
use query::HttpReply;
use std::collections::HashMap;
use std::io::Write;
use std::sync::Arc;
use store::Db;
use tokio::runtime::Runtime;
use tokio::sync::mpsc::Sender;
use tokio::sync::{oneshot, Mutex};
use tokio::time::{sleep, Duration};
use tracing::*;
use tracing_subscriber::{fmt::MakeWriter, EnvFilter};

use discovery::{Discovered, Discovery};

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

        if !original.contains("hyper=") {
            original.push_str(",hyper=info");
        }

        if !original.contains("reqwest=") {
            original.push_str(",reqwest=info");
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

async fn create_sdk(publish_tx: Sender<DomainMessage>) -> Result<Sdk> {
    info!("startup:bg");

    tokio::spawn({
        let publish_tx = publish_tx.clone();
        async move { background_task(publish_tx).await }
    });

    Ok(Sdk::new(publish_tx)?)
}

async fn background_task(publish_tx: Sender<DomainMessage>) {
    info!("bg:started");

    let (tx, mut rx) = tokio::sync::mpsc::channel::<Discovered>(32);
    let discovery = Discovery::default();

    let nearby: NearbyDevices = Default::default();

    let maintain_discoveries = tokio::spawn({
        let nearby = nearby.clone();
        async move {
            while let Some(announce) = rx.recv().await {
                if nearby.add_if_necessary(announce).await {
                    match nearby.publish(publish_tx.clone()).await {
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
                            let device_id = querying.device_id.clone();
                            let device_id = discovery::DeviceId(device_id);
                            match nearby.update_from_status(&device_id, status).await {
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

#[derive(Default, Clone)]
struct NearbyDevices {
    devices: Arc<Mutex<HashMap<discovery::DeviceId, NearbyStation>>>,
}

impl NearbyDevices {
    async fn add_if_necessary(&self, announce: discovery::Discovered) -> bool {
        let mut devices = self.devices.lock().await;
        let device_id = &announce.device_id;
        if !devices.contains_key(device_id) {
            info!("bg:announce: {:?}", announce);

            devices.insert(
                device_id.clone(),
                NearbyStation {
                    device_id: device_id.0.to_owned(),
                    // This is only here because NearbyStation is
                    // exposed via bridge and so the types are limited.
                    http_addr: format!("{}", announce.http_addr),
                    querying: None,
                    config: None,
                },
            );

            true
        } else {
            false
        }
    }

    async fn first_station_to_query(&self) -> Result<Option<NearbyStation>> {
        let mut devices = self.devices.lock().await;
        for (_, nearby) in devices.iter_mut() {
            info!("nearby-device {:?}", nearby);
            if nearby.should_query() {
                nearby.querying = Some(Querying {
                    attempted: Some(Utc::now()),
                    finished: Some(Utc::now()),
                });
                return Ok(Some(nearby.clone()));
            }
        }

        Ok(None)
    }

    async fn publish(&self, publish_tx: Sender<DomainMessage>) -> Result<()> {
        let devices = self.devices.lock().await;
        let nearby = devices.values().map(|i| i.clone()).collect();

        match publish_tx.send(DomainMessage::NearbyStations(nearby)).await {
            Ok(_) => Ok(()),
            Err(e) => {
                warn!("Send NearbyStations failed: {}", e);
                Ok(())
            }
        }
    }

    async fn update_from_status(
        &self,
        device_id: &discovery::DeviceId,
        status: HttpReply,
    ) -> Result<()> {
        let mut devices = self.devices.lock().await;
        let mut nearby = devices.get_mut(device_id).expect("Whoa, no station yet?");

        trace!("updating {:?} {:?}", nearby, &status);
        let config = self.http_reply_to_station_config(status).await?;

        info!("updating {:?}", &config);
        nearby.config = Some(config);

        nearby.querying = Some(Querying {
            attempted: Some(Utc::now()),
            finished: Some(Utc::now()),
        });

        Ok(())
    }

    async fn http_reply_to_station_config(&self, reply: HttpReply) -> Result<StationConfig> {
        let status = reply.status.expect("No status");
        let identity = status.identity.expect("No identity");
        Ok(StationConfig {
            name: identity.name.to_owned(),
            generation_id: hex::encode(identity.generation_id),
            modules: Vec::new(),
        })
    }

    async fn query_station(&self, nearby: &NearbyStation) -> Result<HttpReply> {
        let client = query::Client::new()?;
        Ok(client.query_status(&nearby.http_addr).await?)
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
            info!("sdk:publish");
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
    db: Db,
    #[allow(dead_code)]
    publish_tx: Sender<DomainMessage>,
}

impl Sdk {
    fn new(publish_tx: Sender<DomainMessage>) -> Result<Self> {
        Ok(Self {
            db: Db::new(),
            publish_tx,
        })
    }
}

#[allow(dead_code)]
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

#[allow(dead_code)]
fn get_my_stations() -> Result<Vec<NearbyStation>> {
    Ok(with_sdk(|sdk| {
        let _stations = sdk.db.get_stations()?;
        Ok(Vec::new())
    })?)
}

pub enum DomainMessage {
    PreAccount,
    NearbyStations(Vec<NearbyStation>),
    // #[allow(dead_code)]
    // MyStations(Vec<NearbyStation>),
}

#[derive(Clone, Debug)]
pub struct StationConfig {
    pub name: String,
    pub generation_id: String,
    pub modules: Vec<ModuleConfig>,
}

#[derive(Clone, Debug)]
pub struct ModuleConfig {
    pub sensors: Vec<SensorConfig>,
}

#[derive(Clone, Debug)]
pub struct SensorConfig {}

#[derive(Clone, Debug)]
pub struct NearbyStation {
    pub device_id: String,
    pub http_addr: String,
    pub querying: Option<Querying>,
    pub config: Option<StationConfig>,
}

impl NearbyStation {
    fn should_query(&self) -> bool {
        match &self.querying {
            Some(querying) => querying.should_query(),
            None => true,
        }
    }
}

pub type ModelTime = DateTime<Utc>;

#[derive(Clone, Debug)]
pub struct Querying {
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
