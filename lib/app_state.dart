import 'dart:convert';
import 'dart:math';
import 'package:fk/meta.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:fk/gen/api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:exponential_back_off/exponential_back_off.dart';
import 'package:protobuf/protobuf.dart';
import 'package:uuid/uuid.dart';
import 'package:fk_data_protocol/fk-data.pb.dart' as proto;

import 'diagnostics.dart';
import 'dispatcher.dart';

const uuid = Uuid();

class SyncStatus {
  int uploaded;
  int downloaded;

  SyncStatus({required this.uploaded, required this.downloaded});
}

class StationModel {
  final String deviceId;
  StationConfig? config;
  EphemeralConfig? ephemeral;
  SyncingProgress? syncing;
  FirmwareInfo? get firmware => config?.firmware;
  bool connected;
  SyncStatus? syncStatus;

  StationModel({
    required this.deviceId,
    this.config,
    this.connected = false,
  });

  void updateName(String value) {
    // config?.name = value;
  }
}

class UpdatePortal {
  final PortalAccounts portalAccounts;
  final Map<String, ExponentialBackOff> _active = {};
  final Map<String, AddOrUpdatePortalStation> _updates = {};

  UpdatePortal(
      {required this.portalAccounts, required AppEventDispatcher dispatcher}) {
    dispatcher.addListener<DomainMessage_StationRefreshed>((refreshed) async {
      final deviceId = refreshed.field0.deviceId;

      // Always update what we'll be sending to the server. So when we do succeed it's the fresh data.
      _updates[deviceId] = AddOrUpdatePortalStation(
          name: refreshed.field0.name,
          deviceId: deviceId,
          locationName: "",
          statusPb: refreshed.field2);

      await tick();
    });
  }

  Future<bool> updateAll(UnmodifiableListView<StationModel> stations) async {
    for (final station in stations) {
      final config = station.config;
      if (config != null && config.pb != null) {
        _updates[station.deviceId] = AddOrUpdatePortalStation(
            name: config.name,
            deviceId: station.deviceId,
            locationName: "",
            statusPb: hex.encode(config.pb!));
      } else {
        Loggers.state.w("${station.deviceId} no config $config");
      }
    }

    await tick();

    return true;
  }

  Future<bool> tick() async {
    for (final kv in _updates.entries) {
      final deviceId = kv.key;
      final update = kv.value;
      final name = update.name;

      if (_active.containsKey(deviceId) &&
          _active[deviceId]!.isProcessRunning()) {
        Loggers.state.i("$deviceId $name portal update active");
        continue;
      } else {
        Loggers.state.i(
            "$deviceId $name portal update (${update.statusPb.length} bytes)");
      }

      final account = portalAccounts.getAccountForDevice(deviceId);
      final tokens = account?.tokens;
      if (account != null && tokens != null) {
        final backOff = ExponentialBackOff(
          interval: const Duration(milliseconds: 2000),
          maxDelay: const Duration(seconds: 60 * 5),
          maxAttempts: 10,
          maxRandomizationFactor: 0.0,
        );

        _active[deviceId] = backOff;

        final update = await backOff.start(
            () async {
              final idIfOk = await addOrUpdateStationInPortal(
                  tokens: tokens, station: _updates[deviceId]!);
              portalAccounts.markValid(account);
              if (idIfOk == null) {
                Loggers.state.w("$deviceId permissions-conflict");
              } else {
                Loggers.state.v("$deviceId refreshed portal-id=$idIfOk");
              }
            },
            retryIf: (e) => e is PortalError_Connecting,
            onRetry: (e) {
              if (e is PortalError_Connecting) {
                portalAccounts.markConnectivyIssue(account);
              }
            });

        if (update.isLeft()) {
          final error = update.getLeftValue();
          if (error is PortalError_Authentication) {
            Loggers.main.e("portal: auth $e");
            await portalAccounts.validateAccount(account);
          } else {
            Loggers.state.e("portal: $error");
          }
        }
      } else {
        Loggers.state.w("$deviceId need-auth");
      }
    }

    Loggers.state.i("portal: tick");

    return true;
  }
}

class AuthenticationStatus extends ChangeNotifier {
  AuthenticationStatus(
      PortalStateMachine portalState, PortalAccounts accounts) {
    portalState.addListener(() {
      if (portalState.state == PortalState.loaded) {
        accounts.validate();
      }
      if (portalState.state == PortalState.validated) {
        accounts.refreshFirmware();
      }
    });
  }
}

class KnownStationsModel extends ChangeNotifier {
  final Map<String, StationModel> _stations = {};

  UnmodifiableListView<StationModel> get stations =>
      UnmodifiableListView(_stations.values);

  KnownStationsModel(AppEventDispatcher dispatcher) {
    dispatcher.addListener<DomainMessage_NearbyStations>((nearby) {
      final byDeviceId = {};
      for (final station in nearby.field0) {
        findOrCreate(station.deviceId);
        byDeviceId[station.deviceId] = station;
      }
      for (var station in _stations.values) {
        final nearby = byDeviceId[station.deviceId];
        station.connected = nearby != null;
      }
      notifyListeners();
    });

    dispatcher.addListener<DomainMessage_StationRefreshed>((refreshed) {
      final station = findOrCreate(refreshed.field0.deviceId);
      station.config = refreshed.field0;
      station.ephemeral = refreshed.field1;
      station.connected = true;
      Loggers.state.i(
          "${station.deviceId} ${station.config?.name} udp=${station.ephemeral?.capabilities.udp} fw=${station.config?.firmware.label}/${station.config?.firmware.time}");
      notifyListeners();
    });

    dispatcher.addListener<DomainMessage_DownloadProgress>((transferProgress) {
      applyTransferProgress(transferProgress.field0);
    });

    dispatcher.addListener<DomainMessage_UploadProgress>((transferProgress) {
      applyTransferProgress(transferProgress.field0);
    });

    dispatcher.addListener<DomainMessage_RecordArchives>((archives) {
      final byDeviceId = archives.field0.groupListsBy((a) => a.deviceId);
      for (final entry in byDeviceId.entries) {
        final uploaded = entry.value
            .where((e) => e.uploaded != null)
            .map((e) => e.tail - e.head)
            .sum;
        final downloaded = entry.value.map((e) => e.tail - e.head).sum;
        findOrCreate(entry.key).syncStatus =
            SyncStatus(uploaded: uploaded, downloaded: downloaded);
      }
    });

    _load();
  }

