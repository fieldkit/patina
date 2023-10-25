import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:protobuf/protobuf.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:fk_data_protocol/fk-data.pb.dart' as proto;

import 'diagnostics.dart';
import 'gen/ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dispatcher.dart';

class StationModel {
  final String deviceId;
  StationConfig? config;
  EphemeralConfig? ephemeral;
  SyncingProgress? syncing;
  FirmwareInfo? get firmware => config?.firmware;
  bool connected;

  StationModel({
    required this.deviceId,
    this.config,
    this.connected = false,
  });
}

class UpdatePortal {
  UpdatePortal(Native api, PortalAccounts portalAccounts, AppEventDispatcher dispatcher) {
    dispatcher.addListener<DomainMessage_StationRefreshed>((refreshed) async {
      final deviceId = refreshed.field0.deviceId;
      final account = portalAccounts.getAccountForDevice(deviceId);
      final tokens = account?.tokens;
      if (tokens != null) {
        final name = refreshed.field0.name;
        try {
          final idIfOk = await api.addOrUpdateStationInPortal(
              tokens: tokens,
              station: AddOrUpdatePortalStation(name: name, deviceId: deviceId, locationName: "", statusPb: refreshed.field2));
          if (idIfOk == null) {
            Loggers.main.w("$deviceId permissions-conflict");
          } else {
            Loggers.main.i("$deviceId refreshed portal-id=$idIfOk");
          }
        } catch (e) {
          Loggers.main.i("Add or update portal error: $e");
        }
      } else {
        // TODO Warn user about lack of updates due to logged out.
        Loggers.main.w("$deviceId need-auth");
      }
    });
  }
}

class KnownStationsModel extends ChangeNotifier {
  final Map<String, StationModel> _stations = {};

  UnmodifiableListView<StationModel> get stations => UnmodifiableListView(_stations.values);

