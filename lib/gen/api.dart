// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.28.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import 'frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:freezed_annotation/freezed_annotation.dart' hide protected;
part 'api.freezed.dart';

// The type `CapabilitiesInfo` is not used by any `pub` functions, thus it is ignored.
// The type `LogSink` is not used by any `pub` functions, thus it is ignored.
// The type `MergeAndPublishReplies` is not used by any `pub` functions, thus it is ignored.
// The type `Sdk` is not used by any `pub` functions, thus it is ignored.
// The type `SdkMappingError` is not used by any `pub` functions, thus it is ignored.
// The type `StationAndConnection` is not used by any `pub` functions, thus it is ignored.

Stream<DomainMessage> startNative(
        {required String storagePath,
        required String portalBaseUrl,
        dynamic hint}) =>
    RustLib.instance.api.startNative(
        storagePath: storagePath, portalBaseUrl: portalBaseUrl, hint: hint);

Future<List<StationConfig>> getMyStations({dynamic hint}) =>
    RustLib.instance.api.getMyStations(hint: hint);

Future<Authenticated> authenticatePortal(
        {required String email, required String password, dynamic hint}) =>
    RustLib.instance.api
        .authenticatePortal(email: email, password: password, hint: hint);

Future<Registered> registerPortalAccount(
        {required String email,
        required String password,
        required String name,
        required bool tncAccount,
        dynamic hint}) =>
    RustLib.instance.api.registerPortalAccount(
        email: email,
        password: password,
        name: name,
        tncAccount: tncAccount,
        hint: hint);

Future<int?> addOrUpdateStationInPortal(
        {required Tokens tokens,
        required AddOrUpdatePortalStation station,
        dynamic hint}) =>
    RustLib.instance.api.addOrUpdateStationInPortal(
        tokens: tokens, station: station, hint: hint);

Future<void> configureDeploy(
        {required String deviceId,
        required DeployConfig config,
        dynamic hint}) =>
    RustLib.instance.api
        .configureDeploy(deviceId: deviceId, config: config, hint: hint);

Future<void> configureWifiNetworks(
        {required String deviceId,
        required WifiNetworksConfig config,
        dynamic hint}) =>
    RustLib.instance.api
        .configureWifiNetworks(deviceId: deviceId, config: config, hint: hint);

Future<void> configureWifiTransmission(
        {required String deviceId,
        required WifiTransmissionConfig config,
        dynamic hint}) =>
    RustLib.instance.api.configureWifiTransmission(
        deviceId: deviceId, config: config, hint: hint);

Future<void> configureLoraTransmission(
        {required String deviceId,
        required LoraTransmissionConfig config,
        dynamic hint}) =>
    RustLib.instance.api.configureLoraTransmission(
        deviceId: deviceId, config: config, hint: hint);

Future<void> verifyLoraTransmission({required String deviceId, dynamic hint}) =>
    RustLib.instance.api.verifyLoraTransmission(deviceId: deviceId, hint: hint);

Future<void> clearCalibration(
        {required String deviceId, required int module, dynamic hint}) =>
    RustLib.instance.api
        .clearCalibration(deviceId: deviceId, module: module, hint: hint);

Future<void> calibrate(
        {required String deviceId,
        required int module,
        required List<int> data,
        dynamic hint}) =>
    RustLib.instance.api
        .calibrate(deviceId: deviceId, module: module, data: data, hint: hint);

Future<Authenticated> validateTokens({required Tokens tokens, dynamic hint}) =>
    RustLib.instance.api.validateTokens(tokens: tokens, hint: hint);

Future<TransferProgress> startDownload(
        {required String deviceId, int? first, dynamic hint}) =>
    RustLib.instance.api
        .startDownload(deviceId: deviceId, first: first, hint: hint);

Future<TransferProgress> startUpload(
        {required String deviceId,
        required Tokens tokens,
        required List<RecordArchive> files,
        dynamic hint}) =>
    RustLib.instance.api.startUpload(
        deviceId: deviceId, tokens: tokens, files: files, hint: hint);

Future<FirmwareDownloadStatus> cacheFirmware({Tokens? tokens, dynamic hint}) =>
    RustLib.instance.api.cacheFirmware(tokens: tokens, hint: hint);

Future<UpgradeProgress> upgradeStation(
        {required String deviceId,
        required LocalFirmware firmware,
        required bool swap,
        dynamic hint}) =>
    RustLib.instance.api.upgradeStation(
        deviceId: deviceId, firmware: firmware, swap: swap, hint: hint);