  void applyTransferProgress(TransferProgress transferProgress) {
    final deviceId = transferProgress.deviceId;
    final station = findOrCreate(deviceId);
    final status = transferProgress.status;
    if (status is TransferStatus_Starting) {
      station.syncing =
          SyncingProgress(download: null, upload: null, failed: false);
    }
    if (status is TransferStatus_Downloading) {
      station.syncing = SyncingProgress(
          download: DownloadOperation(status: status),
          upload: null,
          failed: false);
    }
    if (status is TransferStatus_Uploading) {
      station.syncing = SyncingProgress(
          download: null,
          upload: UploadOperation(status: status),
          failed: false);
    }
    if (status is TransferStatus_Completed) {
      station.syncing = null;
    }
    if (status is TransferStatus_Failed) {
      station.syncing =
          SyncingProgress(download: null, upload: null, failed: true);
    }

    station.connected = true;

    notifyListeners();
  }

  void _load() async {
    final stations = await getMyStations();
    Loggers.state.i("stations: ${stations.length} stations");
    for (var station in stations) {
      findOrCreate(station.deviceId).config = station;
    }
    Loggers.state.i("stations: loaded");
    notifyListeners();
  }

  StationModel? find(String deviceId) {
    return _stations[deviceId];
  }

  StationModel findOrCreate(String deviceId) {
    _stations.putIfAbsent(deviceId, () => StationModel(deviceId: deviceId));
    return _stations[deviceId]!;
  }

  Future<void> startDownloading({required String deviceId, int? first}) async {
    final station = find(deviceId);
    if (station == null) {
      Loggers.state.w("$deviceId station missing");
      return;
    }

    final syncing = station.syncing;
    if (syncing != null) {
      if (!syncing.failed) {
        Loggers.state.w("$deviceId already syncing");
        return;
      }
    }

    final progress = await startDownload(deviceId: deviceId, first: first);
    applyTransferProgress(progress);
  }

  Future<void> startUploading(
      {required String deviceId,
      required Tokens tokens,
      required List<RecordArchive> files}) async {
    final station = find(deviceId);
    if (station == null) {
      Loggers.state.w("$deviceId station missing");
      return;
    }

    if (station.syncing != null) {
      Loggers.state.w("$deviceId already syncing");
      return;
    }

    final progress =
        await startUpload(deviceId: deviceId, tokens: tokens, files: files);
    applyTransferProgress(progress);
  }

  ModuleAndStation? findModule(ModuleIdentity moduleIdentity) {
    for (final station in stations) {
      final config = station.config;
      if (config != null) {
        for (final module in config.modules) {
          if (module.identity == moduleIdentity) {
            return ModuleAndStation(config, module);
          }
        }
      }
    }
    return null;
  }
}

class ModuleAndStation {
  final StationConfig station;
  final ModuleConfig module;

  ModuleAndStation(this.station, this.module);
}

const String globalOperationKey = "Global";

class StationOperations extends ChangeNotifier {
  final Map<String, List<Operation>> _active = {};

  StationOperations({required AppEventDispatcher dispatcher}) {
    dispatcher.addListener<DomainMessage_UpgradeProgress>((upgradeProgress) {
      getOrCreate<UpgradeOperation>(
              () => UpgradeOperation(upgradeProgress.field0.firmwareId),
              upgradeProgress.field0.deviceId)
          .update(upgradeProgress);
      notifyListeners();
    });
    dispatcher.addListener<DomainMessage_DownloadProgress>((transferProgress) {
      getOrCreate<TransferOperation>(
              DownloadOperation.new, transferProgress.field0.deviceId)
          .update(transferProgress);
      notifyListeners();
    });
    dispatcher.addListener<DomainMessage_UploadProgress>((transferProgress) {
      getOrCreate<TransferOperation>(
              UploadOperation.new, transferProgress.field0.deviceId)
          .update(transferProgress);
      notifyListeners();
    });
    dispatcher
        .addListener<DomainMessage_FirmwareDownloadStatus>((downloadProgress) {
      getOrCreate<FirmwareDownloadOperation>(
              FirmwareDownloadOperation.new, globalOperationKey)
          .update(downloadProgress);
      notifyListeners();
    });
  }

  T getOrCreate<T extends Operation>(T Function() factory, String deviceId) {
    if (!_active.containsKey(deviceId)) {
      _active[deviceId] = List.empty(growable: true);
    }
    for (final operation in _active[deviceId] ?? List.empty()) {
      if (operation is T) {
        return operation;
      }
    }
    Loggers.state.i("Creating $T");
    final operation = factory();
    _active[deviceId]!.add(operation);
    return operation;
  }

  List<T> getAll<T extends Operation>(String deviceId) {
    final List<Operation> station = _active[deviceId] ?? List.empty();
    return station.whereType<T>().toList();
  }

  List<T> getBusy<T extends Operation>(String deviceId) {
    return getAll<T>(deviceId).where((op) => !op.done).toList();
  }

  bool isBusy(String deviceId) {
    return getBusy<Operation>(deviceId).isNotEmpty;
  }

  void dismiss(Operation operation) {
    operation.dismiss();
    notifyListeners();
  }
}

abstract class Operation extends ChangeNotifier {
  bool dismissed = false;

  void update(DomainMessage message);

  void dismiss() {
    dismissed = true;
  }

  void undismiss() {
    dismissed = false;
  }

  bool get done;

  bool get busy => !done;
}

abstract class TransferOperation extends Operation {
  TransferStatus status;

  TransferOperation({this.status = const TransferStatus.starting()});

