// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.82.1.
// ignore_for_file: non_constant_identifier_names, unused_element, duplicate_ignore, directives_ordering, curly_braces_in_flow_control_structures, unnecessary_lambdas, slash_for_doc_comments, prefer_const_literals_to_create_immutables, implicit_dynamic_list_literal, duplicate_import, unused_import, unnecessary_import, prefer_single_quotes, prefer_const_constructors, use_super_parameters, always_use_package_imports, annotate_overrides, invalid_use_of_protected_member, constant_identifier_names, invalid_use_of_internal_member, prefer_is_empty, unnecessary_const

import "bridge_definitions.dart";
import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:uuid/uuid.dart';
import 'bridge_generated.dart';
export 'bridge_generated.dart';
import 'dart:ffi' as ffi;

class NativePlatform extends FlutterRustBridgeBase<NativeWire> {
  NativePlatform(ffi.DynamicLibrary dylib) : super(NativeWire(dylib));

// Section: api2wire

  @protected
  ffi.Pointer<wire_uint_8_list> api2wire_String(String raw) {
    return api2wire_uint_8_list(utf8.encoder.convert(raw));
  }

  @protected
  ffi.Pointer<wire_AddOrUpdatePortalStation>
      api2wire_box_autoadd_add_or_update_portal_station(
          AddOrUpdatePortalStation raw) {
    final ptr = inner.new_box_autoadd_add_or_update_portal_station_0();
    _api_fill_to_wire_add_or_update_portal_station(raw, ptr.ref);
    return ptr;
  }

  @protected
  ffi.Pointer<wire_LocalFirmware> api2wire_box_autoadd_local_firmware(
      LocalFirmware raw) {
    final ptr = inner.new_box_autoadd_local_firmware_0();
    _api_fill_to_wire_local_firmware(raw, ptr.ref);
    return ptr;
  }

  @protected
  ffi.Pointer<wire_Tokens> api2wire_box_autoadd_tokens(Tokens raw) {
    final ptr = inner.new_box_autoadd_tokens_0();
    _api_fill_to_wire_tokens(raw, ptr.ref);
    return ptr;
  }

  @protected
  ffi.Pointer<ffi.Uint64> api2wire_box_autoadd_u64(int raw) {
    return inner.new_box_autoadd_u64_0(api2wire_u64(raw));
  }

  @protected
  ffi.Pointer<wire_WifiTransmissionConfig>
      api2wire_box_autoadd_wifi_transmission_config(
          WifiTransmissionConfig raw) {
    final ptr = inner.new_box_autoadd_wifi_transmission_config_0();
    _api_fill_to_wire_wifi_transmission_config(raw, ptr.ref);
    return ptr;
  }

  @protected
  int api2wire_i64(int raw) {
    return raw;
  }

  @protected
  ffi.Pointer<wire_list_record_archive> api2wire_list_record_archive(
      List<RecordArchive> raw) {
    final ans = inner.new_list_record_archive_0(raw.length);
    for (var i = 0; i < raw.length; ++i) {
      _api_fill_to_wire_record_archive(raw[i], ans.ref.ptr[i]);
    }
    return ans;
  }

  @protected
  ffi.Pointer<wire_Tokens> api2wire_opt_box_autoadd_tokens(Tokens? raw) {
    return raw == null ? ffi.nullptr : api2wire_box_autoadd_tokens(raw);
  }

  @protected
  ffi.Pointer<ffi.Uint64> api2wire_opt_box_autoadd_u64(int? raw) {
    return raw == null ? ffi.nullptr : api2wire_box_autoadd_u64(raw);
  }

  @protected
  int api2wire_u64(int raw) {
    return raw;
  }

  @protected
  ffi.Pointer<wire_uint_8_list> api2wire_uint_8_list(Uint8List raw) {
    final ans = inner.new_uint_8_list_0(raw.length);
    ans.ref.ptr.asTypedList(raw.length).setAll(0, raw);
    return ans;
  }

// Section: finalizer

// Section: api_fill_to_wire

