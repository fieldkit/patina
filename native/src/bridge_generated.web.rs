use super::*;
// Section: wire functions

#[wasm_bindgen]
pub fn wire_start_native(port_: MessagePort, storage_path: String, portal_base_url: String) {
    wire_start_native_impl(port_, storage_path, portal_base_url)
}

#[wasm_bindgen]
pub fn wire_get_my_stations(port_: MessagePort) {
    wire_get_my_stations_impl(port_)
}

#[wasm_bindgen]
pub fn wire_authenticate_portal(port_: MessagePort, email: String, password: String) {
    wire_authenticate_portal_impl(port_, email, password)
}

#[wasm_bindgen]
pub fn wire_add_or_update_station_in_portal(port_: MessagePort, tokens: JsValue, station: JsValue) {
    wire_add_or_update_station_in_portal_impl(port_, tokens, station)
}

#[wasm_bindgen]
pub fn wire_configure_wifi_networks(port_: MessagePort, device_id: String, config: JsValue) {
    wire_configure_wifi_networks_impl(port_, device_id, config)
}

#[wasm_bindgen]
pub fn wire_configure_wifi_transmission(port_: MessagePort, device_id: String, config: JsValue) {
    wire_configure_wifi_transmission_impl(port_, device_id, config)
}

#[wasm_bindgen]
pub fn wire_clear_calibration(port_: MessagePort, device_id: String, module: usize) {
    wire_clear_calibration_impl(port_, device_id, module)
}

#[wasm_bindgen]
pub fn wire_calibrate(port_: MessagePort, device_id: String, module: usize, data: Box<[u8]>) {
    wire_calibrate_impl(port_, device_id, module, data)
}

#[wasm_bindgen]
pub fn wire_validate_tokens(port_: MessagePort, tokens: JsValue) {
    wire_validate_tokens_impl(port_, tokens)
}

#[wasm_bindgen]
pub fn wire_start_download(port_: MessagePort, device_id: String, first: JsValue) {
    wire_start_download_impl(port_, device_id, first)
}

#[wasm_bindgen]
pub fn wire_start_upload(port_: MessagePort, device_id: String, tokens: JsValue, files: JsValue) {
    wire_start_upload_impl(port_, device_id, tokens, files)
}

#[wasm_bindgen]
pub fn wire_cache_firmware(port_: MessagePort, tokens: JsValue) {
    wire_cache_firmware_impl(port_, tokens)
}

#[wasm_bindgen]
pub fn wire_upgrade_station(port_: MessagePort, device_id: String, firmware: JsValue, swap: bool) {
    wire_upgrade_station_impl(port_, device_id, firmware, swap)
}

#[wasm_bindgen]
pub fn wire_rust_release_mode(port_: MessagePort) {
    wire_rust_release_mode_impl(port_)
}

#[wasm_bindgen]
pub fn wire_create_log_sink(port_: MessagePort) {
    wire_create_log_sink_impl(port_)
}

// Section: allocate functions

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for String {
    fn wire2api(self) -> String {
        self
    }
}
impl Wire2Api<AddOrUpdatePortalStation> for JsValue {
    fn wire2api(self) -> AddOrUpdatePortalStation {
        let self_ = self.dyn_into::<JsArray>().unwrap();
        assert_eq!(
            self_.length(),
            4,
            "Expected 4 elements, got {}",
            self_.length()
        );
        AddOrUpdatePortalStation {
            name: self_.get(0).wire2api(),
            device_id: self_.get(1).wire2api(),
            location_name: self_.get(2).wire2api(),
            status_pb: self_.get(3).wire2api(),
        }
    }
}

impl Wire2Api<Vec<RecordArchive>> for JsValue {
    fn wire2api(self) -> Vec<RecordArchive> {
        self.dyn_into::<JsArray>()
            .unwrap()
            .iter()
            .map(Wire2Api::wire2api)
            .collect()
    }
}
impl Wire2Api<Vec<WifiNetworkConfig>> for JsValue {
    fn wire2api(self) -> Vec<WifiNetworkConfig> {
        self.dyn_into::<JsArray>()
            .unwrap()
            .iter()
            .map(Wire2Api::wire2api)
            .collect()
    }
}
impl Wire2Api<LocalFirmware> for JsValue {
    fn wire2api(self) -> LocalFirmware {
        let self_ = self.dyn_into::<JsArray>().unwrap();
        assert_eq!(
            self_.length(),
            5,
            "Expected 5 elements, got {}",
            self_.length()
        );
        LocalFirmware {
            id: self_.get(0).wire2api(),
            label: self_.get(1).wire2api(),
            time: self_.get(2).wire2api(),
            module: self_.get(3).wire2api(),
            profile: self_.get(4).wire2api(),
        }
    }
}
impl Wire2Api<Option<String>> for Option<String> {
    fn wire2api(self) -> Option<String> {
        self.map(Wire2Api::wire2api)
    }
}
impl Wire2Api<Option<Tokens>> for JsValue {
    fn wire2api(self) -> Option<Tokens> {
        (!self.is_undefined() && !self.is_null()).then(|| self.wire2api())
    }
}