  KnownStationsModel(Native api, AppEventDispatcher dispatcher) {
    dispatcher.addListener<DomainMessage_NearbyStations>((nearby) {
      final byDeviceId = {};
      for (var station in nearby.field0) {
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
      notifyListeners();
    });

    dispatcher.addListener<DomainMessage_DownloadProgress>((transferProgress) {
      applyTransferProgress(transferProgress.field0);
    });

    dispatcher.addListener<DomainMessage_UploadProgress>((transferProgress) {
      applyTransferProgress(transferProgress.field0);
    });

    _load();
  }

  void applyTransferProgress(TransferProgress transferProgress) {
    final deviceId = transferProgress.deviceId;
    final station = findOrCreate(deviceId);
    final status = transferProgress.status;

    if (status is TransferStatus_Starting) {
      station.syncing = SyncingProgress(download: null, upload: null);
    }
    if (status is TransferStatus_Downloading) {
      station.syncing = SyncingProgress(download: DownloadOperation(status: status), upload: null);
    }
    if (status is TransferStatus_Uploading) {
      station.syncing = SyncingProgress(download: null, upload: UploadOperation(status: status));
    }
    if (status is TransferStatus_Completed) {
      station.syncing = null;
    }
    if (status is TransferStatus_Failed) {
      station.syncing = SyncingProgress(download: null, upload: null);
    }

    station.connected = true;

    notifyListeners();
  }

  void _load() async {
    var stations = await api.getMyStations();
    Loggers.state.i("(load) my-stations: $stations");
    for (var station in stations) {
      findOrCreate(station.deviceId).config = station;
    }
    notifyListeners();
  }

  StationModel? find(String deviceId) {
    return _stations[deviceId];
  }

  StationModel findOrCreate(String deviceId) {
    _stations.putIfAbsent(deviceId, () => StationModel(deviceId: deviceId));
    return _stations[deviceId]!;
  }

  Future<void> startDownload({required String deviceId, int? first}) async {
    final station = find(deviceId);
    if (station == null) {
      Loggers.state.w("$deviceId station missing");
      return;
    }

    if (station.syncing != null) {
      Loggers.state.w("$deviceId already syncing");
      return;
    }

    final progress = await api.startDownload(deviceId: deviceId, first: first);
    applyTransferProgress(progress);
  }

  Future<void> startUpload({required String deviceId, required Tokens tokens, required List<RecordArchive> files}) async {
    final station = find(deviceId);
    if (station == null) {
      Loggers.state.w("$deviceId station missing");
      return;
    }

    if (station.syncing != null) {
      Loggers.state.w("$deviceId already syncing");
      return;
    }

    final progress = await api.startUpload(deviceId: deviceId, tokens: tokens, files: files);
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
      getOrCreate<UpgradeOperation>(() => UpgradeOperation(upgradeProgress.field0.firmwareId), upgradeProgress.field0.deviceId)
          .update(upgradeProgress);
      notifyListeners();
    });
    dispatcher.addListener<DomainMessage_DownloadProgress>((transferProgress) {
      getOrCreate<TransferOperation>(DownloadOperation.new, transferProgress.field0.deviceId).update(transferProgress);
      notifyListeners();
    });
    dispatcher.addListener<DomainMessage_UploadProgress>((transferProgress) {
      getOrCreate<TransferOperation>(UploadOperation.new, transferProgress.field0.deviceId).update(transferProgress);
      notifyListeners();
    });
    dispatcher.addListener<DomainMessage_FirmwareDownloadStatus>((downloadProgress) {
      getOrCreate<FirmwareDownloadOperation>(FirmwareDownloadOperation.new, globalOperationKey).update(downloadProgress);
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
}

abstract class Operation extends ChangeNotifier {
  void update(DomainMessage message);

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
  bool get done => status is TransferStatus_Completed || status is TransferStatus_Failed;

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

  TransferStatus_Downloading? get _downloading => status as TransferStatus_Downloading;

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

  FirmwareComparison({required this.label, required this.time, required this.otherTime, required this.newer});

  factory FirmwareComparison.compare(LocalFirmware local, FirmwareInfo station) {
    final other = DateTime.fromMillisecondsSinceEpoch(station.time * 1000);
    final time = DateTime.fromMillisecondsSinceEpoch(local.time);
    return FirmwareComparison(label: local.label, time: time, otherTime: other, newer: time.isAfter(other));
  }
}

class UpgradeOperation extends Operation {
  int firmwareId;
  UpgradeStatus status = const UpgradeStatus.starting();

  UpgradeOperation(this.firmwareId);

  @override
  void update(DomainMessage message) {
    if (message is DomainMessage_UpgradeProgress) {
      firmwareId = message.field0.firmwareId;
      status = message.field0.status;
      notifyListeners();
    }
  }

  @override
  bool get done => status is UpgradeStatus_Completed || status is UpgradeStatus_Failed;
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
  bool get done => status is FirmwareDownloadStatus_Completed || status is FirmwareDownloadStatus_Failed;
}

class AvailableFirmwareModel extends ChangeNotifier {
  final Native api;
  final List<LocalFirmware> _firmware = [];

  UnmodifiableListView<LocalFirmware> get firmware => UnmodifiableListView(_firmware);

  AvailableFirmwareModel({required this.api, required AppEventDispatcher dispatcher}) {
    dispatcher.addListener<DomainMessage_AvailableFirmware>((availableFirmware) {
      _firmware.clear();
      _firmware.addAll(availableFirmware.field0);
      notifyListeners();
    });
  }

  Future<void> upgrade(String deviceId, LocalFirmware firmware) async {
    await api.upgradeStation(deviceId: deviceId, firmware: firmware, swap: false);
  }
}

class StationConfiguration extends ChangeNotifier {
  final Native api;
  final PortalAccounts portalAccounts;

  StationConfiguration({required this.api, required this.portalAccounts});

  Future<void> enableWifiUploading(String deviceId) async {
    final account = portalAccounts.getAccountForDevice(deviceId);
    if (account == null) {
      Loggers.state.i("No account for device $deviceId (hasAny: ${portalAccounts.hasAnyTokens()})");
      return;
    }

    await api.configureWifiTransmission(deviceId: deviceId, config: WifiTransmissionConfig(tokens: account.tokens));
  }

  Future<void> disableWifiUploading(String deviceId) async {
    await api.configureWifiTransmission(deviceId: deviceId, config: const WifiTransmissionConfig(tokens: null));
  }
}

var uuid = const Uuid();

abstract class Task {
  final String key_ = uuid.v1();

  String get key => key_;
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
    return tasks;
  }
}

class DeployTask extends Task {
  final StationModel station;