Future<bool> rustReleaseMode({dynamic hint}) =>
    RustLib.instance.api.rustReleaseMode(hint: hint);

Stream<String> createLogSink({dynamic hint}) =>
    RustLib.instance.api.createLogSink(hint: hint);

class AddOrUpdatePortalStation {
  final String name;
  final String deviceId;
  final String locationName;
  final String statusPb;

  const AddOrUpdatePortalStation({
    required this.name,
    required this.deviceId,
    required this.locationName,
    required this.statusPb,
  });

  @override
  int get hashCode =>
      name.hashCode ^
      deviceId.hashCode ^
      locationName.hashCode ^
      statusPb.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddOrUpdatePortalStation &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          deviceId == other.deviceId &&
          locationName == other.locationName &&
          statusPb == other.statusPb;
}

class Authenticated {
  final String email;
  final String name;
  final Tokens tokens;

  const Authenticated({
    required this.email,
    required this.name,
    required this.tokens,
  });

  @override
  int get hashCode => email.hashCode ^ name.hashCode ^ tokens.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Authenticated &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          name == other.name &&
          tokens == other.tokens;
}

class BatteryInfo {
  final double percentage;
  final double voltage;

  const BatteryInfo({
    required this.percentage,
    required this.voltage,
  });

  @override
  int get hashCode => percentage.hashCode ^ voltage.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatteryInfo &&
          runtimeType == other.runtimeType &&
          percentage == other.percentage &&
          voltage == other.voltage;
}

class DeployConfig {
  final String location;
  final int deployed;
  final Schedule schedule;

  const DeployConfig({
    required this.location,
    required this.deployed,
    required this.schedule,
  });

  @override
  int get hashCode => location.hashCode ^ deployed.hashCode ^ schedule.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeployConfig &&
          runtimeType == other.runtimeType &&
          location == other.location &&
          deployed == other.deployed &&
          schedule == other.schedule;
}

class DeploymentConfig {
  final int startTime;

  const DeploymentConfig({
    required this.startTime,
  });

  @override
  int get hashCode => startTime.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeploymentConfig &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime;
}

class DeviceCapabilities {
  final bool udp;

  const DeviceCapabilities({
    required this.udp,
  });

  @override
  int get hashCode => udp.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceCapabilities &&
          runtimeType == other.runtimeType &&
          udp == other.udp;
}

@freezed
sealed class DomainMessage with _$DomainMessage {
  const factory DomainMessage.preAccount() = DomainMessage_PreAccount;
  const factory DomainMessage.nearbyStations(
    List<NearbyStation> field0,
  ) = DomainMessage_NearbyStations;
  const factory DomainMessage.stationRefreshed(
    StationConfig field0,
    EphemeralConfig? field1,
    String field2,
  ) = DomainMessage_StationRefreshed;
  const factory DomainMessage.uploadProgress(
    TransferProgress field0,
  ) = DomainMessage_UploadProgress;
  const factory DomainMessage.downloadProgress(
    TransferProgress field0,
  ) = DomainMessage_DownloadProgress;
  const factory DomainMessage.firmwareDownloadStatus(
    FirmwareDownloadStatus field0,
  ) = DomainMessage_FirmwareDownloadStatus;
  const factory DomainMessage.upgradeProgress(
    UpgradeProgress field0,
  ) = DomainMessage_UpgradeProgress;
  const factory DomainMessage.availableFirmware(
    List<LocalFirmware> field0,
  ) = DomainMessage_AvailableFirmware;
  const factory DomainMessage.recordArchives(
    List<RecordArchive> field0,
  ) = DomainMessage_RecordArchives;
}

class DownloadProgress {
  final int started;
  final double completed;
  final int total;
  final int received;

  const DownloadProgress({
    required this.started,
    required this.completed,
    required this.total,
    required this.received,
  });

  @override
  int get hashCode =>
      started.hashCode ^
      completed.hashCode ^
      total.hashCode ^
      received.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadProgress &&
          runtimeType == other.runtimeType &&
          started == other.started &&
          completed == other.completed &&
          total == other.total &&
          received == other.received;
}

class EphemeralConfig {
  final DeploymentConfig? deployment;
  final TransmissionConfig? transmission;
  final List<NetworkConfig> networks;
  final LoraConfig? lora;
  final DeviceCapabilities capabilities;
  final Uint8List events;

  const EphemeralConfig({
    this.deployment,
    this.transmission,
    required this.networks,
    this.lora,
    required this.capabilities,
    required this.events,
  });

