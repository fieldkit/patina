#![allow(
    non_camel_case_types,
    unused,
    clippy::redundant_closure,
    clippy::useless_conversion,
    clippy::unit_arg,
    clippy::double_parens,
    non_snake_case,
    clippy::too_many_arguments
)]
// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.75.2.

use crate::api::*;
use core::panic::UnwindSafe;
use flutter_rust_bridge::*;
use std::ffi::c_void;
use std::sync::Arc;

// Section: imports

// Section: wire functions

fn wire_start_native_impl(
    port_: MessagePort,
    storage_path: impl Wire2Api<String> + UnwindSafe,
    portal_base_url: impl Wire2Api<String> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "start_native",
            port: Some(port_),
            mode: FfiCallMode::Stream,
        },
        move || {
            let api_storage_path = storage_path.wire2api();
            let api_portal_base_url = portal_base_url.wire2api();
            move |task_callback| {
                start_native(
                    api_storage_path,
                    api_portal_base_url,
                    task_callback.stream_sink(),
                )
            }
        },
    )
}
fn wire_get_my_stations_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "get_my_stations",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| get_my_stations(),
    )
}
fn wire_authenticate_portal_impl(
    port_: MessagePort,
    email: impl Wire2Api<String> + UnwindSafe,
    password: impl Wire2Api<String> + UnwindSafe,
) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "authenticate_portal",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_email = email.wire2api();
            let api_password = password.wire2api();
            move |task_callback| authenticate_portal(api_email, api_password)
        },
    )
}
fn wire_validate_tokens_impl(port_: MessagePort, tokens: impl Wire2Api<Tokens> + UnwindSafe) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "validate_tokens",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_tokens = tokens.wire2api();
            move |task_callback| validate_tokens(api_tokens)
        },
    )
}
fn wire_start_download_impl(port_: MessagePort, device_id: impl Wire2Api<String> + UnwindSafe) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "start_download",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_device_id = device_id.wire2api();
            move |task_callback| start_download(api_device_id)
        },
    )
}
fn wire_start_upload_impl(port_: MessagePort, device_id: impl Wire2Api<String> + UnwindSafe) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "start_upload",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || {
            let api_device_id = device_id.wire2api();
            move |task_callback| start_upload(api_device_id)
        },
    )
}
fn wire_rust_release_mode_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "rust_release_mode",
            port: Some(port_),
            mode: FfiCallMode::Normal,
        },
        move || move |task_callback| Ok(rust_release_mode()),
    )
}
fn wire_create_log_sink_impl(port_: MessagePort) {
    FLUTTER_RUST_BRIDGE_HANDLER.wrap(
        WrapInfo {
            debug_name: "create_log_sink",
            port: Some(port_),
            mode: FfiCallMode::Stream,
        },
        move || move |task_callback| create_log_sink(task_callback.stream_sink()),
    )
}
// Section: wrapper structs

// Section: static checks

// Section: allocate functions

// Section: related functions

// Section: impl Wire2Api

pub trait Wire2Api<T> {
    fn wire2api(self) -> T;
}

impl<T, S> Wire2Api<Option<T>> for *mut S
where
    *mut S: Wire2Api<T>,
{
    fn wire2api(self) -> Option<T> {
        (!self.is_null()).then(|| self.wire2api())
    }
}

impl Wire2Api<u8> for u8 {
    fn wire2api(self) -> u8 {
        self
    }
}

// Section: impl IntoDart