  @override
  void update(DomainMessage message) {
    if (message is DomainMessage_DownloadProgress) {
      status = message.field0.status;
      notifyListeners();
    }
    if (message is DomainMessage_UploadProgress) {
      status = message.field0.status;
      notifyListeners();
    }
  }

  @override
  bool get done =>
      status is TransferStatus_Completed || status is TransferStatus_Failed;

  double get completed {
    final status = this.status;
    if (status is TransferStatus_Uploading) {
      return status.field0.bytesUploaded / status.field0.totalBytes;
    }
    if (status is TransferStatus_Downloading) {
      return status.field0.received / status.field0.total;
    }
    if (status is TransferStatus_Completed) {
      return 0.0;
    }
    return 0.0;
  }
}

class DownloadOperation extends TransferOperation {
  DownloadOperation({super.status = const TransferStatus.starting()});

  TransferStatus_Downloading? get _downloading =>
      status as TransferStatus_Downloading;

  int get received => _downloading?.field0.received ?? 0;
  int get total => _downloading?.field0.total ?? 0;
  int get started => _downloading?.field0.started ?? 0;
}

class UploadOperation extends TransferOperation {
  UploadOperation({super.status = const TransferStatus.starting()});
}

class FirmwareComparison {
  final String label;
  final DateTime time;
  final DateTime otherTime;
  final bool newer;

  FirmwareComparison(
      {required this.label,
      required this.time,
      required this.otherTime,
      required this.newer});

  factory FirmwareComparison.compare(
      LocalFirmware local, FirmwareInfo station) {
    final other = DateTime.fromMillisecondsSinceEpoch(station.time * 1000);
    final time = DateTime.fromMillisecondsSinceEpoch(local.time);
    return FirmwareComparison(
        label: local.label,
        time: time,
        otherTime: other,
        newer: time.isAfter(other));
  }
}

class UpgradeOperation extends Operation {
  int firmwareId;
  UpgradeStatus status = const UpgradeStatus.starting();
  UpgradeError? error;

  UpgradeOperation(this.firmwareId);

  @override
  void update(DomainMessage message) {
    if (message is DomainMessage_UpgradeProgress) {
      final upgradeStatus = message.field0.status;
      if (upgradeStatus is UpgradeStatus_Failed) {
        error = upgradeStatus.field0;
        Loggers.state.i("upgrade: $error");
      } else {
        error = null;
        Loggers.state.i("upgrade: $upgradeStatus");
      }
      firmwareId = message.field0.firmwareId;
      status = upgradeStatus;
      undismiss();
      notifyListeners();
    }
  }

  @override
  bool get done => dismissed;

  @override
  bool get busy => !(status is UpgradeStatus_Completed ||
      status is UpgradeStatus_Failed ||
      status is UpgradeStatus_ReconnectTimeout);
}

class FirmwareDownloadOperation extends Operation {
  FirmwareDownloadStatus status = const FirmwareDownloadStatus.checking();

  @override
  void update(DomainMessage message) {
    if (message is DomainMessage_FirmwareDownloadStatus) {
      status = message.field0;
      notifyListeners();
    }
  }

  @override
  bool get done =>
      status is FirmwareDownloadStatus_Completed ||
      status is FirmwareDownloadStatus_Failed;
}

class LocalFirmwareBranchInfo {
  final String branch;
  final String? version;
  final String? sha;

  LocalFirmwareBranchInfo(
      {required this.version, required this.branch, required this.sha});

  static LocalFirmwareBranchInfo? parse(String label) {
    if (label.length >= 8) {
      final version = label.split('-').first;
      final lastDash = label.lastIndexOf("-");
      if (lastDash > 0) {
        final sha = label.substring(lastDash + 1);
        final RegExp hex = RegExp("[0..9abcdef]+");
        if (hex.hasMatch(sha)) {
          final branch = label.substring(version.length + 1, lastDash);
          final maybeDot = branch.indexOf(".");
          if (maybeDot > 0) {
            return LocalFirmwareBranchInfo(
                version: version,
                branch: branch.substring(0, maybeDot),
                sha: sha);
          } else {
            return LocalFirmwareBranchInfo(
                version: version, branch: branch, sha: sha);
          }
        }
      }
    }
    return LocalFirmwareBranchInfo(version: null, branch: label, sha: null);
  }

  @override
  String toString() {
    return "BranchInfo($version, $branch, $sha)";
  }
}

class AvailableFirmwareModel extends ChangeNotifier {
  final List<LocalFirmware> _firmware = [];

  UnmodifiableListView<LocalFirmware> get firmware =>
      UnmodifiableListView(_firmware);

  AvailableFirmwareModel({required AppEventDispatcher dispatcher}) {
    dispatcher
        .addListener<DomainMessage_AvailableFirmware>((availableFirmware) {
      _firmware.clear();
      _firmware.addAll(availableFirmware.field0);
      notifyListeners();
    });
  }

  Future<void> upgrade(String deviceId, LocalFirmware firmware) async {
    await upgradeStation(deviceId: deviceId, firmware: firmware, swap: true);
  }
}

class WifiNetwork {
  String? ssid;
  String? password;
  bool preferred;

  WifiNetwork(
      {required this.ssid, required this.password, required this.preferred});
}

class Event {
  final proto.Event data;

  DateTime get time => DateTime.fromMillisecondsSinceEpoch(data.time * 1000);

  Event({required this.data});

  static Event from(proto.Event e) {
    if (e.system == proto.EventSystem.EVENT_SYSTEM_LORA) {
      return LoraEvent(data: e);
    }
    if (e.system == proto.EventSystem.EVENT_SYSTEM_RESTART) {
      return RestartEvent(data: e);
    }
    return UnknownEvent(data: e);
  }
}

class UnknownEvent extends Event {
  UnknownEvent({required super.data});
}

