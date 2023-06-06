import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fk/gen/fk-data.pb.dart';

import '../gen/fk-data.pb.dart' as proto;
import 'gen/ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dispatcher.dart';

class StationModel {
  final String deviceId;
  StationConfig? config;
  SyncingProgress? syncing;
  bool connected;
  bool busy;

  StationModel({
    required this.deviceId,
    this.config,
    this.connected = false,
    this.busy = false,
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
        station.busy = nearby?.busy;
      }
      notifyListeners();
    });

    dispatcher.addListener<DomainMessage_StationRefreshed>((refreshed) {
      final station = findOrCreate(refreshed.field0.deviceId);
      station.config = refreshed.field0;
      station.connected = true;
      notifyListeners();
    });

    dispatcher.addListener<DomainMessage_TransferProgress>((transferProgress) {
      applyTransferProgress(transferProgress.field0);
    });

    _load();
  }

  void applyTransferProgress(TransferProgress transferProgress) {
    final deviceId = transferProgress.deviceId;
    final station = findOrCreate(deviceId);
    final status = transferProgress.status;

    station.connected = true;
    if (status is TransferStatus_Starting) {
      station.syncing = SyncingProgress(download: null, upload: null);
    }
    if (status is TransferStatus_Downloading) {
      station.syncing = SyncingProgress(download: status.field0, upload: null);
    }
    if (status is TransferStatus_Uploading) {
      station.syncing = SyncingProgress(download: null, upload: status.field0);
    }
    if (status is TransferStatus_Completed) {
      station.syncing = null;
    }
    if (status is TransferStatus_Failed) {
      station.syncing = SyncingProgress(download: null, upload: null); // TODO Handle failed transfer/sync.
    }

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

class AppState {
  final Native api;
  final AppEventDispatcher dispatcher;
  final KnownStationsModel knownStations;
  final ModuleConfigurations moduleConfigurations;
  final PortalAccounts portalAccounts;

  AppState._(this.api, this.dispatcher, this.knownStations, this.moduleConfigurations, this.portalAccounts);

  static AppState build(Native api, AppEventDispatcher dispatcher) {
    final knownStations = KnownStationsModel(api, dispatcher);
    return AppState._(api, dispatcher, knownStations, ModuleConfigurations(api: api, knownStations: knownStations),
        PortalAccounts(api: api, accounts: List.empty()));
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
  final DownloadProgress? download;
  final UploadProgress? upload;

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

  SensorConfig? get calibrationSensor {
    if (key.startsWith("modules.water")) {
      return sensors[0];
    }
    return null;
  }
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

class ModuleConfigurations extends ChangeNotifier {
  final Native api;
  final KnownStationsModel knownStations;

  ModuleConfigurations({required this.api, required this.knownStations});

  ModuleConfiguration? findModuleConfiguration(ModuleIdentity moduleIdentity) {
    final configuration = knownStations.findModule(moduleIdentity)?.module.configuration;
    if (configuration == null) {
      return null;
    }

    return proto.ModuleConfiguration.fromBuffer(configuration);
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