impl support::IntoDart for Authenticated {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.email.into_dart(),
            self.name.into_dart(),
            self.tokens.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for Authenticated {}

impl support::IntoDart for BatteryInfo {
    fn into_dart(self) -> support::DartAbi {
        vec![self.percentage.into_dart(), self.voltage.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for BatteryInfo {}

impl support::IntoDart for DomainMessage {
    fn into_dart(self) -> support::DartAbi {
        match self {
            Self::PreAccount => vec![0.into_dart()],
            Self::NearbyStations(field0) => vec![1.into_dart(), field0.into_dart()],
            Self::StationRefreshed(field0, field1) => {
                vec![2.into_dart(), field0.into_dart(), field1.into_dart()]
            }
            Self::TransferProgress(field0) => vec![3.into_dart(), field0.into_dart()],
        }
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for DomainMessage {}
impl support::IntoDart for DownloadProgress {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.started.into_dart(),
            self.completed.into_dart(),
            self.total.into_dart(),
            self.received.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for DownloadProgress {}

impl support::IntoDart for ModuleConfig {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.position.into_dart(),
            self.module_id.into_dart(),
            self.key.into_dart(),
            self.sensors.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for ModuleConfig {}

impl support::IntoDart for NearbyStation {
    fn into_dart(self) -> support::DartAbi {
        vec![self.device_id.into_dart(), self.busy.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for NearbyStation {}

impl support::IntoDart for NetworkConfig {
    fn into_dart(self) -> support::DartAbi {
        vec![self.ssid.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for NetworkConfig {}

impl support::IntoDart for SensitiveConfig {
    fn into_dart(self) -> support::DartAbi {
        vec![self.transmission.into_dart(), self.networks.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for SensitiveConfig {}

impl support::IntoDart for SensorConfig {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.number.into_dart(),
            self.key.into_dart(),
            self.full_key.into_dart(),
            self.calibrated_uom.into_dart(),
            self.uncalibrated_uom.into_dart(),
            self.value.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for SensorConfig {}

impl support::IntoDart for SensorValue {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.time.into_dart(),
            self.value.into_dart(),
            self.uncalibrated.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for SensorValue {}

impl support::IntoDart for SolarInfo {
    fn into_dart(self) -> support::DartAbi {
        vec![self.voltage.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for SolarInfo {}

impl support::IntoDart for StationConfig {
    fn into_dart(self) -> support::DartAbi {
        vec![
            self.device_id.into_dart(),
            self.name.into_dart(),
            self.last_seen.into_dart(),
            self.meta.into_dart(),
            self.data.into_dart(),
            self.battery.into_dart(),
            self.solar.into_dart(),
            self.modules.into_dart(),
        ]
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for StationConfig {}

impl support::IntoDart for StreamInfo {
    fn into_dart(self) -> support::DartAbi {
        vec![self.size.into_dart(), self.records.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for StreamInfo {}

impl support::IntoDart for Tokens {
    fn into_dart(self) -> support::DartAbi {
        vec![self.token.into_dart(), self.transmission.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for Tokens {}

impl support::IntoDart for TransferProgress {
    fn into_dart(self) -> support::DartAbi {
        vec![self.device_id.into_dart(), self.status.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for TransferProgress {}

impl support::IntoDart for TransferStatus {
    fn into_dart(self) -> support::DartAbi {
        match self {
            Self::Starting => vec![0.into_dart()],
            Self::Transferring(field0) => vec![1.into_dart(), field0.into_dart()],
            Self::Processing => vec![2.into_dart()],
            Self::Completed => vec![3.into_dart()],
            Self::Failed => vec![4.into_dart()],
        }
        .into_dart()
    }
}
impl support::IntoDartExceptPrimitive for TransferStatus {}
impl support::IntoDart for TransmissionConfig {
    fn into_dart(self) -> support::DartAbi {
        vec![self.enabled.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for TransmissionConfig {}

impl support::IntoDart for TransmissionToken {
    fn into_dart(self) -> support::DartAbi {
        vec![self.token.into_dart(), self.url.into_dart()].into_dart()
    }
}
impl support::IntoDartExceptPrimitive for TransmissionToken {}

// Section: executor

support::lazy_static! {
    pub static ref FLUTTER_RUST_BRIDGE_HANDLER: support::DefaultHandler = Default::default();
}

/// cbindgen:ignore
#[cfg(target_family = "wasm")]
#[path = "bridge_generated.web.rs"]
mod web;
#[cfg(target_family = "wasm")]
pub use web::*;

#[cfg(not(target_family = "wasm"))]
#[path = "bridge_generated.io.rs"]
mod io;
#[cfg(not(target_family = "wasm"))]
pub use io::*;
