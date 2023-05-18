import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'gen/ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dispatcher.dart';

class StationModel {
  final String deviceId;
  final StationConfig? config;
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
}

class AppState {
  final Native api;
  final KnownStationsModel knownStations;
  final AppEventDispatcher dispatcher;

  AppState._(this.api, this.dispatcher, this.knownStations);

  static AppState build(Native api, AppEventDispatcher dispatcher) {
    return AppState._(api, dispatcher, KnownStationsModel(api, dispatcher));
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

class PortalAccount extends ChangeNotifier {
  final String email;
  final String token;
  final String refreshToken;
  final bool active;

  PortalAccount({required this.email, required this.token, required this.refreshToken, required this.active});

  factory PortalAccount.fromJson(Map<String, dynamic> data) {
    final email = data['email'] as String;
    final token = data['token'] as String;
    final refreshToken = data['refresh_token'] as String;
    final active = data['active'] as bool;

    return PortalAccount(email: email, token: token, refreshToken: refreshToken, active: active);
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'active': active,
      };
}

class PortalAccounts extends ChangeNotifier {
  final Native api;
  final List<PortalAccount> _accounts = List.empty(growable: true);

  UnmodifiableListView<PortalAccount> get accounts => UnmodifiableListView(_accounts);

  PortalAccounts({required this.api, required List<PortalAccount> accounts}) {
    _accounts.addAll(accounts);
  }

  factory PortalAccounts.fromJson(Native api, Map<String, dynamic> data) {
    final accountsData = data['accounts'] as List<dynamic>;
    final accounts = accountsData.map((accountData) => PortalAccount.fromJson(accountData)).toList();
    final portalAccounts = PortalAccounts(api: api, accounts: accounts); // Global
    return portalAccounts;
  }

  static Future<PortalAccounts> get(Native api) async {
    const storage = FlutterSecureStorage();
    String? value = await storage.read(key: "fk.accounts");
    if (value == null) {
      return PortalAccounts(api: api, accounts: List.empty());
    } else {
      return PortalAccounts.fromJson(api, jsonDecode(value));
    }
  }

  void save() async {
    const storage = FlutterSecureStorage();
    final serialized = jsonEncode(this);
    await storage.write(key: "fk.accounts", value: serialized);
  }

  void activate(PortalAccount account) async {
    debugPrint("activating $account");
    var updated = _accounts.map((iter) {
      // Got a hunch there's a better way to do this.
      return PortalAccount(email: iter.email, token: iter.token, refreshToken: iter.refreshToken, active: account == iter);
    }).toList();
    _accounts.clear();
    _accounts.addAll(updated);
    notifyListeners();
  }
}
