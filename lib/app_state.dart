import 'dart:collection';

import 'package:flutter/foundation.dart';

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