class RestartEvent extends Event {
  /*
  enum ResetReason {
      FK_RESET_REASON_POR    = 1,
      FK_RESET_REASON_BOD12  = 2,
      FK_RESET_REASON_BOD33  = 4,
      FK_RESET_REASON_NVM    = 8,
      FK_RESET_REASON_EXT    = 16,
      FK_RESET_REASON_WDT    = 32,
      FK_RESET_REASON_SYST   = 64,
      FK_RESET_REASON_BACKUP = 128
  };
  */

  String get reason {
    if (data.code == 1) return "POR";
    if (data.code == 2) return "BOD12";
    if (data.code == 4) return "BOD33";
    if (data.code == 8) return "NVM";
    if (data.code == 16) return "EXT";
    if (data.code == 32) return "WDT";
    if (data.code == 64) return "SYST";
    if (data.code == 128) return "BACKUP";
    return "Unknown";
  }

  RestartEvent({required super.data});
}

enum LoraCode {
  joinOk,
  joinFail,
  confirmedSend,
  unknown,
}

class LoraEvent extends Event {
  LoraCode get code {
    if (data.code == 1) return LoraCode.joinOk;
    if (data.code == 2) return LoraCode.joinFail;
    if (data.code == 3) return LoraCode.confirmedSend;
    return LoraCode.unknown;
  }

  LoraEvent({required super.data});
}

class StationConfiguration extends ChangeNotifier {
  final KnownStationsModel knownStations;
  final PortalAccounts portalAccounts;
  final String deviceId;

  StationModel get config => knownStations.find(deviceId)!;

  String get name => config.config!.name;

  List<NetworkConfig> get networks =>
      config.ephemeral?.networks ?? List.empty();

  bool get isAutomaticUploadEnabled =>
      config.ephemeral?.transmission?.enabled ?? false;

  LoraConfig? get loraConfig => config.ephemeral?.lora;

  StationConfiguration(
      {required this.knownStations,
      required this.portalAccounts,
      required this.deviceId}) {
    knownStations.addListener(() {
      notifyListeners();
    });
  }

  List<Event> events() {
    final Uint8List? bytes = config.ephemeral?.events;
    if (bytes == null || bytes.isEmpty) {
      return List.empty();
    }
    try {
      final CodedBufferReader reader = CodedBufferReader(bytes);
      final List<int> delimited = reader.readBytes();
      try {
        final proto.DataRecord record = proto.DataRecord.fromBuffer(delimited);
        Loggers.state.i("Events $record");
        return record.events.map((e) => Event.from(e)).toList();
      } catch (e) {
        Loggers.state.w("Error reading events: $e");
        Loggers.state.w("$bytes (${bytes.length})");
        Loggers.state.i("$delimited (${delimited.length})");
        return List.empty();
      }
    } catch (e) {
      Loggers.state.w("Error reading events: $e");
      Loggers.state.w("$bytes (${bytes.length})");
      return List.empty();
    }
  }

  Future<void> addNetwork(
      List<NetworkConfig> existing, WifiNetwork network) async {
    final int keeping = existing.isEmpty ? 1 : 0;
    final List<WifiNetworkConfig> networks =
        List<int>.generate(2, (i) => i).map((index) {
      if (keeping == index) {
        return WifiNetworkConfig(index: index, keeping: true, preferred: false);
      } else {
        return WifiNetworkConfig(
            index: index,
            keeping: false,
            preferred: false,
            ssid: network.ssid!,
            password: network.password!);
      }
    }).toList();

    await configureWifiNetworks(
        deviceId: deviceId, config: WifiNetworksConfig(networks: networks));
  }

  Future<void> removeNetwork(NetworkConfig network) async {
    final List<WifiNetworkConfig> networks =
        List<int>.generate(2, (i) => i).map((index) {
      if (network.index == index) {
        return WifiNetworkConfig(
            index: index,
            keeping: false,
            preferred: false,
            ssid: "",
            password: "");
      } else {
        return WifiNetworkConfig(index: index, keeping: true, preferred: false);
      }
    }).toList();

    await configureWifiNetworks(
        deviceId: deviceId, config: WifiNetworksConfig(networks: networks));
  }

  bool canEnableWifiUploading() {
    final account = portalAccounts.getAccountForDevice(deviceId);
    return account != null;
  }

  Future<void> enableWifiUploading() async {
    final account = portalAccounts.getAccountForDevice(deviceId);
    if (account == null) {
      Loggers.state.i(
          "No account for device $deviceId (hasAny: ${portalAccounts.hasAnyTokens()})");
      return;
    }

    await configureWifiTransmission(
        deviceId: deviceId,
        config: WifiTransmissionConfig(
            tokens: account.tokens, schedule: const Schedule_Every(10 * 60)));
  }

  Future<void> disableWifiUploading() async {
    await configureWifiTransmission(
        deviceId: deviceId,
        config: const WifiTransmissionConfig(tokens: null, schedule: null));
  }

  Future<void> configureLora(LoraTransmissionConfig config) async {
    await configureLoraTransmission(deviceId: deviceId, config: config);
  }

  Future<void> verifyLora() async {
    await verifyLoraTransmission(deviceId: deviceId);
  }

  Future<void> deploy(DeployConfig config) async {
    await configureDeploy(deviceId: deviceId, config: config);
  }
}

abstract class Task {
  final String key_ = uuid.v1();

  String get key => key_;

  bool isFor(String deviceId) {
    return false;
  }
}

abstract class TaskFactory<M> extends ChangeNotifier {
  final List<M> _tasks = List.empty(growable: true);

  List<M> get tasks => List.unmodifiable(_tasks);

  List<T> getAll<T extends Task>() {
    return tasks.whereType<T>().toList();
  }
}

class DeployTaskFactory extends TaskFactory<DeployTask> {
  final KnownStationsModel knownStations;

  DeployTaskFactory({required this.knownStations}) {
    knownStations.addListener(() {
      _tasks.clear();
      _tasks.addAll(create());
      notifyListeners();
    });
  }