  @override
  int get hashCode =>
      deployment.hashCode ^
      transmission.hashCode ^
      networks.hashCode ^
      lora.hashCode ^
      capabilities.hashCode ^
      events.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EphemeralConfig &&
          runtimeType == other.runtimeType &&
          deployment == other.deployment &&
          transmission == other.transmission &&
          networks == other.networks &&
          lora == other.lora &&
          capabilities == other.capabilities &&
          events == other.events;
}

@freezed
sealed class FirmwareDownloadStatus with _$FirmwareDownloadStatus {
  const factory FirmwareDownloadStatus.checking() =
      FirmwareDownloadStatus_Checking;
  const factory FirmwareDownloadStatus.downloading(
    DownloadProgress field0,
  ) = FirmwareDownloadStatus_Downloading;
  const factory FirmwareDownloadStatus.offline() =
      FirmwareDownloadStatus_Offline;
  const factory FirmwareDownloadStatus.completed() =
      FirmwareDownloadStatus_Completed;
  const factory FirmwareDownloadStatus.failed() = FirmwareDownloadStatus_Failed;
}

class FirmwareInfo {
  final String label;
  final int time;

  const FirmwareInfo({
    required this.label,
    required this.time,
  });

  @override
  int get hashCode => label.hashCode ^ time.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FirmwareInfo &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          time == other.time;
}

class LocalFirmware {
  final int id;
  final String label;
  final int time;
  final String module;
  final String profile;

  const LocalFirmware({
    required this.id,
    required this.label,
    required this.time,
    required this.module,
    required this.profile,
  });

  @override
  int get hashCode =>
      id.hashCode ^
      label.hashCode ^
      time.hashCode ^
      module.hashCode ^
      profile.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalFirmware &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          time == other.time &&
          module == other.module &&
          profile == other.profile;
}

enum LoraBand {
  f915Mhz,
  f868Mhz,
}

class LoraConfig {
  final bool available;
  final LoraBand band;
  final Uint8List deviceEui;
  final Uint8List appKey;
  final Uint8List joinEui;
  final Uint8List deviceAddress;
  final Uint8List networkSessionKey;
  final Uint8List appSessionKey;

  const LoraConfig({
    required this.available,
    required this.band,
    required this.deviceEui,
    required this.appKey,
    required this.joinEui,
    required this.deviceAddress,
    required this.networkSessionKey,
    required this.appSessionKey,
  });

  @override
  int get hashCode =>
      available.hashCode ^
      band.hashCode ^
      deviceEui.hashCode ^
      appKey.hashCode ^
      joinEui.hashCode ^
      deviceAddress.hashCode ^
      networkSessionKey.hashCode ^
      appSessionKey.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoraConfig &&
          runtimeType == other.runtimeType &&
          available == other.available &&
          band == other.band &&
          deviceEui == other.deviceEui &&
          appKey == other.appKey &&
          joinEui == other.joinEui &&
          deviceAddress == other.deviceAddress &&
          networkSessionKey == other.networkSessionKey &&
          appSessionKey == other.appSessionKey;
}

class LoraTransmissionConfig {
  final int? band;
  final Uint8List? appKey;
  final Uint8List? joinEui;
  final Schedule? schedule;

  const LoraTransmissionConfig({
    this.band,
    this.appKey,
    this.joinEui,
    this.schedule,
  });

  @override
  int get hashCode =>
      band.hashCode ^ appKey.hashCode ^ joinEui.hashCode ^ schedule.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoraTransmissionConfig &&
          runtimeType == other.runtimeType &&
          band == other.band &&
          appKey == other.appKey &&
          joinEui == other.joinEui &&
          schedule == other.schedule;
}

class ModuleConfig {
  final int position;
  final String moduleId;
  final String key;
  final List<SensorConfig> sensors;
  final Uint8List? configuration;

  const ModuleConfig({
    required this.position,
    required this.moduleId,
    required this.key,
    required this.sensors,
    this.configuration,
  });

  @override
  int get hashCode =>
      position.hashCode ^
      moduleId.hashCode ^
      key.hashCode ^
      sensors.hashCode ^
      configuration.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleConfig &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          moduleId == other.moduleId &&
          key == other.key &&
          sensors == other.sensors &&
          configuration == other.configuration;
}

class NearbyStation {
  final String deviceId;
  final bool busy;

  const NearbyStation({
    required this.deviceId,
    required this.busy,
  });

  @override
  int get hashCode => deviceId.hashCode ^ busy.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyStation &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          busy == other.busy;
}

