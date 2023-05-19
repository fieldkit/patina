import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'gen/ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dispatcher.dart';

class StationModel {
  final String deviceId;
  final StationConfig? config;
  SyncingProgress? syncing;
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
      var byDeviceId = {};
      for (var station in nearby.field0) {
        _stations.putIfAbsent(station.deviceId, () => StationModel(deviceId: station.deviceId));
        byDeviceId[station.deviceId] = true;
      }
      for (var station in _stations.values) {
        station.connected = byDeviceId.containsKey(station.deviceId);
      }
      notifyListeners();
    });

    dispatcher.addListener<DomainMessage_StationRefreshed>((refreshed) {
      var station = refreshed.field0;
      _stations[station.deviceId] = StationModel(deviceId: station.deviceId, config: station, connected: true);
      notifyListeners();
    });

    _load();
  }

  void _load() async {
    var stations = await api.getMyStations();
    debugPrint("(load) my-stations: $stations");
    for (var station in stations) {
      _stations[station.deviceId] = StationModel(deviceId: station.deviceId, config: station);
    }
    notifyListeners();
  }

  StationModel? find(String deviceId) {
    return _stations[deviceId];
  }

  Future<void> startDownload({required String deviceId}) async {
    await api.startDownload(deviceId: deviceId);
  }

  Future<void> startUpload({required String deviceId}) async {
    await api.startUpload(deviceId: deviceId);
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
  final String? refresh;

  const PortalTokens({required this.token, this.refresh});

  factory PortalTokens.fromJson(Map<String, dynamic> data) {
    final token = data['token'] as String;
    final refresh = data['refresh'] as String?;

    return PortalTokens(token: token, refresh: refresh);
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'refresh': refresh,
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
      final portalTokens = PortalTokens(token: tokens.token, refresh: tokens.refresh);
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
        _accounts.add(PortalAccount(email: iter.email, tokens: tokens, active: iter.active, valid: validated != null));
      }
    }
    notifyListeners();
    return this;
  }
}

class SyncingProgress extends ChangeNotifier {}
