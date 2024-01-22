use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
use flutter_rust_bridge::StreamSink;
use std::{
    io::Write,
    path::{Path, PathBuf},
    sync::{Arc, Mutex as StdMutex},
};
use sync::{FilesRecordSink, Server, ServerEvent, UdpTransport};
use thiserror::Error;
use tokio::sync::{mpsc::Sender, oneshot, Mutex};
use tokio::{runtime::Runtime, sync::mpsc::Receiver};
use tokio_stream::StreamExt;
use tracing::*;
use tracing_subscriber::{fmt::MakeWriter, EnvFilter};

use discovery::{DeviceId, Discovered, Discovery};
use query::{
    device::{self, HttpReply},
    portal::{DecodedToken, StatusCode},
};
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
            BackgroundMessage::StationReply(device_id, reply, raw) => {
                let station = {
                    let db = self.db.lock().await;
                    db.merge_reply(store::DeviceId(device_id.0), reply.clone())?
                };

                Ok(self
                    .publish_tx
                    .send(DomainMessage::StationRefreshed(
                        StationAndConnection {
                            station,
                            connection: Some(Connection::Connected),
                        }
                        .try_into()?,
                        Some(reply.try_into()?),
                        raw,
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

async fn create_sdk(
    storage_path: String,
    portal_base_url: String,
    publish_tx: Sender<DomainMessage>,
) -> Result<Sdk> {
    info!("startup:bg");

    let (bg_tx, bg_rx) = tokio::sync::mpsc::channel::<BackgroundMessage>(32);

    let nearby = NearbyDevices::new(bg_tx.clone());

    let server = Arc::new(Server::new(
        UdpTransport::new(),
        FilesRecordSink::new(&Path::new(&storage_path).join("fk-data")),
    ));

    let sdk = Sdk::new(
        storage_path,
        portal_base_url,
        nearby.clone(),
        server.clone(),
        publish_tx.clone(),
    )?;

    let db = sdk.open().await?;

    let merge = MergeAndPublishReplies::new(db, publish_tx.clone());

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

pub fn start_native(
    storage_path: String,
    portal_base_url: String,
    sink: StreamSink<DomainMessage>,
) -> Result<()> {
    info!("startup:runtime");
    let rt = start_runtime()?;

    let (publish_tx, mut publish_rx) = tokio::sync::mpsc::channel(20);
    let sdk = rt.block_on(create_sdk(storage_path, portal_base_url, publish_tx))?;

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
    portal_base_url: String,
    db: Arc<Mutex<Db>>,
    nearby: NearbyDevices,
    server: Arc<Server<UdpTransport, FilesRecordSink>>,
    publish_tx: Sender<DomainMessage>,
}

impl Sdk {
    fn new(
        storage_path: String,
        portal_base_url: String,
        nearby: NearbyDevices,
        server: Arc<Server<UdpTransport, FilesRecordSink>>,
        publish_tx: Sender<DomainMessage>,
    ) -> Result<Self> {
        Ok(Self {
            storage_path,
            portal_base_url,
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

    async fn authenticate_portal(
        &self,
        email: String,
        password: String,
    ) -> Result<Authenticated, PortalError> {
        let client = query::portal::Client::new(&self.portal_base_url)?;
        let tokens = client
            .login(query::portal::LoginPayload {
                email: email.clone(),
                password,
            })
            .await?;

        let authenticated = client.to_authenticated(tokens.clone())?;
        let ourselves = authenticated.query_ourselves().await?;
        let transmission = authenticated.issue_transmission_token().await?;

        Ok(Authenticated {
            name: ourselves.name,
            email,
            tokens: Tokens::from(tokens, transmission),
        })
    }

    async fn add_or_update_station_in_portal(
        &self,
        tokens: Tokens,
        station: AddOrUpdatePortalStation,
    ) -> Result<Option<u32>, PortalError> {
        let client = query::portal::Client::new(&self.portal_base_url)?;
        let authenticated = client.to_authenticated(tokens.into())?;

        Ok(authenticated
            .add_or_update_station(station.into())
            .await?
            .map(|s| s.id))
    }

    async fn validate_tokens(&self, tokens: Tokens) -> Result<Authenticated, PortalError> {
        let client = query::portal::Client::new(&self.portal_base_url)?;
        let client = client.to_authenticated(tokens.clone().into())?;

        let decoded = tokens.decoded()?;
        info!(
            "expires={:?} ({} remaining) issued={:?}",
            decoded.issued(),
            decoded.remaining(),
            decoded.expires(),
        );

        match client.query_ourselves().await {
            Ok(ourselves) => Ok(Authenticated {
                name: ourselves.name,
                email: ourselves.email,
                tokens,
            }),
            Err(query::portal::PortalError::HttpStatus(StatusCode::UNAUTHORIZED)) => {
                Ok(self.refresh_tokens(tokens).await?)
            }
            Err(e) => {
                warn!("query error: {:?}", e);
                Err(e.into())
            }
        }
    }

    async fn refresh_tokens(&self, tokens: Tokens) -> Result<Authenticated, PortalError> {
        let refresh_token = tokens.refresh_token()?;
        let client = query::portal::Client::new(&self.portal_base_url)?;
        let refreshed = client.use_refresh_token(&refresh_token).await?;
        let authenticated = client.to_authenticated(refreshed.clone())?;
        let ourselves = authenticated.query_ourselves().await?;
        let transmission = authenticated.issue_transmission_token().await?;
        Ok(Authenticated {
            name: ourselves.name,
            email: ourselves.email,
            tokens: Tokens::from(refreshed, transmission),
        })
    }

    async fn start_download(
        &self,
        device_id: DeviceId,
        first: Option<u64>,
    ) -> Result<TransferProgress> {
        info!("{:?} start download", &device_id);

        let discovered = self.nearby.get_discovered(&device_id).await;

        if let Some(discovered) = discovered {
            self.server.sync(discovered, first).await?;
        } else {
            warn!("{:?} undiscovered!", &device_id);
        }

        Ok(TransferProgress {
            device_id: device_id.0,
            status: TransferStatus::Starting,
        })
    }

    async fn start_upload(
        &self,
        device_id: DeviceId,
        tokens: Tokens,
        files: Vec<RecordArchive>,
    ) -> Result<TransferProgress, PortalError> {
        info!("{:?} start upload", &device_id);

        tokio::task::spawn({
            let client = query::portal::Client::new(&self.portal_base_url)?;
            let authenticated = client.to_authenticated(tokens.into())?;
            let publish_tx = self.publish_tx.clone();
            let device_id = device_id.clone();

            async move {
                for file in files.into_iter() {
                    info!("{:?} uploading", &file);

                    let res = authenticated
                        .upload_readings(&PathBuf::from(file.path))
                        .await;

                    let status = match res {
                        Ok(mut stream) => {
                            while let Some(Ok(bytes)) = stream.next().await {
                                match publish_tx
                                    .send(DomainMessage::UploadProgress(TransferProgress {
                                        device_id: device_id.clone().into(),
                                        status: TransferStatus::Uploading(UploadProgress {
                                            bytes_uploaded: bytes.bytes_uploaded,
                                            total_bytes: bytes.total_bytes,
                                        }),
                                    }))
                                    .await
                                {
                                    Ok(_) => {}
                                    Err(e) => warn!("Publish failed: {:?}", e),
                                }
                            }

                            TransferStatus::Completed
                        }
                        Err(e) => {
                            warn!("Upload failed: {:?}", e);

                            TransferStatus::Failed
                        }
                    };

                    publish_tx
                        .send(DomainMessage::UploadProgress(TransferProgress {
                            device_id: device_id.clone().into(),
                            status,
                        }))
                        .await
                        .expect("Publish failed")
                }
            }
        });

        Ok(TransferProgress {
            device_id: device_id.into(),
            status: TransferStatus::Starting,
        })
    }

    async fn get_nearby_addr(&self, device_id: &DeviceId) -> Result<Option<String>> {
        let discovered = self.nearby.get_discovered(&device_id).await;
        Ok(discovered.map(|d| {
            d.http_addr
                .map(|o| format!("{}", o))
                .expect("Expected HTTP url")
        }))
    }

    async fn configure_wifi_transmission(
        &self,
        device_id: DeviceId,
        config: WifiTransmissionConfig,
    ) -> Result<()> {
        if let Some(addr) = self.get_nearby_addr(&device_id).await? {
            let client = query::device::Client::new()?;
            client
                .configure_wifi_transmission(&addr, config.into())
                .await?;
        }

        Ok(())
    }

    async fn clear_calibration(&self, device_id: DeviceId, module: usize) -> Result<()> {
        info!("clear-calibration: {:?} {:?}", device_id, module);
        if let Some(addr) = self.get_nearby_addr(&device_id).await? {
            let client = query::device::Client::new()?;
            client.clear_calibration(&addr, module).await?;
            let status = client.query_readings(&addr).await?;
            self.nearby
                .mark_finished_and_publish_reply(&device_id, status)
                .await?;
        }

        Ok(())
    }

    async fn calibrate(&self, device_id: DeviceId, module: usize, data: Vec<u8>) -> Result<()> {
        info!("calibrate: {:?} {:?} {:?}", device_id, module, data);
        if let Some(addr) = self.get_nearby_addr(&device_id).await? {
            let client = query::device::Client::new()?;
            client.calibrate(&addr, module, &data).await?;
            let status = client.query_readings(&addr).await?;
            self.nearby
                .mark_finished_and_publish_reply(&device_id, status)
                .await?;
        }

        Ok(())
    }

    async fn cache_firmware(
        &self,
        tokens: Option<Tokens>,
    ) -> Result<FirmwareDownloadStatus, PortalError> {
        crate::firmware::cache_firmware(
            self.portal_base_url.clone(),
            self.storage_path.clone(),
            self.publish_tx.clone(),
            tokens,
        )
        .await
    }

    async fn upgrade_station(
        &self,
        device_id: DeviceId,
        firmware: LocalFirmware,
        swap: bool,
    ) -> Result<UpgradeProgress> {
        info!("upgrade-station: {:?} to {:?}", device_id, firmware);
        match self.get_nearby_addr(&device_id).await? {
            Some(addr) => {
                let nearby = self.nearby.clone();

                crate::firmware::upgrade(
                    nearby,
                    self.publish_tx.clone(),
                    self.storage_path.clone(),
                    device_id,
                    firmware,
                    swap,
                    addr,
                )
                .await
            }
            None => {
                warn!("No nearby for station!");

                Ok(UpgradeProgress {
                    device_id: device_id.0.clone(),
                    firmware_id: firmware.id,
                    status: UpgradeStatus::Failed,
                })
            }
        }
    }
}

pub fn get_my_stations() -> Result<Vec<StationConfig>> {
    Ok(with_runtime(|rt, sdk| rt.block_on(sdk.get_my_stations()))?)
}

pub fn authenticate_portal(email: String, password: String) -> Result<Authenticated, PortalError> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.authenticate_portal(email, password))
    })?)
}

pub fn add_or_update_station_in_portal(
    tokens: Tokens,
    station: AddOrUpdatePortalStation,
) -> Result<Option<u32>, PortalError> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.add_or_update_station_in_portal(tokens, station))
    })?)
}