  List<DeployTask> create() {
    final List<DeployTask> tasks = List.empty(growable: true);
    for (final station in knownStations.stations) {
      if (station.ephemeral != null && station.ephemeral?.deployment == null) {
        tasks.add(DeployTask(station: station));
      }
    }
    return tasks;
  }
}

class DeployTask extends Task {
  final StationModel station;

  DeployTask({required this.station});

  @override
  bool isFor(String deviceId) {
    return station.deviceId == deviceId;
  }
}

class UpgradeTaskFactory extends TaskFactory<UpgradeTask> {
  final AvailableFirmwareModel availableFirmware;
  final KnownStationsModel knownStations;

  UpgradeTaskFactory(
      {required this.availableFirmware, required this.knownStations}) {
    listener() {
      _tasks.clear();
      _tasks.addAll(create());
      notifyListeners();
    }

    availableFirmware.addListener(listener);
    knownStations.addListener(listener);
  }

  List<UpgradeTask> create() {
    final List<UpgradeTask> tasks = List.empty(growable: true);
    for (final station in knownStations.stations) {
      final firmware = station.firmware;
      if (firmware != null) {
        for (final local in availableFirmware.firmware) {
          final comparison = FirmwareComparison.compare(local, firmware);
          if (comparison.newer) {
            Loggers.state.i(
                "UpgradeTask ${station.config?.name} ${local.label} ${comparison.label}");
            tasks.add(UpgradeTask(station: station, comparison: comparison));
            break;
          }
        }
      }
    }
    return tasks;
  }
}

class UpgradeTask extends Task {
  final StationModel station;
  final FirmwareComparison comparison;

  UpgradeTask({required this.station, required this.comparison});

  @override
  bool isFor(String deviceId) {
    return station.deviceId == deviceId;
  }
}

class DownloadTaskFactory extends TaskFactory<DownloadTask> {
  List<NearbyStation> _nearby = List.empty();
  List<RecordArchive> _archives = List.empty();
  final Map<String, int> _records = {};
  final Map<String, String> _generations = {};

  DownloadTaskFactory(
      {required KnownStationsModel knownStations,
      required AppEventDispatcher dispatcher}) {
    dispatcher.addListener<DomainMessage_StationRefreshed>((refreshed) {
      _records[refreshed.field0.deviceId] = refreshed.field0.data.records;
      _generations[refreshed.field0.deviceId] = refreshed.field0.generationId;
      _tasks.clear();
      _tasks.addAll(create());
      notifyListeners();
    });

    dispatcher.addListener<DomainMessage_NearbyStations>((nearby) {
      _nearby = nearby.field0;
      _tasks.clear();
      _tasks.addAll(create());
      notifyListeners();
    });

    dispatcher.addListener<DomainMessage_RecordArchives>((archives) {
      _archives = archives.field0;
      _tasks.clear();
      _tasks.addAll(create());
      notifyListeners();
    });
  }

  List<DownloadTask> create() {
    final List<DownloadTask> tasks = List.empty(growable: true);
    final archivesById = _archives.groupListsBy((a) => a.deviceId);
    for (final nearby in _nearby) {
      final int? total = _records[nearby.deviceId];
      if (total != null) {
        if (_generations.containsKey(nearby.deviceId)) {
          final String generationId = _generations[nearby.deviceId]!;

          // Find already downloaded archives.
          final Iterable<RecordArchive>? archives =
              archivesById[nearby.deviceId]
                  ?.where((archive) => archive.generationId == generationId);

          if (archives != null && archives.isNotEmpty) {
            // Some records have already been downloaded.
            final int first =
                archives.map((archive) => archive.tail).reduce(max);
            tasks.add(DownloadTask(
                deviceId: nearby.deviceId, total: total, first: first));
          } else {
            // Nothing has been downloaded yet.
            Loggers.state.w("${nearby.deviceId} no archives");
            tasks.add(DownloadTask(
                deviceId: nearby.deviceId, total: total, first: 0));
          }
        } else {
          Loggers.state.w("${nearby.deviceId} no generation");
        }
      } else {
        Loggers.state.w("${nearby.deviceId} no total records");
      }
    }
    return tasks;
  }
}

class DownloadTask extends Task {
  final String deviceId;
  final int total;
  final int? first;

  bool get hasReadings {
    return first != null && total - first! > 0;
  }

  DownloadTask({required this.deviceId, required this.total, this.first});

  @override
  String toString() {
    return "DownloadTask($deviceId, $first, $total)";
  }

  @override
  bool isFor(String deviceId) {
    return this.deviceId == deviceId;
  }
}

class UploadTaskFactory extends TaskFactory<UploadTask> {
  final PortalAccounts portalAccounts;
  List<RecordArchive> _archives = List.empty();

  UploadTaskFactory(
      {required this.portalAccounts, required AppEventDispatcher dispatcher}) {
    portalAccounts.addListener(() {
      _tasks.clear();
      _tasks.addAll(create());
      notifyListeners();
    });

    dispatcher.addListener<DomainMessage_RecordArchives>((archives) {
      _archives = archives.field0;
      _tasks.clear();
      _tasks.addAll(create());
      notifyListeners();
    });
  }

  List<UploadTask> create() {
    final List<UploadTask> tasks = List.empty(growable: true);
    final pending = _archives
        .where((a) => a.uploaded == null)
        .groupListsBy((a) => a.deviceId);
    for (final entry in pending.entries) {
      final account = portalAccounts.getAccountForDevice(entry.key);
      // Always create an UploadTask, regardless of authentication status.
      if (account == null || account.tokens == null) {
        // User needs to login.
        tasks.add(UploadTask(
            deviceId: entry.key,
            files: entry.value,
            tokens: null,
            problem: UploadProblem.authentication));
      } else {
        if (account.validity == Validity.connectivity) {
          // User *may* need to login, or could just have connectivity issues.
          tasks.add(UploadTask(
              deviceId: entry.key,
              files: entry.value,
              tokens: account.tokens,
              problem: UploadProblem.connectivity));
        } else {
          // User is good to try uploading.
          tasks.add(UploadTask(
              deviceId: entry.key,
              files: entry.value,
              tokens: account.tokens,
              problem: UploadProblem.none));
        }
      }
    }
    return tasks;
  }
}