impl Wire2Api<RecordArchive> for JsValue {
    fn wire2api(self) -> RecordArchive {
        let self_ = self.dyn_into::<JsArray>().unwrap();
        assert_eq!(
            self_.length(),
            4,
            "Expected 4 elements, got {}",
            self_.length()
        );
        RecordArchive {
            device_id: self_.get(0).wire2api(),
            path: self_.get(1).wire2api(),
            head: self_.get(2).wire2api(),
            tail: self_.get(3).wire2api(),
        }
    }
}
impl Wire2Api<Tokens> for JsValue {
    fn wire2api(self) -> Tokens {
        let self_ = self.dyn_into::<JsArray>().unwrap();
        assert_eq!(
            self_.length(),
            2,
            "Expected 2 elements, got {}",
            self_.length()
        );
        Tokens {
            token: self_.get(0).wire2api(),
            transmission: self_.get(1).wire2api(),
        }
    }
}
impl Wire2Api<TransmissionToken> for JsValue {
    fn wire2api(self) -> TransmissionToken {
        let self_ = self.dyn_into::<JsArray>().unwrap();
        assert_eq!(
            self_.length(),
            2,
            "Expected 2 elements, got {}",
            self_.length()
        );
        TransmissionToken {
            token: self_.get(0).wire2api(),
            url: self_.get(1).wire2api(),
        }
    }
}

impl Wire2Api<Vec<u8>> for Box<[u8]> {
    fn wire2api(self) -> Vec<u8> {
        self.into_vec()
    }
}

impl Wire2Api<WifiNetworkConfig> for JsValue {
    fn wire2api(self) -> WifiNetworkConfig {
        let self_ = self.dyn_into::<JsArray>().unwrap();
        assert_eq!(
            self_.length(),
            5,
            "Expected 5 elements, got {}",
            self_.length()
        );
        WifiNetworkConfig {
            index: self_.get(0).wire2api(),
            ssid: self_.get(1).wire2api(),
            password: self_.get(2).wire2api(),
            preferred: self_.get(3).wire2api(),
            keeping: self_.get(4).wire2api(),
        }
    }
}
impl Wire2Api<WifiNetworksConfig> for JsValue {
    fn wire2api(self) -> WifiNetworksConfig {
        let self_ = self.dyn_into::<JsArray>().unwrap();
        assert_eq!(
            self_.length(),
            1,
            "Expected 1 elements, got {}",
            self_.length()
        );
        WifiNetworksConfig {
            networks: self_.get(0).wire2api(),
        }
    }
}
impl Wire2Api<WifiTransmissionConfig> for JsValue {
    fn wire2api(self) -> WifiTransmissionConfig {
        let self_ = self.dyn_into::<JsArray>().unwrap();
        assert_eq!(
            self_.length(),
            1,
            "Expected 1 elements, got {}",
            self_.length()
        );
        WifiTransmissionConfig {
            tokens: self_.get(0).wire2api(),
        }
    }
}
// Section: impl Wire2Api for JsValue

impl Wire2Api<String> for JsValue {
    fn wire2api(self) -> String {
        self.as_string().expect("non-UTF-8 string, or not a string")
    }
}
impl Wire2Api<bool> for JsValue {
    fn wire2api(self) -> bool {
        self.is_truthy()
    }
}
impl Wire2Api<i64> for JsValue {
    fn wire2api(self) -> i64 {
        ::std::convert::TryInto::try_into(self.dyn_into::<js_sys::BigInt>().unwrap()).unwrap()
    }
}
impl Wire2Api<Option<String>> for JsValue {
    fn wire2api(self) -> Option<String> {
        (!self.is_undefined() && !self.is_null()).then(|| self.wire2api())
    }
}
impl Wire2Api<Option<u64>> for JsValue {
    fn wire2api(self) -> Option<u64> {
        (!self.is_undefined() && !self.is_null()).then(|| self.wire2api())
    }
}
impl Wire2Api<u64> for JsValue {
    fn wire2api(self) -> u64 {
        ::std::convert::TryInto::try_into(self.dyn_into::<js_sys::BigInt>().unwrap()).unwrap()
    }
}
impl Wire2Api<u8> for JsValue {
    fn wire2api(self) -> u8 {
        self.unchecked_into_f64() as _
    }
}
impl Wire2Api<Vec<u8>> for JsValue {
    fn wire2api(self) -> Vec<u8> {
        self.unchecked_into::<js_sys::Uint8Array>().to_vec().into()
    }
}
impl Wire2Api<usize> for JsValue {
    fn wire2api(self) -> usize {
        self.unchecked_into_f64() as _
    }
}
