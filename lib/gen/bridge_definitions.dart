// AUTO GENERATED FILE, DO NOT EDIT.
// Generated by `flutter_rust_bridge`@ 1.75.2.
// ignore_for_file: non_constant_identifier_names, unused_element, duplicate_ignore, directives_ordering, curly_braces_in_flow_control_structures, unnecessary_lambdas, slash_for_doc_comments, prefer_const_literals_to_create_immutables, implicit_dynamic_list_literal, duplicate_import, unused_import, unnecessary_import, prefer_single_quotes, prefer_const_constructors, use_super_parameters, always_use_package_imports, annotate_overrides, invalid_use_of_protected_member, constant_identifier_names, invalid_use_of_internal_member, prefer_is_empty, unnecessary_const

import 'bridge_generated.io.dart'
    if (dart.library.html) 'bridge_generated.web.dart';
import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:uuid/uuid.dart';
import 'package:freezed_annotation/freezed_annotation.dart' hide protected;

part 'bridge_definitions.freezed.dart';

abstract class Native {
  Future<bool> rustReleaseMode({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kRustReleaseModeConstMeta;

  Stream<String> createLogSink({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kCreateLogSinkConstMeta;

  Stream<DomainMessage> startNative({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kStartNativeConstMeta;

  Future<List<StationConfig>> getMyStations({dynamic hint});

  FlutterRustBridgeTaskConstMeta get kGetMyStationsConstMeta;
}

@freezed
class DomainMessage with _$DomainMessage {
  const factory DomainMessage.preAccount() = DomainMessage_PreAccount;
  const factory DomainMessage.nearbyStations(
    List<NearbyStation> field0,
  ) = DomainMessage_NearbyStations;
  const factory DomainMessage.myStations(
    List<StationConfig> field0,
  ) = DomainMessage_MyStations;
}

class ModuleConfig {
  final int position;
  final String key;
  final List<SensorConfig> sensors;

  const ModuleConfig({
    required this.position,
    required this.key,
    required this.sensors,
  });
}

class NearbyStation {
  final String deviceId;

  const NearbyStation({
    required this.deviceId,
  });
}

class SensorConfig {
  final int number;
  final String key;
  final String calibratedUom;
  final String uncalibratedUom;

  const SensorConfig({
    required this.number,
    required this.key,
    required this.calibratedUom,
    required this.uncalibratedUom,
  });
}

class StationConfig {
  final String name;
  final List<ModuleConfig> modules;

  const StationConfig({
    required this.name,
    required this.modules,
  });
}