enum UploadProblem {
  none,
  authentication,
  connectivity,
}

class UploadTask extends Task {
  final String deviceId;
  final List<RecordArchive> files;
  final Tokens? tokens;
  final UploadProblem problem;

  UploadTask(
      {required this.deviceId,
      required this.files,
      required this.tokens,
      required this.problem});

  bool get allowed => problem == UploadProblem.none;

  int get total => files.map((e) => e.tail - e.head).sum;

  @override
  String toString() {
    return "UploadTask($deviceId, ${files.length} files, $problem)";
  }

  @override
  bool isFor(String deviceId) {
    return this.deviceId == deviceId;
  }
}

class LoginTask extends Task {
  LoginTask();
}

class LoginTaskFactory extends TaskFactory<LoginTask> {
  final PortalAccounts portalAccounts;

  LoginTaskFactory({required this.portalAccounts}) {
    portalAccounts.addListener(() {
      _tasks.clear();
      if (!portalAccounts.hasAnyTokens()) {
        _tasks.add(LoginTask());
      }
      notifyListeners();
    });
  }
}

class TasksModel extends ChangeNotifier {
  final List<TaskFactory> factories = List.empty(growable: true);

  TasksModel(
      {required AvailableFirmwareModel availableFirmware,
      required KnownStationsModel knownStations,
      required PortalAccounts portalAccounts,
      required AppEventDispatcher dispatcher}) {
    factories.add(LoginTaskFactory(portalAccounts: portalAccounts));
    factories.add(DeployTaskFactory(knownStations: knownStations));
    factories.add(UploadTaskFactory(
        portalAccounts: portalAccounts, dispatcher: dispatcher));
    factories.add(DownloadTaskFactory(
        knownStations: knownStations, dispatcher: dispatcher));
    factories.add(UpgradeTaskFactory(
        availableFirmware: availableFirmware, knownStations: knownStations));
    for (final TaskFactory f in factories) {
      f.addListener(notifyListeners);
    }
  }

  List<T> getAll<T extends Task>() {
    return factories.map((f) => f.getAll<T>()).flattened.toList();
  }

  List<T> getAllFor<T extends Task>(String deviceId) {
    return factories
        .map((f) => f.getAll<T>())
        .flattened
        .where((task) => task.isFor(deviceId))
        .toList();
  }

  T? getMaybeOne<T extends Task>(String deviceId) {
    final all = getAllFor<T>(deviceId);
    if (all.length > 1) {
      throw ArgumentError("Excepted one and only one Task");
    }
    if (all.length == 1) {
      return all[0];
    }
    return null;
  }
}

class AppState {
  final AppEventDispatcher dispatcher;
  final AvailableFirmwareModel firmware;
  final KnownStationsModel knownStations;
  final StationOperations stationOperations;
  final ModuleConfigurations moduleConfigurations;
  final AuthenticationStatus authenticationStatus;
  final PortalAccounts portalAccounts;
  final TasksModel tasks;
  final UpdatePortal updatePortal;

  AppState._(
      this.dispatcher,
      this.knownStations,
      this.moduleConfigurations,
      this.authenticationStatus,
      this.portalAccounts,
      this.firmware,
      this.stationOperations,
      this.tasks,
      this.updatePortal);

  static AppState build(AppEventDispatcher dispatcher) {
    final stationOperations = StationOperations(dispatcher: dispatcher);
    final firmware = AvailableFirmwareModel(dispatcher: dispatcher);
    final knownStations = KnownStationsModel(dispatcher);
    final moduleConfigurations =
        ModuleConfigurations(knownStations: knownStations);
    final PortalStateMachine portalState = PortalStateMachine();
    final portalAccounts = PortalAccounts(portalState: portalState);
    final authenticationStatus =
        AuthenticationStatus(portalState, portalAccounts);
    final tasks = TasksModel(
      availableFirmware: firmware,
      knownStations: knownStations,
      portalAccounts: portalAccounts,
      dispatcher: dispatcher,
    );
    final updatePortal =
        UpdatePortal(portalAccounts: portalAccounts, dispatcher: dispatcher);
    return AppState._(
      dispatcher,
      knownStations,
      moduleConfigurations,
      authenticationStatus,
      portalAccounts,
      firmware,
      stationOperations,
      tasks,
      updatePortal,
    );
  }

  late final AppLifecycleListener _listener;
  DateTime? _periodicRan;

  AppState start() {
    _everyFiveMinutes();

    _listener = AppLifecycleListener(
      onStateChange: (AppLifecycleState state) {
        Loggers.state.i("lifecycle: $state");

        if (state == AppLifecycleState.resumed) {
          if (_periodicRan != null &&
              DateTime.now().difference(_periodicRan!).inSeconds < 30) {
            Loggers.state.i("periodic: $_periodicRan");
          } else {
            _periodic();
          }
        }
      },
    );

    return this;
  }

  AppState stop() {
    _listener.dispose();

    return this;
  }

  Future<void> _periodic() async {
    _periodicRan = DateTime.now();

    await portalAccounts.refreshFirmware();

    await updatePortal.updateAll(knownStations.stations);
  }

  Future<void> _everyFiveMinutes() async {
    while (true) {
      await Future.delayed(const Duration(minutes: 5));

      await _periodic();
    }
  }

  StationConfiguration configurationFor(deviceId) {
    return StationConfiguration(
        knownStations: knownStations,
        portalAccounts: portalAccounts,
        deviceId: deviceId);
  }
}

class AppEnv {
  AppEventDispatcher dispatcher;
  ValueNotifier<AppState?> _appState;

  AppEnv._(this.dispatcher, {AppState? appState})
      : _appState = ValueNotifier(appState);

  AppEnv.appState(AppEventDispatcher dispatcher)
      : this._(
          dispatcher,
          appState: AppState.build(dispatcher).start(),
        );