  DeployTask({required this.station});
}

class UpgradeTaskFactory extends TaskFactory<UpgradeTask> {
  final AvailableFirmwareModel availableFirmware;
  final KnownStationsModel knownStations;

  UpgradeTaskFactory({required this.availableFirmware, required this.knownStations}) {
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
            Loggers.state.i("UpgradeTask ${station.config?.name} ${local.label} ${comparison.label}");
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
}

class DownloadTaskFactory extends TaskFactory<DownloadTask> {
  List<NearbyStation> _nearby = List.empty();
  List<RecordArchive> _archives = List.empty();
  final Map<String, int> _records = {};

  DownloadTaskFactory({required KnownStationsModel knownStations, required AppEventDispatcher dispatcher}) {
    dispatcher.addListener<DomainMessage_StationRefreshed>((refreshed) {
      _records[refreshed.field0.deviceId] = refreshed.field0.data.records;
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
      final int? first = archivesById[nearby.deviceId]?.map((archive) => archive.tail).reduce(max);
      final int? total = _records[nearby.deviceId];
      if (total != null) {
        tasks.add(DownloadTask(deviceId: nearby.deviceId, total: total, first: first));
      }
    }
    return tasks;
  }
}

class DownloadTask extends Task {
  final String deviceId;
  final int total;
  final int? first;

  DownloadTask({required this.deviceId, required this.total, this.first});

  @override
  String toString() {
    return "DownloadTask($deviceId, $first, $total)";
  }
}

class UploadTaskFactory extends TaskFactory<UploadTask> {
  final PortalAccounts portalAccounts;
  List<RecordArchive> _archives = List.empty();

  UploadTaskFactory({required this.portalAccounts, required AppEventDispatcher dispatcher}) {
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
    final byId = _archives.groupListsBy((a) => a.deviceId);
    for (final entry in byId.entries) {
      final tokens = portalAccounts.getAccountForDevice(entry.key)?.tokens;
      if (tokens != null) {
        tasks.add(UploadTask(deviceId: entry.key, files: entry.value, tokens: tokens));
      }
    }
    return tasks;
  }
}

class UploadTask extends Task {
  final String deviceId;
  final List<RecordArchive> files;
  final Tokens tokens;

  UploadTask({required this.deviceId, required this.files, required this.tokens});

  @override
  String toString() {
    return "UploadTask($deviceId, $files)";
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
    factories.add(UploadTaskFactory(portalAccounts: portalAccounts, dispatcher: dispatcher));
    factories.add(DownloadTaskFactory(knownStations: knownStations, dispatcher: dispatcher));
    factories.add(UpgradeTaskFactory(availableFirmware: availableFirmware, knownStations: knownStations));
    for (final TaskFactory f in factories) {
      f.addListener(notifyListeners);
    }
  }

  List<T> getAll<T extends Task>() {
    return factories.map((f) => f.getAll<T>()).flattened.toList();
  }

