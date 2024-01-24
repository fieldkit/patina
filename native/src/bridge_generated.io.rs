use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_start_native(
    port_: i64,
    storage_path: *mut wire_uint_8_list,
    portal_base_url: *mut wire_uint_8_list,
) {
    wire_start_native_impl(port_, storage_path, portal_base_url)
}

#[no_mangle]
pub extern "C" fn wire_get_my_stations(port_: i64) {
    wire_get_my_stations_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_authenticate_portal(
    port_: i64,
    email: *mut wire_uint_8_list,
    password: *mut wire_uint_8_list,
) {
    wire_authenticate_portal_impl(port_, email, password)
}

#[no_mangle]
pub extern "C" fn wire_add_or_update_station_in_portal(
    port_: i64,
    tokens: *mut wire_Tokens,
    station: *mut wire_AddOrUpdatePortalStation,
) {
    wire_add_or_update_station_in_portal_impl(port_, tokens, station)
}

#[no_mangle]
pub extern "C" fn wire_configure_wifi_networks(
    port_: i64,
    device_id: *mut wire_uint_8_list,
    config: *mut wire_WifiNetworksConfig,
) {
    wire_configure_wifi_networks_impl(port_, device_id, config)
}

#[no_mangle]
pub extern "C" fn wire_configure_wifi_transmission(
    port_: i64,
    device_id: *mut wire_uint_8_list,
    config: *mut wire_WifiTransmissionConfig,
) {
    wire_configure_wifi_transmission_impl(port_, device_id, config)
}

#[no_mangle]
pub extern "C" fn wire_clear_calibration(
    port_: i64,
    device_id: *mut wire_uint_8_list,
    module: usize,
) {
    wire_clear_calibration_impl(port_, device_id, module)
}

#[no_mangle]
pub extern "C" fn wire_calibrate(
    port_: i64,
    device_id: *mut wire_uint_8_list,
    module: usize,
    data: *mut wire_uint_8_list,
) {
    wire_calibrate_impl(port_, device_id, module, data)
}

#[no_mangle]
pub extern "C" fn wire_validate_tokens(port_: i64, tokens: *mut wire_Tokens) {
    wire_validate_tokens_impl(port_, tokens)
}

#[no_mangle]
pub extern "C" fn wire_start_download(
    port_: i64,
    device_id: *mut wire_uint_8_list,
    first: *mut u64,
) {
    wire_start_download_impl(port_, device_id, first)
}

#[no_mangle]
pub extern "C" fn wire_start_upload(
    port_: i64,
    device_id: *mut wire_uint_8_list,
    tokens: *mut wire_Tokens,
    files: *mut wire_list_record_archive,
) {
    wire_start_upload_impl(port_, device_id, tokens, files)
}

#[no_mangle]
pub extern "C" fn wire_cache_firmware(port_: i64, tokens: *mut wire_Tokens) {
    wire_cache_firmware_impl(port_, tokens)
}

#[no_mangle]
pub extern "C" fn wire_upgrade_station(
    port_: i64,
    device_id: *mut wire_uint_8_list,
    firmware: *mut wire_LocalFirmware,
    swap: bool,
) {
    wire_upgrade_station_impl(port_, device_id, firmware, swap)
}

#[no_mangle]
pub extern "C" fn wire_rust_release_mode(port_: i64) {
    wire_rust_release_mode_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_create_log_sink(port_: i64) {
    wire_create_log_sink_impl(port_)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_box_autoadd_add_or_update_portal_station_0(
) -> *mut wire_AddOrUpdatePortalStation {
    support::new_leak_box_ptr(wire_AddOrUpdatePortalStation::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_local_firmware_0() -> *mut wire_LocalFirmware {
    support::new_leak_box_ptr(wire_LocalFirmware::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_tokens_0() -> *mut wire_Tokens {
    support::new_leak_box_ptr(wire_Tokens::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_u64_0(value: u64) -> *mut u64 {
    support::new_leak_box_ptr(value)
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_wifi_networks_config_0() -> *mut wire_WifiNetworksConfig {
    support::new_leak_box_ptr(wire_WifiNetworksConfig::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_box_autoadd_wifi_transmission_config_0() -> *mut wire_WifiTransmissionConfig {
    support::new_leak_box_ptr(wire_WifiTransmissionConfig::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_list_record_archive_0(len: i32) -> *mut wire_list_record_archive {
    let wrap = wire_list_record_archive {
        ptr: support::new_leak_vec_ptr(<wire_RecordArchive>::new_with_null_ptr(), len),
        len,
    };
    support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_list_wifi_network_config_0(len: i32) -> *mut wire_list_wifi_network_config {
    let wrap = wire_list_wifi_network_config {
        ptr: support::new_leak_vec_ptr(<wire_WifiNetworkConfig>::new_with_null_ptr(), len),
        len,
    };
    support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_uint_8_list_0(len: i32) -> *mut wire_uint_8_list {
    let ans = wire_uint_8_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
}

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for *mut wire_uint_8_list {
    fn wire2api(self) -> String {
        let vec: Vec<u8> = self.wire2api();
        String::from_utf8_lossy(&vec).into_owned()
    }
}
impl Wire2Api<AddOrUpdatePortalStation> for wire_AddOrUpdatePortalStation {
    fn wire2api(self) -> AddOrUpdatePortalStation {
        AddOrUpdatePortalStation {
            name: self.name.wire2api(),
            device_id: self.device_id.wire2api(),
            location_name: self.location_name.wire2api(),
            status_pb: self.status_pb.wire2api(),
        }
    }
}

impl Wire2Api<AddOrUpdatePortalStation> for *mut wire_AddOrUpdatePortalStation {
    fn wire2api(self) -> AddOrUpdatePortalStation {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<AddOrUpdatePortalStation>::wire2api(*wrap).into()
    }
}
impl Wire2Api<LocalFirmware> for *mut wire_LocalFirmware {
    fn wire2api(self) -> LocalFirmware {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<LocalFirmware>::wire2api(*wrap).into()
    }
}
impl Wire2Api<Tokens> for *mut wire_Tokens {
    fn wire2api(self) -> Tokens {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<Tokens>::wire2api(*wrap).into()
    }
}
impl Wire2Api<u64> for *mut u64 {
    fn wire2api(self) -> u64 {
        unsafe { *support::box_from_leak_ptr(self) }
    }
}
impl Wire2Api<WifiNetworksConfig> for *mut wire_WifiNetworksConfig {
    fn wire2api(self) -> WifiNetworksConfig {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<WifiNetworksConfig>::wire2api(*wrap).into()
    }
}
impl Wire2Api<WifiTransmissionConfig> for *mut wire_WifiTransmissionConfig {
    fn wire2api(self) -> WifiTransmissionConfig {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<WifiTransmissionConfig>::wire2api(*wrap).into()
    }
}

impl Wire2Api<Vec<RecordArchive>> for *mut wire_list_record_archive {
    fn wire2api(self) -> Vec<RecordArchive> {
        let vec = unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        };
        vec.into_iter().map(Wire2Api::wire2api).collect()
    }
}
impl Wire2Api<Vec<WifiNetworkConfig>> for *mut wire_list_wifi_network_config {
    fn wire2api(self) -> Vec<WifiNetworkConfig> {
        let vec = unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        };
        vec.into_iter().map(Wire2Api::wire2api).collect()
    }
}
impl Wire2Api<LocalFirmware> for wire_LocalFirmware {
    fn wire2api(self) -> LocalFirmware {
        LocalFirmware {
            id: self.id.wire2api(),
            label: self.label.wire2api(),
            time: self.time.wire2api(),
            module: self.module.wire2api(),
            profile: self.profile.wire2api(),
        }
    }
}

impl Wire2Api<RecordArchive> for wire_RecordArchive {
    fn wire2api(self) -> RecordArchive {
        RecordArchive {
            device_id: self.device_id.wire2api(),
            path: self.path.wire2api(),
            head: self.head.wire2api(),
            tail: self.tail.wire2api(),
        }
    }
}
impl Wire2Api<Tokens> for wire_Tokens {
    fn wire2api(self) -> Tokens {
        Tokens {
            token: self.token.wire2api(),
            transmission: self.transmission.wire2api(),
        }
    }
}
impl Wire2Api<TransmissionToken> for wire_TransmissionToken {
    fn wire2api(self) -> TransmissionToken {
        TransmissionToken {
            token: self.token.wire2api(),
            url: self.url.wire2api(),
        }
    }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
    fn wire2api(self) -> Vec<u8> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}

impl Wire2Api<WifiNetworkConfig> for wire_WifiNetworkConfig {
    fn wire2api(self) -> WifiNetworkConfig {
        WifiNetworkConfig {
            index: self.index.wire2api(),
            ssid: self.ssid.wire2api(),
            password: self.password.wire2api(),
            preferred: self.preferred.wire2api(),
            keeping: self.keeping.wire2api(),
        }
    }
}
impl Wire2Api<WifiNetworksConfig> for wire_WifiNetworksConfig {
    fn wire2api(self) -> WifiNetworksConfig {
        WifiNetworksConfig {
            networks: self.networks.wire2api(),
        }
    }
}
impl Wire2Api<WifiTransmissionConfig> for wire_WifiTransmissionConfig {
    fn wire2api(self) -> WifiTransmissionConfig {
        WifiTransmissionConfig {
            tokens: self.tokens.wire2api(),
        }
    }
}
// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_AddOrUpdatePortalStation {
    name: *mut wire_uint_8_list,
    device_id: *mut wire_uint_8_list,
    location_name: *mut wire_uint_8_list,
    status_pb: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list_record_archive {
    ptr: *mut wire_RecordArchive,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list_wifi_network_config {
    ptr: *mut wire_WifiNetworkConfig,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_LocalFirmware {
    id: i64,
    label: *mut wire_uint_8_list,
    time: i64,
    module: *mut wire_uint_8_list,
    profile: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_RecordArchive {
    device_id: *mut wire_uint_8_list,
    path: *mut wire_uint_8_list,
    head: i64,
    tail: i64,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_Tokens {
    token: *mut wire_uint_8_list,
    transmission: wire_TransmissionToken,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_TransmissionToken {
    token: *mut wire_uint_8_list,
    url: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
    ptr: *mut u8,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_WifiNetworkConfig {
    index: usize,
    ssid: *mut wire_uint_8_list,
    password: *mut wire_uint_8_list,
    preferred: bool,
    keeping: bool,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_WifiNetworksConfig {
    networks: *mut wire_list_wifi_network_config,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_WifiTransmissionConfig {
    tokens: *mut wire_Tokens,
}

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

impl NewWithNullPtr for wire_AddOrUpdatePortalStation {
    fn new_with_null_ptr() -> Self {
        Self {
            name: core::ptr::null_mut(),
            device_id: core::ptr::null_mut(),
            location_name: core::ptr::null_mut(),
            status_pb: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_AddOrUpdatePortalStation {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_LocalFirmware {
    fn new_with_null_ptr() -> Self {
        Self {
            id: Default::default(),
            label: core::ptr::null_mut(),
            time: Default::default(),
            module: core::ptr::null_mut(),
            profile: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_LocalFirmware {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_RecordArchive {
    fn new_with_null_ptr() -> Self {
        Self {
            device_id: core::ptr::null_mut(),
            path: core::ptr::null_mut(),
            head: Default::default(),
            tail: Default::default(),
        }
    }
}

impl Default for wire_RecordArchive {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_Tokens {
    fn new_with_null_ptr() -> Self {
        Self {
            token: core::ptr::null_mut(),
            transmission: Default::default(),
        }
    }
}

impl Default for wire_Tokens {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_TransmissionToken {
    fn new_with_null_ptr() -> Self {
        Self {
            token: core::ptr::null_mut(),
            url: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_TransmissionToken {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_WifiNetworkConfig {
    fn new_with_null_ptr() -> Self {
        Self {
            index: Default::default(),
            ssid: core::ptr::null_mut(),
            password: core::ptr::null_mut(),
            preferred: Default::default(),
            keeping: Default::default(),
        }
    }
}

impl Default for wire_WifiNetworkConfig {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_WifiNetworksConfig {
    fn new_with_null_ptr() -> Self {
        Self {
            networks: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_WifiNetworksConfig {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_WifiTransmissionConfig {
    fn new_with_null_ptr() -> Self {
        Self {
            tokens: core::ptr::null_mut(),
        }
    }
}

impl Default for wire_WifiTransmissionConfig {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