  void _api_fill_to_wire_add_or_update_portal_station(
      AddOrUpdatePortalStation apiObj, wire_AddOrUpdatePortalStation wireObj) {
    wireObj.name = api2wire_String(apiObj.name);
    wireObj.device_id = api2wire_String(apiObj.deviceId);
    wireObj.location_name = api2wire_String(apiObj.locationName);
    wireObj.status_pb = api2wire_String(apiObj.statusPb);
  }

  void _api_fill_to_wire_box_autoadd_add_or_update_portal_station(
      AddOrUpdatePortalStation apiObj,
      ffi.Pointer<wire_AddOrUpdatePortalStation> wireObj) {
    _api_fill_to_wire_add_or_update_portal_station(apiObj, wireObj.ref);
  }

  void _api_fill_to_wire_box_autoadd_local_firmware(
      LocalFirmware apiObj, ffi.Pointer<wire_LocalFirmware> wireObj) {
    _api_fill_to_wire_local_firmware(apiObj, wireObj.ref);
  }

  void _api_fill_to_wire_box_autoadd_tokens(
      Tokens apiObj, ffi.Pointer<wire_Tokens> wireObj) {
    _api_fill_to_wire_tokens(apiObj, wireObj.ref);
  }

  void _api_fill_to_wire_box_autoadd_wifi_transmission_config(
      WifiTransmissionConfig apiObj,
      ffi.Pointer<wire_WifiTransmissionConfig> wireObj) {
    _api_fill_to_wire_wifi_transmission_config(apiObj, wireObj.ref);
  }

  void _api_fill_to_wire_local_firmware(
      LocalFirmware apiObj, wire_LocalFirmware wireObj) {
    wireObj.id = api2wire_i64(apiObj.id);
    wireObj.label = api2wire_String(apiObj.label);
    wireObj.time = api2wire_i64(apiObj.time);
    wireObj.module = api2wire_String(apiObj.module);
    wireObj.profile = api2wire_String(apiObj.profile);
  }

  void _api_fill_to_wire_opt_box_autoadd_tokens(
      Tokens? apiObj, ffi.Pointer<wire_Tokens> wireObj) {
    if (apiObj != null) _api_fill_to_wire_box_autoadd_tokens(apiObj, wireObj);
  }

  void _api_fill_to_wire_record_archive(
      RecordArchive apiObj, wire_RecordArchive wireObj) {
    wireObj.device_id = api2wire_String(apiObj.deviceId);
    wireObj.path = api2wire_String(apiObj.path);
    wireObj.head = api2wire_i64(apiObj.head);
    wireObj.tail = api2wire_i64(apiObj.tail);
  }

  void _api_fill_to_wire_tokens(Tokens apiObj, wire_Tokens wireObj) {
    wireObj.token = api2wire_String(apiObj.token);
    _api_fill_to_wire_transmission_token(
        apiObj.transmission, wireObj.transmission);
  }

  void _api_fill_to_wire_transmission_token(
      TransmissionToken apiObj, wire_TransmissionToken wireObj) {
    wireObj.token = api2wire_String(apiObj.token);
    wireObj.url = api2wire_String(apiObj.url);
  }

  void _api_fill_to_wire_wifi_transmission_config(
      WifiTransmissionConfig apiObj, wire_WifiTransmissionConfig wireObj) {
    wireObj.tokens = api2wire_opt_box_autoadd_tokens(apiObj.tokens);
  }
}

// ignore_for_file: camel_case_types, non_constant_identifier_names, avoid_positional_boolean_parameters, annotate_overrides, constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint

/// generated by flutter_rust_bridge
class NativeWire implements FlutterRustBridgeWireBase {
  @internal
  late final dartApi = DartApiDl(init_frb_dart_api_dl);

  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  NativeWire(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  NativeWire.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  void store_dart_post_cobject(
    DartPostCObjectFnType ptr,
  ) {
    return _store_dart_post_cobject(
      ptr,
    );
  }

  late final _store_dart_post_cobjectPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(DartPostCObjectFnType)>>(
          'store_dart_post_cobject');
  late final _store_dart_post_cobject = _store_dart_post_cobjectPtr
      .asFunction<void Function(DartPostCObjectFnType)>();

  Object get_dart_object(
    int ptr,
  ) {
    return _get_dart_object(
      ptr,
    );
  }

  late final _get_dart_objectPtr =
      _lookup<ffi.NativeFunction<ffi.Handle Function(ffi.UintPtr)>>(
          'get_dart_object');
  late final _get_dart_object =
      _get_dart_objectPtr.asFunction<Object Function(int)>();

  void drop_dart_object(
    int ptr,
  ) {
    return _drop_dart_object(
      ptr,
    );
  }

  late final _drop_dart_objectPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.UintPtr)>>(
          'drop_dart_object');
  late final _drop_dart_object =
      _drop_dart_objectPtr.asFunction<void Function(int)>();