  List<T> getAllFor<T extends Task>(String deviceId) {
    return factories.map((f) => f.getAll<T>()).flattened.toList();
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
  final Native api;
  final AppEventDispatcher dispatcher;
  final AvailableFirmwareModel firmware;
  final StationConfiguration configuration;
  final KnownStationsModel knownStations;
  final StationOperations stationOperations;
  final ModuleConfigurations moduleConfigurations;
  final PortalAccounts portalAccounts;
  final TasksModel tasks;
  final UpdatePortal updatePortal;

  AppState._(this.api, this.dispatcher, this.knownStations, this.moduleConfigurations, this.portalAccounts, this.firmware,
      this.stationOperations, this.tasks, this.configuration, this.updatePortal);

  static AppState build(Native api, AppEventDispatcher dispatcher) {
    final stationOperations = StationOperations(dispatcher: dispatcher);
    final firmware = AvailableFirmwareModel(api: api, dispatcher: dispatcher);
    final knownStations = KnownStationsModel(api, dispatcher);
    final moduleConfigurations = ModuleConfigurations(api: api, knownStations: knownStations);
    final portalAccounts = PortalAccounts(api: api, accounts: List.empty());
    final tasks = TasksModel(
      availableFirmware: firmware,
      knownStations: knownStations,
      portalAccounts: portalAccounts,
      dispatcher: dispatcher,
    );
    final configurations = StationConfiguration(api: api, portalAccounts: portalAccounts);
    final updatePortal = UpdatePortal(api, portalAccounts, dispatcher);
    return AppState._(
      api,
      dispatcher,
      knownStations,
      moduleConfigurations,
      portalAccounts,
      firmware,
      stationOperations,
      tasks,
      configurations,
      updatePortal,
    );
  }

  ModuleConfiguration findModuleConfiguration(ModuleIdentity moduleIdentity) {
    return moduleConfigurations.find(moduleIdentity);
  }
}

class AppEnv {
  AppEventDispatcher dispatcher;
  ValueNotifier<AppState?> _appState;

  AppEnv._(this.dispatcher, {AppState? appState}) : _appState = ValueNotifier(appState);

  AppEnv.appState(AppEventDispatcher dispatcher)
      : this._(
          dispatcher,
          appState: AppState.build(api, dispatcher),
        );

  ValueListenable<AppState?> get appState => _appState;
}

class SyncingProgress extends ChangeNotifier {
  final DownloadOperation? download;
  final UploadOperation? upload;

  double? get completed {
    if (download != null) {
      return download?.completed ?? 0;
    }
    if (upload != null) {
      return upload?.completed ?? 0;
    }
    return null;
  }

  SyncingProgress({this.download, this.upload});
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
}

class PortalAccount extends ChangeNotifier {
  final String email;
  final String name;
  final Tokens? tokens;
  final bool active;
  final Validity valid;

  PortalAccount({required this.email, required this.name, required this.tokens, required this.active, this.valid = Validity.unknown});

  factory PortalAccount.fromJson(Map<String, dynamic> data) {
    final email = data['email'] as String;
    final name = data['name'] as String;
    final active = data['active'] as bool;
    final tokensData = data["tokens"] as Map<String, dynamic>?;
    final tokens = tokensData != null ? PortalTokens.fromJson(tokensData) : null;
    return PortalAccount(email: email, name: name, tokens: tokens, active: active);
  }

  factory PortalAccount.fromAuthenticated(Authenticated authenticated) {
    return PortalAccount(
        email: authenticated.email, name: authenticated.name, tokens: authenticated.tokens, active: true, valid: Validity.valid);
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
        'tokens': tokens?.toJson(),
        'active': active,
      };

  PortalAccount invalid() {
    return PortalAccount(email: email, name: name, tokens: null, active: active, valid: Validity.invalid);
  }

  PortalAccount withActive(bool active) {
    return PortalAccount(email: email, name: name, tokens: tokens, active: active, valid: valid);
  }
}

class PortalAccounts extends ChangeNotifier {
  static const secureStorageKey = "fk.accounts";

  final Native api;
  final List<PortalAccount> _accounts = List.empty(growable: true);

  UnmodifiableListView<PortalAccount> get accounts => UnmodifiableListView(_accounts);

  PortalAccount? get active => _accounts.where((a) => a.active).first;

  PortalAccounts({required this.api, required List<PortalAccount> accounts}) {
    _accounts.addAll(accounts);
  }

  factory PortalAccounts.fromJson(Native api, Map<String, dynamic> data) {
    final accountsData = data['accounts'] as List<dynamic>;
    final accounts = accountsData.map((accountData) => PortalAccount.fromJson(accountData)).toList();
    return PortalAccounts(api: api, accounts: accounts);
  }

  Map<String, dynamic> toJson() => {
        'accounts': _accounts.map((a) => a.toJson()).toList(),
      };

