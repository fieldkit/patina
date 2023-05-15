use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_rust_release_mode(port_: i64) {
    wire_rust_release_mode_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_create_log_sink(port_: i64) {
    wire_create_log_sink_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_start_native(port_: i64) {
    wire_start_native_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_get_my_stations(port_: i64) {
    wire_get_my_stations_impl(port_)
}

// Section: allocate functions

// Section: related functions

// Section: impl Wire2Api

// Section: wire structs

// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