class NetworkConfig {
  final int index;
  final String ssid;
  final bool preferred;

  const NetworkConfig({
    required this.index,
    required this.ssid,
    required this.preferred,
  });

  @override
  int get hashCode => index.hashCode ^ ssid.hashCode ^ preferred.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkConfig &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          ssid == other.ssid &&
          preferred == other.preferred;
}

@freezed
sealed class PortalError with _$PortalError implements FrbException {
  const factory PortalError.authentication() = PortalError_Authentication;
  const factory PortalError.connecting() = PortalError_Connecting;
  const factory PortalError.other(
    String field0,
  ) = PortalError_Other;
}

class RecordArchive {
  final String deviceId;
  final String generationId;
  final String path;
  final int head;
  final int tail;

  const RecordArchive({
    required this.deviceId,
    required this.generationId,
    required this.path,
    required this.head,
    required this.tail,
  });

  @override
  int get hashCode =>
      deviceId.hashCode ^
      generationId.hashCode ^
      path.hashCode ^
      head.hashCode ^
      tail.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordArchive &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          generationId == other.generationId &&
          path == other.path &&
          head == other.head &&
          tail == other.tail;
}

class Registered {
  final String email;
  final String name;

  const Registered({
    required this.email,
    required this.name,
  });

  @override
  int get hashCode => email.hashCode ^ name.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Registered &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          name == other.name;
}

@freezed
sealed class Schedule with _$Schedule {
  const factory Schedule.every(
    int field0,
  ) = Schedule_Every;
}

class SensorConfig {
  final int number;
  final String key;
  final String fullKey;
  final String calibratedUom;
  final String uncalibratedUom;
  final SensorValue? value;
  final SensorValue? previousValue;

  const SensorConfig({
    required this.number,
    required this.key,
    required this.fullKey,
    required this.calibratedUom,
    required this.uncalibratedUom,
    this.value,
    this.previousValue,
  });

  @override
  int get hashCode =>
      number.hashCode ^
      key.hashCode ^
      fullKey.hashCode ^
      calibratedUom.hashCode ^
      uncalibratedUom.hashCode ^
      value.hashCode ^
      previousValue.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorConfig &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          key == other.key &&
          fullKey == other.fullKey &&
          calibratedUom == other.calibratedUom &&
          uncalibratedUom == other.uncalibratedUom &&
          value == other.value &&
          previousValue == other.previousValue;
}

class SensorValue {
  final UtcDateTime time;
  final double value;
  final double uncalibrated;

  const SensorValue({
    required this.time,
    required this.value,
    required this.uncalibrated,
  });

  @override
  int get hashCode => time.hashCode ^ value.hashCode ^ uncalibrated.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorValue &&
          runtimeType == other.runtimeType &&
          time == other.time &&
          value == other.value &&
          uncalibrated == other.uncalibrated;
}

class SolarInfo {
  final double voltage;

  const SolarInfo({
    required this.voltage,
  });

  @override
  int get hashCode => voltage.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SolarInfo &&
          runtimeType == other.runtimeType &&
          voltage == other.voltage;
}

class StationConfig {
  final String deviceId;
  final String generationId;
  final String name;
  final FirmwareInfo firmware;
  final UtcDateTime lastSeen;
  final StreamInfo meta;
  final StreamInfo data;
  final BatteryInfo battery;
  final SolarInfo solar;
  final List<ModuleConfig> modules;

  const StationConfig({
    required this.deviceId,
    required this.generationId,
    required this.name,
    required this.firmware,
    required this.lastSeen,
    required this.meta,
    required this.data,
    required this.battery,
    required this.solar,
    required this.modules,
  });

  @override
  int get hashCode =>
      deviceId.hashCode ^
      generationId.hashCode ^
      name.hashCode ^
      firmware.hashCode ^
      lastSeen.hashCode ^
      meta.hashCode ^
      data.hashCode ^
      battery.hashCode ^
      solar.hashCode ^
      modules.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StationConfig &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          generationId == other.generationId &&
          name == other.name &&
          firmware == other.firmware &&
          lastSeen == other.lastSeen &&
          meta == other.meta &&
          data == other.data &&
          battery == other.battery &&
          solar == other.solar &&
          modules == other.modules;
}

class StreamInfo {
  final int size;
  final int records;

  const StreamInfo({
    required this.size,
    required this.records,
  });

  @override
  int get hashCode => size.hashCode ^ records.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamInfo &&
          runtimeType == other.runtimeType &&
          size == other.size &&
          records == other.records;
}

