import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:fk_data_protocol/fk-data.pb.dart' as proto;

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
    debugPrint("(load) my-stations: $stations");
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

  Future<void> startDownload({required String deviceId}) async {
    final station = find(deviceId);
    if (station == null) {
      debugPrint("$deviceId station missing");
      return;
    }

    if (station.syncing != null) {
      debugPrint("$deviceId already syncing");
      return;
    }

    final progress = await api.startDownload(deviceId: deviceId);
    applyTransferProgress(progress);
  }

  Future<void> startUpload({required String deviceId, required Tokens tokens}) async {
    final station = find(deviceId);
    if (station == null) {
      debugPrint("$deviceId station missing");
      return;
    }

    if (station.syncing != null) {
      debugPrint("$deviceId already syncing");
      return;
    }

    final progress = await api.startUpload(deviceId: deviceId, tokens: tokens);
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
    debugPrint("Creating $T");
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

var uuid = const Uuid();

abstract class Task {
  final String key_ = uuid.v1();

  String get key => key_;
}

class UpgradeTaskFactory extends ChangeNotifier {
  final AvailableFirmwareModel availableFirmware;
  final KnownStationsModel knownStations;
  final List<UpgradeTask> tasks = List.empty(growable: true);

  UpgradeTaskFactory({required this.availableFirmware, required this.knownStations}) {
    listener() {
      tasks.clear();
      tasks.addAll(create());
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
            debugPrint("UpgradeTask ${station.config?.name} ${local.label} ${comparison.label}");
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

class TasksModel extends ChangeNotifier {
  TasksModel({required AvailableFirmwareModel availableFirmware, required KnownStationsModel knownStations}) {
    UpgradeTaskFactory(availableFirmware: availableFirmware, knownStations: knownStations).addListener(notifyListeners);
  }
}

class AppState {
  final Native api;
  final AppEventDispatcher dispatcher;
  final AvailableFirmwareModel firmware;
  final KnownStationsModel knownStations;
  final StationOperations stationOperations;
  final ModuleConfigurations moduleConfigurations;
  final PortalAccounts portalAccounts;
  final TasksModel tasks;

  AppState._(this.api, this.dispatcher, this.knownStations, this.moduleConfigurations, this.portalAccounts, this.firmware,
      this.stationOperations, this.tasks);

  static AppState build(Native api, AppEventDispatcher dispatcher) {
    final stationOperations = StationOperations(dispatcher: dispatcher);
    final firmware = AvailableFirmwareModel(api: api, dispatcher: dispatcher);
    final knownStations = KnownStationsModel(api, dispatcher);
    final moduleConfigurations = ModuleConfigurations(api: api, knownStations: knownStations);
    final portalAccounts = PortalAccounts(api: api, accounts: List.empty());
    final tasks = TasksModel(availableFirmware: firmware, knownStations: knownStations);
    return AppState._(api, dispatcher, knownStations, moduleConfigurations, portalAccounts, firmware, stationOperations, tasks);
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
        _accounts.clear();
        _accounts.addAll(loaded.accounts);
        notifyListeners();
      } catch (e) {
        debugPrint("Exception loading accounts: $e");
      }
    }

    if (_accounts.isEmpty) {
      debugPrint("Checking firmware (unauthenticated)");
      await api.cacheFirmware(tokens: null);
    } else {
      for (PortalAccount account in _accounts) {
        debugPrint("Checking firmware (${account.email})");
        await api.cacheFirmware(tokens: account.tokens);
      }
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
      debugPrint("Exception authenticating: $e");
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
          debugPrint("Exception validating: $e");
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
    final configuration = knownStations.findModule(moduleIdentity)?.module.configuration;
    if (configuration == null) {
      return ModuleConfiguration(null);
    }
    return ModuleConfiguration(proto.ModuleConfiguration.fromBuffer(configuration));
  }

  Future<void> clear(ModuleIdentity moduleIdentity) async {
    final mas = knownStations.findModule(moduleIdentity);
    if (mas != null) {
      await api.clearCalibration(deviceId: mas.station.deviceId, module: mas.module.position);
    } else {
      debugPrint("unknown module identity $moduleIdentity");
    }
  }

  Future<void> calibrate(ModuleIdentity moduleIdentity, Uint8List data) async {
    final mas = knownStations.findModule(moduleIdentity);
    if (mas != null) {
      await api.calibrate(deviceId: mas.station.deviceId, module: mas.module.position, data: data);
    } else {
      debugPrint("unknown module identity $moduleIdentity");
    }
  }
}
