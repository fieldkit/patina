import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    debugPrint("$deviceId transfer ${transferProgress.status}");
    final station = findOrCreate(deviceId);
    station.connected = true;

    final status = transferProgress.status;
    if (status is TransferStatus_Starting) {
      station.syncing = SyncingProgress(progress: transferProgress);
    }
    if (status is TransferStatus_Transferring) {
      station.syncing = SyncingProgress(progress: transferProgress);
    }
    if (status is TransferStatus_Completed) {
      station.syncing = null;
    }
    if (status is TransferStatus_Failed) {
      station.syncing = SyncingProgress(progress: transferProgress);
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

  Future<void> startUpload({required String deviceId}) async {
    final station = find(deviceId);
    if (station == null) {
      debugPrint("$deviceId station missing");
      return;
    }

    if (station.syncing != null) {
      debugPrint("$deviceId already syncing");
      return;
    }

    final progress = await api.startUpload(deviceId: deviceId);
    applyTransferProgress(progress);
  }

  ModuleConfig? findModule(ModuleIdentity moduleIdentity) {
    for (final station in stations) {
      final config = station.config;
      if (config != null) {
        for (final module in config.modules) {
          if (module.identity == moduleIdentity) {
            return module;
          }
        }
      }
    }
    return null;
  }
}

class AppState {
  final Native api;
  final AppEventDispatcher dispatcher;
  final KnownStationsModel knownStations;
  final PortalAccounts portalAccounts;

  AppState._(this.api, this.dispatcher, this.knownStations, this.portalAccounts);

  static AppState build(Native api, AppEventDispatcher dispatcher) {
    return AppState._(api, dispatcher, KnownStationsModel(api, dispatcher), PortalAccounts(api: api, accounts: List.empty()));
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

class PortalTokens {
  final String token;
  final PortalTransmissionToken? transmission;

  const PortalTokens({required this.token, this.transmission});

  factory PortalTokens.fromJson(Map<String, dynamic> data) {
    final token = data['token'] as String;
    final transmissionData = data['transmission'] as Map<String, dynamic>?;
    final transmission = transmissionData != null ? PortalTransmissionToken.fromJson(transmissionData) : null;

    return PortalTokens(token: token, transmission: transmission);
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'transmission': transmission?.toJson(),
      };
}

class PortalTransmissionToken {
  final String token;
  final String url;

  const PortalTransmissionToken({required this.token, required this.url});

  factory PortalTransmissionToken.fromJson(Map<String, dynamic> data) {
    final token = data['token'] as String;
    final url = data['url'] as String;

    return PortalTransmissionToken(token: token, url: url);
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'url': url,
      };
}

class PortalAccount extends ChangeNotifier {
  final String email;
  final PortalTokens? tokens;
  final bool active;
  final bool? valid;

  PortalAccount({required this.email, required this.tokens, required this.active, this.valid});

  factory PortalAccount.fromJson(Map<String, dynamic> data) {
    final email = data['email'] as String;
    final active = data['active'] as bool;
    final tokensData = data["tokens"] as Map<String, dynamic>?;
    final tokens = tokensData != null ? PortalTokens.fromJson(tokensData) : null;

    return PortalAccount(email: email, tokens: tokens, active: active);
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'tokens': tokens?.toJson(),
        'active': active,
      };
}

class PortalAccounts extends ChangeNotifier {
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

  // ignore: unused_element
  static Future<PortalAccounts> _get(Native api) async {
    const storage = FlutterSecureStorage();
    String? value = await storage.read(key: "fk.accounts");
    if (value == null) {
      return PortalAccounts(api: api, accounts: List.empty());
    } else {
      return PortalAccounts.fromJson(api, jsonDecode(value));
    }
  }

  // A little messy, I know.
  Future<PortalAccounts> load() async {
    const storage = FlutterSecureStorage();
    String? value = await storage.read(key: "fk.accounts");
    if (value != null) {
      final loaded = PortalAccounts.fromJson(api, jsonDecode(value));
      _accounts.clear();
      _accounts.addAll(loaded.accounts);
      notifyListeners();
    }
    return this;
  }

  Future<PortalAccounts> save() async {
    const storage = FlutterSecureStorage();
    final serialized = jsonEncode(this);
    await storage.write(key: "fk.accounts", value: serialized);
    return this;
  }

  Future<PortalAccount?> addOrUpdate(String email, String password) async {
    final tokens = await api.authenticatePortal(email: email, password: password);
    if (tokens != null) {
      final portalTokens = PortalTokens(
          token: tokens.token,
          transmission: tokens.transmission != null
              ? PortalTransmissionToken(token: tokens.transmission!.token, url: tokens.transmission!.url)
              : null);
      final account = PortalAccount(email: email, tokens: portalTokens, active: true, valid: true);
      _accounts.add(account);
      await save();
      notifyListeners();
      return account;
    } else {
      return null;
    }
  }

  Future<void> activate(PortalAccount account) async {
    var updated = _accounts.map((iter) {
      // Got a hunch there's a better way to do this.
      return PortalAccount(email: iter.email, tokens: iter.tokens, active: account == iter, valid: iter.valid);
    }).toList();
    _accounts.clear();
    _accounts.addAll(updated);
    await save();
    notifyListeners();
  }

  Future<void> delete(PortalAccount account) async {
    var updated = _accounts.where((iter) {
      return iter.email != account.email;
    }).toList();
    _accounts.clear();
    _accounts.addAll(updated);
    await save();
    notifyListeners();
  }

  Future<PortalAccounts> validate() async {
    final validating = _accounts.map((e) => e).toList();
    _accounts.clear();
    for (final iter in validating) {
      final tokens = iter.tokens;
      if (tokens != null) {
        final validated = await api.validateTokens(tokens: Tokens(token: tokens.token));
        if (validated == null) {
          _accounts.add(PortalAccount(email: iter.email, tokens: null, active: iter.active, valid: false));
        } else {
          final portalTokens = PortalTokens(token: tokens.token, transmission: tokens.transmission);
          _accounts.add(PortalAccount(email: iter.email, tokens: portalTokens, active: iter.active, valid: true));
        }
      }
    }
    await save();
    notifyListeners();
    return this;
  }
}

class SyncingProgress extends ChangeNotifier {
  final TransferProgress progress;

  SyncingProgress({required this.progress});
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
