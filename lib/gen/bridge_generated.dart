// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.75.2.
// ignore_for_file: non_constant_identifier_names, unused_element, duplicate_ignore, directives_ordering, curly_braces_in_flow_control_structures, unnecessary_lambdas, slash_for_doc_comments, prefer_const_literals_to_create_immutables, implicit_dynamic_list_literal, duplicate_import, unused_import, unnecessary_import, prefer_single_quotes, prefer_const_constructors, use_super_parameters, always_use_package_imports, annotate_overrides, invalid_use_of_protected_member, constant_identifier_names, invalid_use_of_internal_member, prefer_is_empty, unnecessary_const

import "bridge_definitions.dart";
import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:uuid/uuid.dart';
import 'bridge_generated.io.dart'
    if (dart.library.html) 'bridge_generated.web.dart';

class NativeImpl implements Native {
  final NativePlatform _platform;
  factory NativeImpl(ExternalLibrary dylib) =>
      NativeImpl.raw(NativePlatform(dylib));

  /// Only valid on web/WASM platforms.
  factory NativeImpl.wasm(FutureOr<WasmModule> module) =>
      NativeImpl(module as ExternalLibrary);
  NativeImpl.raw(this._platform);
  Future<bool> rustReleaseMode({dynamic hint}) {
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner.wire_rust_release_mode(port_),
      parseSuccessData: _wire2api_bool,
      constMeta: kRustReleaseModeConstMeta,
      argValues: [],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kRustReleaseModeConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "rust_release_mode",
        argNames: [],
      );