  int new_dart_opaque(
    Object handle,
  ) {
    return _new_dart_opaque(
      handle,
    );
  }

  late final _new_dart_opaquePtr =
      _lookup<ffi.NativeFunction<ffi.UintPtr Function(ffi.Handle)>>(
          'new_dart_opaque');
  late final _new_dart_opaque =
      _new_dart_opaquePtr.asFunction<int Function(Object)>();

  int init_frb_dart_api_dl(
    ffi.Pointer<ffi.Void> obj,
  ) {
    return _init_frb_dart_api_dl(
      obj,
    );
  }

  late final _init_frb_dart_api_dlPtr =
      _lookup<ffi.NativeFunction<ffi.IntPtr Function(ffi.Pointer<ffi.Void>)>>(
          'init_frb_dart_api_dl');
  late final _init_frb_dart_api_dl = _init_frb_dart_api_dlPtr
      .asFunction<int Function(ffi.Pointer<ffi.Void>)>();

  void wire_start_native(
    int port_,
    ffi.Pointer<wire_uint_8_list> storage_path,
    ffi.Pointer<wire_uint_8_list> portal_base_url,
  ) {
    return _wire_start_native(
      port_,
      storage_path,
      portal_base_url,
    );
  }

  late final _wire_start_nativePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Int64, ffi.Pointer<wire_uint_8_list>,
              ffi.Pointer<wire_uint_8_list>)>>('wire_start_native');
  late final _wire_start_native = _wire_start_nativePtr.asFunction<
      void Function(
          int, ffi.Pointer<wire_uint_8_list>, ffi.Pointer<wire_uint_8_list>)>();

  void wire_get_my_stations(
    int port_,
  ) {
    return _wire_get_my_stations(
      port_,
    );
  }

  late final _wire_get_my_stationsPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64)>>(
          'wire_get_my_stations');
  late final _wire_get_my_stations =
      _wire_get_my_stationsPtr.asFunction<void Function(int)>();

  void wire_authenticate_portal(
    int port_,
    ffi.Pointer<wire_uint_8_list> email,
    ffi.Pointer<wire_uint_8_list> password,
  ) {
    return _wire_authenticate_portal(
      port_,
      email,
      password,
    );
  }

  late final _wire_authenticate_portalPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Int64, ffi.Pointer<wire_uint_8_list>,
              ffi.Pointer<wire_uint_8_list>)>>('wire_authenticate_portal');
  late final _wire_authenticate_portal =
      _wire_authenticate_portalPtr.asFunction<
          void Function(int, ffi.Pointer<wire_uint_8_list>,
              ffi.Pointer<wire_uint_8_list>)>();

  void wire_add_or_update_station_in_portal(
    int port_,
    ffi.Pointer<wire_Tokens> tokens,
    ffi.Pointer<wire_AddOrUpdatePortalStation> station,
  ) {
    return _wire_add_or_update_station_in_portal(
      port_,
      tokens,
      station,
    );
  }

  late final _wire_add_or_update_station_in_portalPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Int64, ffi.Pointer<wire_Tokens>,
                  ffi.Pointer<wire_AddOrUpdatePortalStation>)>>(
      'wire_add_or_update_station_in_portal');
  late final _wire_add_or_update_station_in_portal =
      _wire_add_or_update_station_in_portalPtr.asFunction<
          void Function(int, ffi.Pointer<wire_Tokens>,
              ffi.Pointer<wire_AddOrUpdatePortalStation>)>();

  void wire_configure_wifi_transmission(
    int port_,
    ffi.Pointer<wire_uint_8_list> device_id,
    ffi.Pointer<wire_WifiTransmissionConfig> config,
  ) {
    return _wire_configure_wifi_transmission(
      port_,
      device_id,
      config,
    );
  }

  late final _wire_configure_wifi_transmissionPtr = _lookup<
          ffi.NativeFunction<
              ffi.Void Function(ffi.Int64, ffi.Pointer<wire_uint_8_list>,
                  ffi.Pointer<wire_WifiTransmissionConfig>)>>(
      'wire_configure_wifi_transmission');
  late final _wire_configure_wifi_transmission =
      _wire_configure_wifi_transmissionPtr.asFunction<
          void Function(int, ffi.Pointer<wire_uint_8_list>,
              ffi.Pointer<wire_WifiTransmissionConfig>)>();

  void wire_clear_calibration(
    int port_,
    ffi.Pointer<wire_uint_8_list> device_id,
    int module,
  ) {
    return _wire_clear_calibration(
      port_,
      device_id,
      module,
    );
  }

  late final _wire_clear_calibrationPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Int64, ffi.Pointer<wire_uint_8_list>,
              ffi.UintPtr)>>('wire_clear_calibration');
  late final _wire_clear_calibration = _wire_clear_calibrationPtr
      .asFunction<void Function(int, ffi.Pointer<wire_uint_8_list>, int)>();

  void wire_calibrate(
    int port_,
    ffi.Pointer<wire_uint_8_list> device_id,
    int module,
    ffi.Pointer<wire_uint_8_list> data,
  ) {
    return _wire_calibrate(
      port_,
      device_id,
      module,
      data,
    );
  }

  late final _wire_calibratePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Int64, ffi.Pointer<wire_uint_8_list>,
              ffi.UintPtr, ffi.Pointer<wire_uint_8_list>)>>('wire_calibrate');
  late final _wire_calibrate = _wire_calibratePtr.asFunction<
      void Function(int, ffi.Pointer<wire_uint_8_list>, int,
          ffi.Pointer<wire_uint_8_list>)>();

  void wire_validate_tokens(
    int port_,
    ffi.Pointer<wire_Tokens> tokens,
  ) {
    return _wire_validate_tokens(
      port_,
      tokens,
    );
  }

  late final _wire_validate_tokensPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Int64, ffi.Pointer<wire_Tokens>)>>('wire_validate_tokens');
  late final _wire_validate_tokens = _wire_validate_tokensPtr
      .asFunction<void Function(int, ffi.Pointer<wire_Tokens>)>();

  void wire_start_download(
    int port_,
    ffi.Pointer<wire_uint_8_list> device_id,
    ffi.Pointer<ffi.Uint64> first,
  ) {
    return _wire_start_download(
      port_,
      device_id,
      first,
    );
  }

  late final _wire_start_downloadPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Int64, ffi.Pointer<wire_uint_8_list>,
              ffi.Pointer<ffi.Uint64>)>>('wire_start_download');
  late final _wire_start_download = _wire_start_downloadPtr.asFunction<
      void Function(
          int, ffi.Pointer<wire_uint_8_list>, ffi.Pointer<ffi.Uint64>)>();

  void wire_start_upload(
    int port_,
    ffi.Pointer<wire_uint_8_list> device_id,
    ffi.Pointer<wire_Tokens> tokens,
    ffi.Pointer<wire_list_record_archive> files,
  ) {
    return _wire_start_upload(
      port_,
      device_id,
      tokens,
      files,
    );
  }

  late final _wire_start_uploadPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Int64,
              ffi.Pointer<wire_uint_8_list>,
              ffi.Pointer<wire_Tokens>,
              ffi.Pointer<wire_list_record_archive>)>>('wire_start_upload');
  late final _wire_start_upload = _wire_start_uploadPtr.asFunction<
      void Function(int, ffi.Pointer<wire_uint_8_list>,
          ffi.Pointer<wire_Tokens>, ffi.Pointer<wire_list_record_archive>)>();

  void wire_cache_firmware(
    int port_,
    ffi.Pointer<wire_Tokens> tokens,
  ) {
    return _wire_cache_firmware(
      port_,
      tokens,
    );
  }

  late final _wire_cache_firmwarePtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Int64, ffi.Pointer<wire_Tokens>)>>('wire_cache_firmware');
  late final _wire_cache_firmware = _wire_cache_firmwarePtr
      .asFunction<void Function(int, ffi.Pointer<wire_Tokens>)>();

  void wire_upgrade_station(
    int port_,
    ffi.Pointer<wire_uint_8_list> device_id,
    ffi.Pointer<wire_LocalFirmware> firmware,
    bool swap,
  ) {
    return _wire_upgrade_station(
      port_,
      device_id,
      firmware,
      swap,
    );
  }

  late final _wire_upgrade_stationPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(
              ffi.Int64,
              ffi.Pointer<wire_uint_8_list>,
              ffi.Pointer<wire_LocalFirmware>,
              ffi.Bool)>>('wire_upgrade_station');
  late final _wire_upgrade_station = _wire_upgrade_stationPtr.asFunction<
      void Function(int, ffi.Pointer<wire_uint_8_list>,
          ffi.Pointer<wire_LocalFirmware>, bool)>();

  void wire_rust_release_mode(
    int port_,
  ) {
    return _wire_rust_release_mode(
      port_,
    );
  }

  late final _wire_rust_release_modePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64)>>(
          'wire_rust_release_mode');
  late final _wire_rust_release_mode =
      _wire_rust_release_modePtr.asFunction<void Function(int)>();

  void wire_create_log_sink(
    int port_,
  ) {
    return _wire_create_log_sink(
      port_,
    );
  }

  late final _wire_create_log_sinkPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int64)>>(
          'wire_create_log_sink');
  late final _wire_create_log_sink =
      _wire_create_log_sinkPtr.asFunction<void Function(int)>();

  ffi.Pointer<wire_AddOrUpdatePortalStation>
      new_box_autoadd_add_or_update_portal_station_0() {
    return _new_box_autoadd_add_or_update_portal_station_0();
  }

  late final _new_box_autoadd_add_or_update_portal_station_0Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<wire_AddOrUpdatePortalStation>
              Function()>>('new_box_autoadd_add_or_update_portal_station_0');
  late final _new_box_autoadd_add_or_update_portal_station_0 =
      _new_box_autoadd_add_or_update_portal_station_0Ptr
          .asFunction<ffi.Pointer<wire_AddOrUpdatePortalStation> Function()>();

  ffi.Pointer<wire_LocalFirmware> new_box_autoadd_local_firmware_0() {
    return _new_box_autoadd_local_firmware_0();
  }

  late final _new_box_autoadd_local_firmware_0Ptr =
      _lookup<ffi.NativeFunction<ffi.Pointer<wire_LocalFirmware> Function()>>(
          'new_box_autoadd_local_firmware_0');
  late final _new_box_autoadd_local_firmware_0 =
      _new_box_autoadd_local_firmware_0Ptr
          .asFunction<ffi.Pointer<wire_LocalFirmware> Function()>();

  ffi.Pointer<wire_Tokens> new_box_autoadd_tokens_0() {
    return _new_box_autoadd_tokens_0();
  }

  late final _new_box_autoadd_tokens_0Ptr =
      _lookup<ffi.NativeFunction<ffi.Pointer<wire_Tokens> Function()>>(
          'new_box_autoadd_tokens_0');
  late final _new_box_autoadd_tokens_0 = _new_box_autoadd_tokens_0Ptr
      .asFunction<ffi.Pointer<wire_Tokens> Function()>();

  ffi.Pointer<ffi.Uint64> new_box_autoadd_u64_0(
    int value,
  ) {
    return _new_box_autoadd_u64_0(
      value,
    );
  }

  late final _new_box_autoadd_u64_0Ptr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Uint64> Function(ffi.Uint64)>>(
          'new_box_autoadd_u64_0');
  late final _new_box_autoadd_u64_0 = _new_box_autoadd_u64_0Ptr
      .asFunction<ffi.Pointer<ffi.Uint64> Function(int)>();

  ffi.Pointer<wire_WifiTransmissionConfig>
      new_box_autoadd_wifi_transmission_config_0() {
    return _new_box_autoadd_wifi_transmission_config_0();
  }

  late final _new_box_autoadd_wifi_transmission_config_0Ptr = _lookup<
          ffi
          .NativeFunction<ffi.Pointer<wire_WifiTransmissionConfig> Function()>>(
      'new_box_autoadd_wifi_transmission_config_0');
  late final _new_box_autoadd_wifi_transmission_config_0 =
      _new_box_autoadd_wifi_transmission_config_0Ptr
          .asFunction<ffi.Pointer<wire_WifiTransmissionConfig> Function()>();

  ffi.Pointer<wire_list_record_archive> new_list_record_archive_0(
    int len,
  ) {
    return _new_list_record_archive_0(
      len,
    );
  }

  late final _new_list_record_archive_0Ptr = _lookup<
      ffi.NativeFunction<
          ffi.Pointer<wire_list_record_archive> Function(
              ffi.Int32)>>('new_list_record_archive_0');
  late final _new_list_record_archive_0 = _new_list_record_archive_0Ptr
      .asFunction<ffi.Pointer<wire_list_record_archive> Function(int)>();

  ffi.Pointer<wire_uint_8_list> new_uint_8_list_0(
    int len,
  ) {
    return _new_uint_8_list_0(
      len,
    );
  }

  late final _new_uint_8_list_0Ptr = _lookup<
          ffi
          .NativeFunction<ffi.Pointer<wire_uint_8_list> Function(ffi.Int32)>>(
      'new_uint_8_list_0');
  late final _new_uint_8_list_0 = _new_uint_8_list_0Ptr
      .asFunction<ffi.Pointer<wire_uint_8_list> Function(int)>();

  void free_WireSyncReturn(
    WireSyncReturn ptr,
  ) {
    return _free_WireSyncReturn(
      ptr,
    );
  }

  late final _free_WireSyncReturnPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(WireSyncReturn)>>(
          'free_WireSyncReturn');
  late final _free_WireSyncReturn =
      _free_WireSyncReturnPtr.asFunction<void Function(WireSyncReturn)>();
}