  ValueListenable<AppState?> get appState => _appState;
}

class SyncingProgress extends ChangeNotifier {
  final DownloadOperation? download;
  final UploadOperation? upload;
  final bool failed;

  double? get completed {
    if (download != null) {
      return download?.completed ?? 0;
    }
    if (upload != null) {
      return upload?.completed ?? 0;
    }
    return null;
  }

  SyncingProgress({this.download, this.upload, required this.failed});
}

extension CompletedProperty on UploadProgress {
  double get completed {
    return bytesUploaded / totalBytes;
  }
}

class ModuleIdentity {
  final String moduleId;

  ModuleIdentity({required this.moduleId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModuleIdentity && other.moduleId == moduleId;
  }

  @override
  int get hashCode => moduleId.hashCode;

  @override
  String toString() {
    return "ModuleIdentity($moduleId)";
  }
}

extension Identity on ModuleConfig {
  ModuleIdentity get identity => ModuleIdentity(moduleId: moduleId);
}

extension PortalTransmissionTokens on TransmissionToken {
  Map<String, dynamic> toJson() => {
        'token': token,
        'url': url,
      };

  static TransmissionToken fromJson(Map<String, dynamic> data) {
    final token = data['token'] as String;
    final url = data['url'] as String;
    return TransmissionToken(token: token, url: url);
  }
}

extension PortalTokens on Tokens {
  Map<String, dynamic> toJson() => {
        'token': token,
        'transmission': transmission.toJson(),
      };

  static Tokens fromJson(Map<String, dynamic> data) {
    final token = data['token'] as String;
    final transmissionData = data['transmission'] as Map<String, dynamic>;
    final transmission = PortalTransmissionTokens.fromJson(transmissionData);
    return Tokens(token: token, transmission: transmission);
  }
}

enum Validity {
  unknown,
  valid,
  invalid,
  connectivity,
}

class PortalAccount extends ChangeNotifier {
  final String email;
  final String name;
  final Tokens? tokens;
  final bool active;
  final Validity validity;

  PortalAccount(
      {required this.email,
      required this.name,
      required this.tokens,
      required this.active,
      this.validity = Validity.unknown});

  factory PortalAccount.fromJson(Map<String, dynamic> data) {
    final email = data['email'] as String;
    final name = data['name'] as String;
    final active = data['active'] as bool;
    final tokensData = data["tokens"] as Map<String, dynamic>?;
    final tokens =
        tokensData != null ? PortalTokens.fromJson(tokensData) : null;
    return PortalAccount(
        email: email, name: name, tokens: tokens, active: active);
  }

  factory PortalAccount.fromAuthenticated(Authenticated authenticated) {
    return PortalAccount(
        email: authenticated.email,
        name: authenticated.name,
        tokens: authenticated.tokens,
        active: true,
        validity: Validity.valid);
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
        'tokens': tokens?.toJson(),
        'active': active,
      };

  PortalAccount invalid() {
    return PortalAccount(
        email: email,
        name: name,
        tokens: null,
        active: active,
        validity: Validity.invalid);
  }

  PortalAccount valid() {
    return PortalAccount(
        email: email,
        name: name,
        tokens: tokens,
        active: active,
        validity: Validity.valid);
  }

  PortalAccount connectivity() {
    return PortalAccount(
        email: email,
        name: name,
        tokens: tokens,
        active: active,
        validity: Validity.connectivity);
  }

  PortalAccount withActive(bool active) {
    return PortalAccount(
        email: email,
        name: name,
        tokens: tokens,
        active: active,
        validity: validity);
  }
}

enum PortalState {
  started,
  loading,
  loaded,
  validating,
  validated,
}

class PortalStateMachine extends ChangeNotifier {
  PortalState _state = PortalState.started;

  PortalState get state => _state;

  void transition(PortalState to) {
    if (_state != to) {
      Loggers.state.i("portal: $to");
      _state = to;
      notifyListeners();
    }
  }
}

class PortalAccounts extends ChangeNotifier {
  static const secureStorageKey = "fk.accounts";

  final PortalStateMachine portalState;
  final List<PortalAccount> _accounts = List.empty(growable: true);

  UnmodifiableListView<PortalAccount> get accounts =>
      UnmodifiableListView(_accounts);

  PortalAccount? get active => _accounts.where((a) => a.active).first;

  PortalAccounts({required this.portalState});

  static List<PortalAccount> fromJson(Map<String, dynamic> data) {
    final accountsData = data['accounts'] as List<dynamic>;
    return accountsData
        .map((accountData) => PortalAccount.fromJson(accountData))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'accounts': _accounts.map((a) => a.toJson()).toList(),
      };

  Future<PortalAccounts> load() async {
    Loggers.state.i("portal: loading");

    try {
      const storage = FlutterSecureStorage();
      String? value = await storage.read(key: secureStorageKey);
      if (value != null) {
        try {
          final loaded = PortalAccounts.fromJson(jsonDecode(value));
          _accounts.clear();
          _accounts.addAll(loaded);
        } catch (e) {
          Loggers.state.e("portal: $e");
        }
      }
    } catch (e) {
      Loggers.state.e("portal: fatal-exception: $e");
    } finally {
      portalState.transition(PortalState.loaded);
    }

    return this;
  }

  Future<void> refreshFirmware() async {
    try {
      // Refresh unauthenticated to get the production firmware.
      Loggers.state.w("firmware: unauthenticated");
      await cacheFirmware(tokens: null, background: true);

      // Request per-user development/testing firmware.
      for (PortalAccount account in _accounts) {
        Loggers.state.i("firmware: ${account.email}");
        await cacheFirmware(tokens: account.tokens, background: true);
      }
    } catch (e) {
      Loggers.main.e("firmware: $e");
    }
  }

  Future<PortalAccounts> _save() async {
    const storage = FlutterSecureStorage();
    final serialized = jsonEncode(this);
    await storage.write(key: secureStorageKey, value: serialized);
    return this;
  }

