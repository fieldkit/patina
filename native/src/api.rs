use anyhow::{bail, Result};
use flutter_rust_bridge::{frb, StreamSink};
use std::collections::HashMap;
use std::io::Write;
use std::{thread::sleep, time::Duration};
use tokio::runtime::Runtime;
use tokio::sync::mpsc::Sender;
use tokio::sync::oneshot;
use tracing::*;
use tracing_subscriber::{fmt::MakeWriter, EnvFilter};

use discovery::{Discovered, Discovery};

pub use store::{DeviceId, Station};

const ONE_SECOND: Duration = Duration::from_secs(1);

static SDK: std::sync::Mutex<Option<Sdk>> = std::sync::Mutex::new(None);
static RUNTIME: std::sync::Mutex<Option<Runtime>> = std::sync::Mutex::new(None);

fn start_runtime() -> Result<Runtime> {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(3)
        .enable_all()
        .thread_name("fieldkit-client")
        .build()?;

    Ok(rt)
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

pub enum DomainMessage {
    PreAccount,
    // PostAccount,
    // Tick,
    // MyStations,
    // StationRefreshed,
    NearbyStations(Vec<NearbyStation>),
}

async fn create_sdk(publish_tx: Sender<DomainMessage>) -> Result<Sdk> {
    info!("startup:bg");

    tokio::spawn({
        let publish_tx = publish_tx.clone();
        async move { background_task(publish_tx).await }
    });

    Ok(Sdk::new(publish_tx)?)
}

#[derive(Clone)]
pub struct NearbyStation {
    pub device_id: String,
}

async fn background_task(publish_tx: Sender<DomainMessage>) {
    info!("bg:started");

    let (tx, mut rx) = tokio::sync::mpsc::channel::<Discovered>(32);
    let discovery = Discovery::default();

    let maintain_discoveries = tokio::spawn({
        async move {
            let mut devices: HashMap<discovery::DeviceId, NearbyStation> = HashMap::new();
            while let Some(announce) = rx.recv().await {
                let device_id = &announce.device_id;
                if !devices.contains_key(device_id) {
                    info!("bg:announce: {:?}", announce);
                    devices.insert(
                        device_id.clone(),
                        NearbyStation {
                            device_id: device_id.0.to_owned(),
                        },
                    );

                    match publish_tx
                        .send(DomainMessage::NearbyStations(
                            devices.values().map(|i| i.clone()).collect(),
                        ))
                        .await
                    {
                        Ok(_) => {}
                        Err(e) => warn!("Send NearbyStations failed: {}", e),
                    };
                }
            }
        }
    });

    let ticks = tokio::spawn({
        async move {
            loop {
                trace!("bg:tick");
                sleep(ONE_SECOND);
            }
        }
    });

    tokio::select! {
        _ = discovery.run(tx) => {},
        _ = maintain_discoveries => {},
        _ = ticks => {},
    };
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
    #[allow(dead_code)]
    publish_tx: Sender<DomainMessage>,
}

impl Sdk {
    fn new(publish_tx: Sender<DomainMessage>) -> Result<Self> {
        Ok(Self { publish_tx })
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
fn get_nearby_stations() -> Result<Vec<Station>> {
    Ok(with_sdk(|_sdk| todo!())?)
}

#[frb(mirror(Station))]
pub struct _Station {
    pub id: Option<i64>,
    pub name: String,
    pub last_seen: chrono::DateTime<chrono::Utc>,
}