pub fn configure_wifi_transmission(
    device_id: String,
    config: WifiTransmissionConfig,
) -> Result<()> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.configure_wifi_transmission(DeviceId(device_id.clone()), config))
    })?)
}

pub fn clear_calibration(device_id: String, module: usize) -> Result<()> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.clear_calibration(DeviceId(device_id.clone()), module))
    })?)
}

pub fn calibrate(device_id: String, module: usize, data: Vec<u8>) -> Result<()> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.calibrate(DeviceId(device_id.clone()), module, data))
    })?)
}

pub fn validate_tokens(tokens: Tokens) -> Result<Authenticated, PortalError> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.validate_tokens(tokens))
    })?)
}

pub fn start_download(device_id: String, first: Option<u64>) -> Result<TransferProgress> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.start_download(DeviceId(device_id.clone()), first))
    })?)
}

pub fn start_upload(
    device_id: String,
    tokens: Tokens,
    files: Vec<RecordArchive>,
) -> Result<TransferProgress, PortalError> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.start_upload(DeviceId(device_id.clone()), tokens, files))
    })?)
}

pub fn cache_firmware(tokens: Option<Tokens>) -> Result<FirmwareDownloadStatus, PortalError> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.cache_firmware(tokens))
    })?)
}

pub fn upgrade_station(
    device_id: String,
    firmware: LocalFirmware,
    swap: bool,
) -> Result<UpgradeProgress> {
    Ok(with_runtime(|rt, sdk| {
        rt.block_on(sdk.upgrade_station(DeviceId(device_id.clone()), firmware, swap))
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

fn with_runtime<R, E>(cb: impl FnOnce(&Runtime, &mut Sdk) -> Result<R, E>) -> Result<R, E> {
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

#[derive(Clone, Debug)]
pub struct WifiTransmissionConfig {
    pub tokens: Option<Tokens>,
}

impl Into<device::ConfigureWifiTransmission> for WifiTransmissionConfig {
    fn into(self) -> device::ConfigureWifiTransmission {
        self.tokens
            .map(|t| device::ConfigureWifiTransmission {
                enabled: true,
                token: Some(t.transmission.token.clone()),
                url: Some(t.transmission.url.clone()),
            })
            .unwrap_or(device::ConfigureWifiTransmission::default())
    }
}

#[derive(Clone, Debug)]
pub struct AddOrUpdatePortalStation {
    pub name: String,
    pub device_id: String,
    pub location_name: String,
    pub status_pb: String,
}

impl Into<query::portal::AddStation> for AddOrUpdatePortalStation {
    fn into(self) -> query::portal::AddStation {
        query::portal::AddStation {
            name: self.name,
            device_id: self.device_id,
            location_name: self.location_name,
            status_pb: self.status_pb,
        }
    }
}

#[derive(Clone, Debug)]
pub struct Tokens {
    pub token: String,
    pub transmission: TransmissionToken,
}

impl Tokens {
    fn from(tokens: query::portal::Tokens, transmission: query::portal::TransmissionToken) -> Self {
        Self {
            token: tokens.token,
            transmission: TransmissionToken {
                token: transmission.token,
                url: transmission.url,
            },
        }
    }

    fn decoded(&self) -> Result<DecodedToken, query::portal::PortalError> {
        DecodedToken::decode(&self.token)
    }

    fn refresh_token(&self) -> Result<String, query::portal::PortalError> {
        Ok(self.decoded()?.refresh_token)
    }
}

impl Into<query::portal::Tokens> for Tokens {
    fn into(self) -> query::portal::Tokens {
        query::portal::Tokens { token: self.token }
    }
}

#[derive(Clone, Debug)]
pub struct TransmissionToken {
    pub token: String,
    pub url: String,
}

#[derive(Debug)]
pub struct Authenticated {
    pub email: String,
    pub name: String,
    pub tokens: Tokens,
}

#[derive(Debug)]
pub struct DownloadProgress {
    pub started: u64,
    pub completed: f32,
    pub total: usize,
    pub received: usize,
}

#[derive(Debug)]
pub struct UploadProgress {
    pub bytes_uploaded: u64,
    pub total_bytes: u64,
}

#[derive(Debug)]
#[allow(dead_code)]
pub enum TransferStatus {
    Starting,
    Downloading(DownloadProgress),
    Uploading(UploadProgress),
    Processing,
    Completed,
    Failed,
}

#[derive(Debug)]
#[allow(dead_code)]
pub enum FirmwareDownloadStatus {
    Checking,
    Downloading(DownloadProgress),
    Offline,
    Completed,
    Failed,
}

#[derive(Debug)]
#[allow(dead_code)]
pub enum UpgradeStatus {
    Starting,
    Uploading(UploadProgress),
    Restarting,
    Completed,
    Failed,
}

#[derive(Debug)]
pub struct UpgradeProgress {
    pub device_id: String,
    pub firmware_id: i64,
    pub status: UpgradeStatus,
}

#[derive(Debug)]
pub struct TransferProgress {
    pub device_id: String,
    pub status: TransferStatus,
}

#[derive(Debug)]
pub struct RecordArchive {
    pub device_id: String,
    pub path: String,
    pub head: i64,
    pub tail: i64,
}

#[derive(Debug)]
pub enum DomainMessage {
    PreAccount,
    NearbyStations(Vec<NearbyStation>),
    StationRefreshed(StationConfig, Option<EphemeralConfig>, String),
    UploadProgress(TransferProgress),
    DownloadProgress(TransferProgress),
    FirmwareDownloadStatus(FirmwareDownloadStatus),
    UpgradeProgress(UpgradeProgress),
    AvailableFirmware(Vec<LocalFirmware>),
    RecordArchives(Vec<RecordArchive>),
}

#[derive(Clone, Debug)]
pub struct LocalFirmware {
    pub id: i64,
    pub label: String,
    pub time: i64,
    pub module: String,
    pub profile: String,
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
    pub firmware: FirmwareInfo,
    pub last_seen: DateTime<Utc>,
    pub meta: StreamInfo,
    pub data: StreamInfo,
    pub battery: BatteryInfo,
    pub solar: SolarInfo,
    pub modules: Vec<ModuleConfig>,
}

#[derive(Clone, Debug)]
pub struct CapabilitiesInfo {
    pub udp: bool,
}

#[derive(Clone, Debug)]
pub struct FirmwareInfo {
    pub label: String,
    pub time: i64,
}

#[derive(Clone, Debug)]
pub struct ModuleConfig {
    pub position: u32,
    pub module_id: String,
    pub key: String,
    pub sensors: Vec<SensorConfig>,
    pub configuration: Option<Vec<u8>>,
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
pub struct EphemeralConfig {
    pub transmission: Option<TransmissionConfig>,
    pub networks: Vec<NetworkConfig>,
    pub capabilities: DeviceCapabilities,
}

#[derive(Clone, Debug)]
pub struct DeviceCapabilities {
    pub udp: bool,
}

impl TryInto<EphemeralConfig> for HttpReply {
    type Error = SdkMappingError;

    fn try_into(self) -> std::result::Result<EphemeralConfig, Self::Error> {
        let transmission = self
            .transmission
            .map(|t| t.wifi)
            .flatten()
            .map(|_| TransmissionConfig { enabled: true });
        let capabilities = DeviceCapabilities {
            udp: self
                .network_settings
                .map(|s| s.supports_udp)
                .unwrap_or(false),
        };

        Ok(EphemeralConfig {
            transmission,
            networks: Vec::new(),
            capabilities,
        })
    }
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
            firmware: FirmwareInfo {
                label: station.firmware.label,
                time: station.firmware.time,
            },
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
                    configuration: module.configuration,
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

#[derive(Error, Debug)]
pub enum PortalError {
    #[error("Authentication")]
    Authentication,
    #[error("Other")]
    Other(String),
}

impl From<query::portal::PortalError> for PortalError {
    fn from(value: query::portal::PortalError) -> Self {
        if let query::portal::PortalError::HttpStatus(status) = value {
            if status.is_client_error() {
                return PortalError::Authentication;
            }
        }
        return PortalError::Other(value.to_string());
    }
}
