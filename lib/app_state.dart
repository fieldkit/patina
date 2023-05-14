import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'gen/ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dispatcher.dart';

class StationConfig {
  final String name;

  const StationConfig({required this.name});
}

class StationModel {
  final String deviceId;
  final StationConfig? config;

  const StationModel({
    required this.deviceId,
    this.config,
  });
}

class KnownStationsModel extends ChangeNotifier {
  final List<StationModel> _stations = [];

  UnmodifiableListView<StationModel> get stations =>
      UnmodifiableListView(_stations);

  KnownStationsModel(AppEventDispatcher dispatcher) {
    dispatcher.addListener<DomainMessage_NearbyStations>((nearby) {
      debugPrint("known-stations:nearby $nearby");
      for (var station in nearby.field0) {
        debugPrint("known-stations:nearby $station");
        _stations.add(StationModel(deviceId: station.deviceId));
      }
      notifyListeners();
    });
  }
}

class AppState {
  final KnownStationsModel knownStations;
  final AppEventDispatcher dispatcher;

  AppState._(this.dispatcher, this.knownStations);

  static AppState build(AppEventDispatcher dispatcher) {
    return AppState._(dispatcher, KnownStationsModel(dispatcher));
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
          appState: AppState.build(dispatcher),
        );

  ValueListenable<AppState?> get appState => _appState;
}