  Future<PortalAccount?> _authenticate(String email, String password) async {
    try {
      final authenticated =
          await authenticatePortal(email: email, password: password);
      return PortalAccount.fromAuthenticated(authenticated);
    } catch (e) {
      Loggers.state.e("portal: $e");
      return null;
    }
  }

  Future<void> registerAccount(
      String email, String password, String name, bool tncAccept) async {
    await registerPortalAccount(
        email: email, password: password, name: name, tncAccount: tncAccept);
  }

  Future<PortalAccount> _add(PortalAccount account) async {
    _removeByEmail(account.email);
    _accounts.add(account);
    await _save();
    Loggers.state.i("portal: add");
    notifyListeners();
    return account;
  }

  Future<PortalAccount?> addOrUpdate(String email, String password) async {
    final account = await _authenticate(email, password);
    if (account != null) {
      return await _add(account);
    } else {
      return null;
    }
  }

  Future<void> activate(PortalAccount account) async {
    final updated =
        _accounts.map((iter) => iter.withActive(account == iter)).toList();
    _accounts.clear();
    _accounts.addAll(updated);
    await _save();
    Loggers.state.i("portal: activate");
    notifyListeners();
  }

  bool _removeByEmail(String email) {
    var filtered = _accounts.where((iter) => iter.email != email).toList();
    if (filtered.length == _accounts.length) {
      return false;
    }
    _accounts.clear();
    _accounts.addAll(filtered);
    return true;
  }

  Future<void> delete(PortalAccount account) async {
    _removeByEmail(account.email);
    await _save();
    Loggers.state.i("portal: delete");
    notifyListeners();
  }

  Future<PortalAccounts> validateAccount(PortalAccount account) async {
    final tokens = account.tokens;
    if (tokens != null) {
      _accounts.remove(account);
      try {
        _accounts.add(PortalAccount.fromAuthenticated(
            await validateTokens(tokens: tokens)));
      } on PortalError_Authentication catch (e) {
        Loggers.state.e("portal(validate): $e");
        _accounts.add(account.invalid());
      } catch (e) {
        Loggers.state.e("portal(validate): $e");
        _accounts.add(account.connectivity());
      }
      await _save();
      notifyListeners();
    }
    return this;
  }

  Future<PortalAccounts> validate() async {
    portalState.transition(PortalState.validating);

    final validating = _accounts.map((e) => e).toList();
    _accounts.clear();
    for (final iter in validating) {
      final tokens = iter.tokens;
      if (tokens != null) {
        await validateAccount(iter);
      } else {
        _accounts.add(iter);
      }
    }

    await _save();

    portalState.transition(PortalState.validated);

    return this;
  }

  PortalAccount? getAccountForDevice(String deviceId) {
    if (_accounts.isEmpty) {
      return null;
    }
    return _accounts[0];
  }

  bool hasAnyTokens() {
    final maybeTokens =
        _accounts.map((e) => e.tokens).where((e) => e != null).firstOrNull;
    return maybeTokens != null;
  }

  void markValid(PortalAccount account) {
    _accounts.removeWhere((el) => el.email == account.email);
    _accounts.add(account.valid());
    Loggers.state.i("portal: mark-valid");
    notifyListeners();
  }

  void markConnectivyIssue(PortalAccount account) {
    _accounts.removeWhere((el) => el.email == account.email);
    _accounts.add(account.connectivity());
    Loggers.state.i("portal: mark-issue");
    notifyListeners();
  }
}

class ModuleConfiguration {
  final proto.ModuleConfiguration? configuration;

  ModuleConfiguration(this.configuration);

  List<proto.Calibration> get calibrations => configuration?.calibrations ?? [];

  bool get isCalibrated => calibrations.isNotEmpty;
}

class ModuleConfigurations extends ChangeNotifier {
  final KnownStationsModel knownStations;

  ModuleConfigurations({required this.knownStations}) {
    knownStations.addListener(() {
      notifyListeners();
    });
  }

  ModuleConfiguration find(ModuleIdentity moduleIdentity) {
    final stationAndModule = knownStations.findModule(moduleIdentity);
    final configuration = stationAndModule?.module.configuration;
    Loggers.state.v("$moduleIdentity Configuration: $configuration");
    if (configuration == null || configuration.isEmpty) {
      return ModuleConfiguration(null);
    }

    final CodedBufferReader reader = CodedBufferReader(configuration);
    final List<int> delimited = reader.readBytes();
    return ModuleConfiguration(proto.ModuleConfiguration.fromBuffer(delimited));
  }

  Future<void> clear(ModuleIdentity moduleIdentity) async {
    final mas = knownStations.findModule(moduleIdentity);
    if (mas != null) {
      await retryOnFailure(() async {
        await clearCalibration(
            deviceId: mas.station.deviceId, module: mas.module.position);
      });
    } else {
      Loggers.state.e("Unknown module identity $moduleIdentity");
    }
  }

  Future<void> calibrateModule(
      ModuleIdentity moduleIdentity, Uint8List data) async {
    final mas = knownStations.findModule(moduleIdentity);
    if (mas != null) {
      await retryOnFailure(() async {
        await calibrate(
            deviceId: mas.station.deviceId,
            module: mas.module.position,
            data: data);
      });
    } else {
      Loggers.state.e("Unknown module identity $moduleIdentity");
    }
  }

  Future<void> retryOnFailure(Future<void> Function() work) async {
    for (var i = 0; i < 3; ++i) {
      try {
        return await work();
      } catch (e) {
        Loggers.state.e("$e");
        Loggers.state.w("retrying");
      }
    }
  }

  bool areAllModulesCalibrated(StationModel station, BuildContext context) {
    final config = station.config;
    if (config != null) {
      for (final module in config.modules) {
        final moduleIdentity = module.identity;
        final moduleConfig = find(moduleIdentity);
        final localizations = AppLocalizations.of(context)!;
        final localized = LocalizedModule.get(module, localizations);
        if (moduleConfig.calibrations.isEmpty && localized.canCalibrate) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}