final class _Dart_Handle extends ffi.Opaque {}

final class wire_uint_8_list extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> ptr;

  @ffi.Int32()
  external int len;
}

final class wire_TransmissionToken extends ffi.Struct {
  external ffi.Pointer<wire_uint_8_list> token;

  external ffi.Pointer<wire_uint_8_list> url;
}

final class wire_Tokens extends ffi.Struct {
  external ffi.Pointer<wire_uint_8_list> token;

  external wire_TransmissionToken transmission;
}

final class wire_AddOrUpdatePortalStation extends ffi.Struct {
  external ffi.Pointer<wire_uint_8_list> name;

  external ffi.Pointer<wire_uint_8_list> device_id;

  external ffi.Pointer<wire_uint_8_list> location_name;

  external ffi.Pointer<wire_uint_8_list> status_pb;
}

final class wire_WifiTransmissionConfig extends ffi.Struct {
  external ffi.Pointer<wire_Tokens> tokens;
}

final class wire_RecordArchive extends ffi.Struct {
  external ffi.Pointer<wire_uint_8_list> device_id;

  external ffi.Pointer<wire_uint_8_list> path;

  @ffi.Int64()
  external int head;

  @ffi.Int64()
  external int tail;
}

final class wire_list_record_archive extends ffi.Struct {
  external ffi.Pointer<wire_RecordArchive> ptr;

  @ffi.Int32()
  external int len;
}

final class wire_LocalFirmware extends ffi.Struct {
  @ffi.Int64()
  external int id;

  external ffi.Pointer<wire_uint_8_list> label;

  @ffi.Int64()
  external int time;

  external ffi.Pointer<wire_uint_8_list> module;

  external ffi.Pointer<wire_uint_8_list> profile;
}

typedef DartPostCObjectFnType = ffi.Pointer<
    ffi.NativeFunction<
        ffi.Bool Function(DartPort port_id, ffi.Pointer<ffi.Void> message)>>;
typedef DartPort = ffi.Int64;