class Tokens {
  final String token;
  final TransmissionToken transmission;

  const Tokens({
    required this.token,
    required this.transmission,
  });

  @override
  int get hashCode => token.hashCode ^ transmission.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tokens &&
          runtimeType == other.runtimeType &&
          token == other.token &&
          transmission == other.transmission;
}

class TransferProgress {
  final String deviceId;
  final TransferStatus status;

  const TransferProgress({
    required this.deviceId,
    required this.status,
  });

  @override
  int get hashCode => deviceId.hashCode ^ status.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferProgress &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          status == other.status;
}

@freezed
sealed class TransferStatus with _$TransferStatus {
  const factory TransferStatus.starting() = TransferStatus_Starting;
  const factory TransferStatus.downloading(
    DownloadProgress field0,
  ) = TransferStatus_Downloading;
  const factory TransferStatus.uploading(
    UploadProgress field0,
  ) = TransferStatus_Uploading;
  const factory TransferStatus.processing() = TransferStatus_Processing;
  const factory TransferStatus.completed() = TransferStatus_Completed;
  const factory TransferStatus.failed() = TransferStatus_Failed;
}

class TransmissionConfig {
  final bool enabled;

  const TransmissionConfig({
    required this.enabled,
  });

  @override
  int get hashCode => enabled.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransmissionConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled;
}

class TransmissionToken {
  final String token;
  final String url;

  const TransmissionToken({
    required this.token,
    required this.url,
  });

  @override
  int get hashCode => token.hashCode ^ url.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransmissionToken &&
          runtimeType == other.runtimeType &&
          token == other.token &&
          url == other.url;
}

class UpgradeProgress {
  final String deviceId;
  final int firmwareId;
  final UpgradeStatus status;

  const UpgradeProgress({
    required this.deviceId,
    required this.firmwareId,
    required this.status,
  });

  @override
  int get hashCode => deviceId.hashCode ^ firmwareId.hashCode ^ status.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpgradeProgress &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          firmwareId == other.firmwareId &&
          status == other.status;
}

@freezed
sealed class UpgradeStatus with _$UpgradeStatus {
  const factory UpgradeStatus.starting() = UpgradeStatus_Starting;
  const factory UpgradeStatus.uploading(
    UploadProgress field0,
  ) = UpgradeStatus_Uploading;
  const factory UpgradeStatus.restarting() = UpgradeStatus_Restarting;
  const factory UpgradeStatus.completed() = UpgradeStatus_Completed;
  const factory UpgradeStatus.failed() = UpgradeStatus_Failed;
}

class UploadProgress {
  final int bytesUploaded;
  final int totalBytes;

  const UploadProgress({
    required this.bytesUploaded,
    required this.totalBytes,
  });

  @override
  int get hashCode => bytesUploaded.hashCode ^ totalBytes.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadProgress &&
          runtimeType == other.runtimeType &&
          bytesUploaded == other.bytesUploaded &&
          totalBytes == other.totalBytes;
}

class UtcDateTime {
  final int field0;

  const UtcDateTime({
    required this.field0,
  });

  @override
  int get hashCode => field0.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UtcDateTime &&
          runtimeType == other.runtimeType &&
          field0 == other.field0;
}

class WifiNetworkConfig {
  final int index;
  final String? ssid;
  final String? password;
  final bool preferred;
  final bool keeping;

  const WifiNetworkConfig({
    required this.index,
    this.ssid,
    this.password,
    required this.preferred,
    required this.keeping,
  });

  @override
  int get hashCode =>
      index.hashCode ^
      ssid.hashCode ^
      password.hashCode ^
      preferred.hashCode ^
      keeping.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WifiNetworkConfig &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          ssid == other.ssid &&
          password == other.password &&
          preferred == other.preferred &&
          keeping == other.keeping;
}

class WifiNetworksConfig {
  final List<WifiNetworkConfig> networks;

  const WifiNetworksConfig({
    required this.networks,
  });

  @override
  int get hashCode => networks.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WifiNetworksConfig &&
          runtimeType == other.runtimeType &&
          networks == other.networks;
}

class WifiTransmissionConfig {
  final Tokens? tokens;
  final Schedule? schedule;

  const WifiTransmissionConfig({
    this.tokens,
    this.schedule,
  });

  @override
  int get hashCode => tokens.hashCode ^ schedule.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WifiTransmissionConfig &&
          runtimeType == other.runtimeType &&
          tokens == other.tokens &&
          schedule == other.schedule;
}