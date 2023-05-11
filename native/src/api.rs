use anyhow::{bail, Result};
use flutter_rust_bridge::StreamSink;
use std::io::Write;
use std::{thread::sleep, time::Duration};
use tokio::runtime::Runtime;
use tokio::sync::mpsc::Sender;
use tokio::sync::oneshot;
use tracing::info;
use tracing_subscriber::{fmt::MakeWriter, EnvFilter};

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
    let log_sink = LogSink { sink };

    if let Err(err) = tracing_subscriber::fmt()
        .with_max_level(tracing::Level::TRACE)
        .with_env_filter(EnvFilter::new("trace"))
        .with_writer(log_sink)
        .try_init()
    {
        bail!("{}", err);
    }

    Ok(())
}

#[allow(dead_code)]
pub enum DomainMessage {
    PreAccount,
    PostAccount,
    Tick,
    MyStations,
    StationRefreshed,
}

async fn create_sdk(publish_tx: tokio::sync::mpsc::Sender<DomainMessage>) -> Result<Sdk> {
    info!("startup:bg");
    tokio::spawn(async move { background_task().await });

    Ok(Sdk::new(publish_tx)?)
}

async fn background_task() {
    info!("bg:started");

    loop {
        info!("bg:tick");
        sleep(ONE_SECOND);
    }
}

pub fn start_native(sink: StreamSink<DomainMessage>) -> Result<()> {
    info!("startup:runtime");
    let rt = start_runtime()?;

    let (publish_tx, mut publish_rx) = tokio::sync::mpsc::channel(20);
    let sdk = rt.block_on(create_sdk(publish_tx))?;

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

pub struct Sdk {
    #[allow(dead_code)]
    publish_tx: Sender<DomainMessage>,
}

impl Sdk {
    fn new(publish_tx: Sender<DomainMessage>) -> Result<Self> {
        Ok(Self { publish_tx })
    }
}
