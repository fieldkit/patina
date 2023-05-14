import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dispatcher.dart';

class Station {
  final String deviceId;
  final String? name;

  const Station({
    required this.deviceId,
    required this.name,
  });
}

class KnownStationsModel extends ChangeNotifier {
  final List<Station> _stations = [];

  UnmodifiableListView<Station> get stations => UnmodifiableListView(_stations);

  KnownStationsModel(AppEventDispatcher dispatcher) {
    dispatcher.addListener<DomainMessage_NearbyStations>((nearby) {
      debugPrint("known-stations:nearby $nearby");
      for (var station in nearby.field0) {
        debugPrint("known-stations:nearby $station");
        _stations.add(Station(deviceId: station.deviceId, name: station.name));
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