  Future<PortalAccounts> load() async {
    const storage = FlutterSecureStorage();
    String? value = await storage.read(key: secureStorageKey);
    if (value != null) {
      try {
        // A little messy, I know.
        final loaded = PortalAccounts.fromJson(api, jsonDecode(value));
        for (final account in loaded.accounts) {
          Loggers.state.v("Account email=${account.email} url=${account.tokens?.transmission.url} #devonly");
        }
        _accounts.clear();
        _accounts.addAll(loaded.accounts);
        notifyListeners();
      } catch (e) {
        Loggers.state.e("Exception loading accounts: $e");
      }
    }

    try {
      if (_accounts.isEmpty) {
        Loggers.state.w("Checking firmware (unauthenticated)");
        await api.cacheFirmware(tokens: null);
      } else {
        for (PortalAccount account in _accounts) {
          Loggers.state.i("Checking firmware (${account.email})");
          await api.cacheFirmware(tokens: account.tokens);
        }
      }
    } catch (e) {
      Loggers.main.i("Firmware update error: $e");
    }

    return this;
  }

  Future<PortalAccounts> _save() async {
    const storage = FlutterSecureStorage();
    final serialized = jsonEncode(this);
    await storage.write(key: secureStorageKey, value: serialized);
    return this;
  }

  Future<PortalAccount?> _authenticate(String email, String password) async {
    try {
      final authenticated = await api.authenticatePortal(email: email, password: password);
      return PortalAccount.fromAuthenticated(authenticated);
    } catch (e) {
      Loggers.state.e("Exception authenticating: $e");
      return null;
    }
  }

  Future<PortalAccount?> addOrUpdate(String email, String password) async {
    final account = await _authenticate(email, password);
    if (account != null) {
      _removeByEmail(account.email);
      _accounts.add(account);
      await _save();
      notifyListeners();
      return account;
    } else {
      return null;
    }
  }

  Future<void> activate(PortalAccount account) async {
    final updated = _accounts.map((iter) => iter.withActive(account == iter)).toList();
    _accounts.clear();
    _accounts.addAll(updated);
    await _save();
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
    notifyListeners();
  }

  Future<PortalAccounts> validate() async {
    final validating = _accounts.map((e) => e).toList();
    _accounts.clear();
    for (final iter in validating) {
      final tokens = iter.tokens;
      if (tokens != null) {
        try {
          _accounts.add(PortalAccount.fromAuthenticated(await api.validateTokens(tokens: tokens)));
        } catch (e) {
          Loggers.state.e("Exception validating: $e");
          _accounts.add(iter.invalid());
        }
      } else {
        _accounts.add(iter);
      }
    }
    await _save();
    notifyListeners();
    return this;
  }

  PortalAccount? getAccountForDevice(String deviceId) {
    if (_accounts.isEmpty) {
      return null;
    }
    return _accounts[0];
  }

  bool hasAnyTokens() {
    final maybeTokens = _accounts.map((e) => e.tokens).where((e) => e != null).firstOrNull;
    return maybeTokens != null;
  }
}

class ModuleConfiguration {
  final proto.ModuleConfiguration? configuration;

  ModuleConfiguration(this.configuration);

  List<proto.Calibration> get calibrations => configuration?.calibrations ?? [];

  bool get isCalibrated => calibrations.isNotEmpty;
}

class ModuleConfigurations extends ChangeNotifier {
  final Native api;
  final KnownStationsModel knownStations;

  ModuleConfigurations({required this.api, required this.knownStations});

  ModuleConfiguration find(ModuleIdentity moduleIdentity) {
    final stationAndModule = knownStations.findModule(moduleIdentity);
    final configuration = stationAndModule?.module.configuration;
    Loggers.state.i("Find module configuration $moduleIdentity ${stationAndModule?.station} ${stationAndModule?.module} $configuration");
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
      await api.clearCalibration(deviceId: mas.station.deviceId, module: mas.module.position);
    } else {
      Loggers.state.e("Unknown module identity $moduleIdentity");
    }
  }

  Future<void> calibrate(ModuleIdentity moduleIdentity, Uint8List data) async {
    final mas = knownStations.findModule(moduleIdentity);
    if (mas != null) {
      await api.calibrate(deviceId: mas.station.deviceId, module: mas.module.position, data: data);
    } else {
      Loggers.state.e("Unknown module identity $moduleIdentity");
    }
  }
}
