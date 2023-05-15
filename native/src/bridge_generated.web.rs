use super::*;
// Section: wire functions

#[wasm_bindgen]
pub fn wire_rust_release_mode(port_: MessagePort) {
    wire_rust_release_mode_impl(port_)
}

#[wasm_bindgen]
pub fn wire_create_log_sink(port_: MessagePort) {
    wire_create_log_sink_impl(port_)
}

#[wasm_bindgen]
pub fn wire_start_native(port_: MessagePort) {
    wire_start_native_impl(port_)
}

#[wasm_bindgen]
pub fn wire_get_my_stations(port_: MessagePort) {
    wire_get_my_stations_impl(port_)
}

// Section: allocate functions

// Section: related functions

// Section: impl Wire2Api

// Section: impl Wire2Api for JsValue