  Stream<String> createLogSink({dynamic hint}) {
    return _platform.executeStream(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner.wire_create_log_sink(port_),
      parseSuccessData: _wire2api_String,
      constMeta: kCreateLogSinkConstMeta,
      argValues: [],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kCreateLogSinkConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "create_log_sink",
        argNames: [],
      );

  Stream<DomainMessage> startNative(
      {required String storagePath, dynamic hint}) {
    var arg0 = _platform.api2wire_String(storagePath);
    return _platform.executeStream(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner.wire_start_native(port_, arg0),
      parseSuccessData: _wire2api_domain_message,
      constMeta: kStartNativeConstMeta,
      argValues: [storagePath],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kStartNativeConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "start_native",
        argNames: ["storagePath"],
      );

  Future<List<StationConfig>> getMyStations({dynamic hint}) {
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner.wire_get_my_stations(port_),
      parseSuccessData: _wire2api_list_station_config,
      constMeta: kGetMyStationsConstMeta,
      argValues: [],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kGetMyStationsConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "get_my_stations",
        argNames: [],
      );

  Future<Tokens?> authenticatePortal(
      {required String email, required String password, dynamic hint}) {
    var arg0 = _platform.api2wire_String(email);
    var arg1 = _platform.api2wire_String(password);
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) =>
          _platform.inner.wire_authenticate_portal(port_, arg0, arg1),
      parseSuccessData: _wire2api_opt_box_autoadd_tokens,
      constMeta: kAuthenticatePortalConstMeta,
      argValues: [email, password],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kAuthenticatePortalConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "authenticate_portal",
        argNames: ["email", "password"],
      );

  Future<Tokens?> validateTokens({required Tokens tokens, dynamic hint}) {
    var arg0 = _platform.api2wire_box_autoadd_tokens(tokens);
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner.wire_validate_tokens(port_, arg0),
      parseSuccessData: _wire2api_opt_box_autoadd_tokens,
      constMeta: kValidateTokensConstMeta,
      argValues: [tokens],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kValidateTokensConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "validate_tokens",
        argNames: ["tokens"],
      );

  Future<TransferProgress> startDownload(
      {required String deviceId, dynamic hint}) {
    var arg0 = _platform.api2wire_String(deviceId);
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner.wire_start_download(port_, arg0),
      parseSuccessData: _wire2api_transfer_progress,
      constMeta: kStartDownloadConstMeta,
      argValues: [deviceId],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kStartDownloadConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "start_download",
        argNames: ["deviceId"],
      );

  Future<TransferProgress> startUpload(
      {required String deviceId, dynamic hint}) {
    var arg0 = _platform.api2wire_String(deviceId);
    return _platform.executeNormal(FlutterRustBridgeTask(
      callFfi: (port_) => _platform.inner.wire_start_upload(port_, arg0),
      parseSuccessData: _wire2api_transfer_progress,
      constMeta: kStartUploadConstMeta,
      argValues: [deviceId],
      hint: hint,
    ));
  }

  FlutterRustBridgeTaskConstMeta get kStartUploadConstMeta =>
      const FlutterRustBridgeTaskConstMeta(
        debugName: "start_upload",
        argNames: ["deviceId"],
      );

  void dispose() {
    _platform.dispose();
  }
// Section: wire2api

  DateTime _wire2api_Chrono_Utc(dynamic raw) {
    return wire2apiTimestamp(ts: _wire2api_i64(raw), isUtc: true);
  }

  String _wire2api_String(dynamic raw) {
    return raw as String;
  }

  BatteryInfo _wire2api_battery_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 2)
      throw Exception('unexpected arr length: expect 2 but see ${arr.length}');
    return BatteryInfo(
      percentage: _wire2api_f32(arr[0]),
      voltage: _wire2api_f32(arr[1]),
    );
  }

  bool _wire2api_bool(dynamic raw) {
    return raw as bool;
  }

  SensitiveConfig _wire2api_box_autoadd_sensitive_config(dynamic raw) {
    return _wire2api_sensitive_config(raw);
  }

  SensorValue _wire2api_box_autoadd_sensor_value(dynamic raw) {
    return _wire2api_sensor_value(raw);
  }

  StationConfig _wire2api_box_autoadd_station_config(dynamic raw) {
    return _wire2api_station_config(raw);
  }

  Tokens _wire2api_box_autoadd_tokens(dynamic raw) {
    return _wire2api_tokens(raw);
  }

  TransferProgress _wire2api_box_autoadd_transfer_progress(dynamic raw) {
    return _wire2api_transfer_progress(raw);
  }

  TransmissionConfig _wire2api_box_autoadd_transmission_config(dynamic raw) {
    return _wire2api_transmission_config(raw);
  }

  DomainMessage _wire2api_domain_message(dynamic raw) {
    switch (raw[0]) {
      case 0:
        return DomainMessage_PreAccount();
      case 1:
        return DomainMessage_NearbyStations(
          _wire2api_list_nearby_station(raw[1]),
        );
      case 2:
        return DomainMessage_StationRefreshed(
          _wire2api_box_autoadd_station_config(raw[1]),
          _wire2api_opt_box_autoadd_sensitive_config(raw[2]),
        );
      case 3:
        return DomainMessage_TransferProgress(
          _wire2api_box_autoadd_transfer_progress(raw[1]),
        );
      default:
        throw Exception("unreachable");
    }
  }

  double _wire2api_f32(dynamic raw) {
    return raw as double;
  }

  int _wire2api_i32(dynamic raw) {
    return raw as int;
  }

  int _wire2api_i64(dynamic raw) {
    return castInt(raw);
  }

  List<ModuleConfig> _wire2api_list_module_config(dynamic raw) {
    return (raw as List<dynamic>).map(_wire2api_module_config).toList();
  }

  List<NearbyStation> _wire2api_list_nearby_station(dynamic raw) {
    return (raw as List<dynamic>).map(_wire2api_nearby_station).toList();
  }

  List<NetworkConfig> _wire2api_list_network_config(dynamic raw) {
    return (raw as List<dynamic>).map(_wire2api_network_config).toList();
  }

  List<SensorConfig> _wire2api_list_sensor_config(dynamic raw) {
    return (raw as List<dynamic>).map(_wire2api_sensor_config).toList();
  }

  List<StationConfig> _wire2api_list_station_config(dynamic raw) {
    return (raw as List<dynamic>).map(_wire2api_station_config).toList();
  }

  ModuleConfig _wire2api_module_config(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 3)
      throw Exception('unexpected arr length: expect 3 but see ${arr.length}');
    return ModuleConfig(
      position: _wire2api_u32(arr[0]),
      key: _wire2api_String(arr[1]),
      sensors: _wire2api_list_sensor_config(arr[2]),
    );
  }

  NearbyStation _wire2api_nearby_station(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 1)
      throw Exception('unexpected arr length: expect 1 but see ${arr.length}');
    return NearbyStation(
      deviceId: _wire2api_String(arr[0]),
    );
  }

  NetworkConfig _wire2api_network_config(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 1)
      throw Exception('unexpected arr length: expect 1 but see ${arr.length}');
    return NetworkConfig(
      ssid: _wire2api_String(arr[0]),
    );
  }

  String? _wire2api_opt_String(dynamic raw) {
    return raw == null ? null : _wire2api_String(raw);
  }

  SensitiveConfig? _wire2api_opt_box_autoadd_sensitive_config(dynamic raw) {
    return raw == null ? null : _wire2api_box_autoadd_sensitive_config(raw);
  }

  SensorValue? _wire2api_opt_box_autoadd_sensor_value(dynamic raw) {
    return raw == null ? null : _wire2api_box_autoadd_sensor_value(raw);
  }

  Tokens? _wire2api_opt_box_autoadd_tokens(dynamic raw) {
    return raw == null ? null : _wire2api_box_autoadd_tokens(raw);
  }

  TransmissionConfig? _wire2api_opt_box_autoadd_transmission_config(
      dynamic raw) {
    return raw == null ? null : _wire2api_box_autoadd_transmission_config(raw);
  }

  SensitiveConfig _wire2api_sensitive_config(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 2)
      throw Exception('unexpected arr length: expect 2 but see ${arr.length}');
    return SensitiveConfig(
      transmission: _wire2api_opt_box_autoadd_transmission_config(arr[0]),
      networks: _wire2api_list_network_config(arr[1]),
    );
  }

  SensorConfig _wire2api_sensor_config(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 6)
      throw Exception('unexpected arr length: expect 6 but see ${arr.length}');
    return SensorConfig(
      number: _wire2api_u32(arr[0]),
      key: _wire2api_String(arr[1]),
      fullKey: _wire2api_String(arr[2]),
      calibratedUom: _wire2api_String(arr[3]),
      uncalibratedUom: _wire2api_String(arr[4]),
      value: _wire2api_opt_box_autoadd_sensor_value(arr[5]),
    );
  }

  SensorValue _wire2api_sensor_value(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 2)
      throw Exception('unexpected arr length: expect 2 but see ${arr.length}');
    return SensorValue(
      value: _wire2api_f32(arr[0]),
      uncalibrated: _wire2api_f32(arr[1]),
    );
  }

  SolarInfo _wire2api_solar_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 1)
      throw Exception('unexpected arr length: expect 1 but see ${arr.length}');
    return SolarInfo(
      voltage: _wire2api_f32(arr[0]),
    );
  }

  StationConfig _wire2api_station_config(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 8)
      throw Exception('unexpected arr length: expect 8 but see ${arr.length}');
    return StationConfig(
      deviceId: _wire2api_String(arr[0]),
      name: _wire2api_String(arr[1]),
      lastSeen: _wire2api_Chrono_Utc(arr[2]),
      meta: _wire2api_stream_info(arr[3]),
      data: _wire2api_stream_info(arr[4]),
      battery: _wire2api_battery_info(arr[5]),
      solar: _wire2api_solar_info(arr[6]),
      modules: _wire2api_list_module_config(arr[7]),
    );
  }

  StreamInfo _wire2api_stream_info(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 2)
      throw Exception('unexpected arr length: expect 2 but see ${arr.length}');
    return StreamInfo(
      size: _wire2api_u64(arr[0]),
      records: _wire2api_u64(arr[1]),
    );
  }

  Tokens _wire2api_tokens(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 2)
      throw Exception('unexpected arr length: expect 2 but see ${arr.length}');
    return Tokens(
      token: _wire2api_String(arr[0]),
      refresh: _wire2api_opt_String(arr[1]),
    );
  }

  TransferProgress _wire2api_transfer_progress(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 2)
      throw Exception('unexpected arr length: expect 2 but see ${arr.length}');
    return TransferProgress(
      deviceId: _wire2api_String(arr[0]),
      status: _wire2api_transfer_status(arr[1]),
    );
  }

  TransferStatus _wire2api_transfer_status(dynamic raw) {
    return TransferStatus.values[raw as int];
  }

  TransmissionConfig _wire2api_transmission_config(dynamic raw) {
    final arr = raw as List<dynamic>;
    if (arr.length != 1)
      throw Exception('unexpected arr length: expect 1 but see ${arr.length}');
    return TransmissionConfig(
      enabled: _wire2api_bool(arr[0]),
    );
  }

  int _wire2api_u32(dynamic raw) {
    return raw as int;
  }

  int _wire2api_u64(dynamic raw) {
    return castInt(raw);
  }

  int _wire2api_u8(dynamic raw) {
    return raw as int;
  }

  Uint8List _wire2api_uint_8_list(dynamic raw) {
    return raw as Uint8List;
  }
}

// Section: api2wire

@protected
int api2wire_u8(int raw) {
  return raw;
}

// Section: finalizer
