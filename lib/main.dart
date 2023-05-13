import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'dispatcher.dart';

class Station {
  final String deviceId;
  final String name;

  const Station({
    required this.deviceId,
    required this.name,
  });
}

class KnownStationsModel extends ChangeNotifier {
  final List<Station> _stations = [
    const Station(deviceId: '0', name: 'Quirky Puppy 34'),
    const Station(deviceId: '1', name: 'Super Slinky 11'),
    const Station(deviceId: '2', name: 'Slippery Penguin 20'),
  ];

  UnmodifiableListView<Station> get stations => UnmodifiableListView(_stations);

  void add(Station station) {
    _stations.add(station);
    notifyListeners();
  }
}

Future<void> _startNative(AppEventDispatcher dispatcher) async {
  api.createLogSink().listen((logRow) {
    var display = logRow.trim();
    debugPrint(display);
    developer.log(display);
  });

  // This is here because the initial native logs were getting chopped off, no
  // idea why and yes this is a hack.
  await Future.delayed(const Duration(milliseconds: 100));

  await for (final e in api.startNative()) {
    var display = e.toString().trim();
    debugPrint(display);
    developer.log(display);
    dispatcher.dispatch(e);
  }
}

void _runNative(AppEventDispatcher dispatcher) async {
  try {
    await _startNative(dispatcher);
  } catch (e, st) {
    debugPrint('Cannot setup native module: $e $st');
  }
}

class AppState {
  final AppEventDispatcher dispatcher;

  AppState._(this.dispatcher);

  static AppState build(AppEventDispatcher dispatcher) {
    return AppState._(dispatcher);
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

Future<AppEnv> initializeCurrentEnv(AppEventDispatcher dispatcher) async {
  _runNative(dispatcher);

  return AppEnv.appState(dispatcher);
}

void main() async {
  var env = await initializeCurrentEnv(AppEventDispatcher());

  debugPrint("initialized: $env");

  runApp(ChangeNotifierProvider(
    create: (context) => KnownStationsModel(),
    child: OurApp(env: env),
  ));
}

class StationsTab extends StatelessWidget {
  const StationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // final state = context.read<AppState>();
    final state = context.watch<AppState>();

    return Navigator(onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => Consumer<KnownStationsModel>(
          builder: (context, knownStations, child) {
            return ListStationsRoute(stations: knownStations.stations);
          },
        ),
      );
    });
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Settings'),
              ),
              body: Center(
                child: ElevatedButton(
                  child: const Text('Settings'),
                  onPressed: () {},
                ),
              ),
            );
          });
    });
  }
}

class DataSyncTab extends StatelessWidget {
  const DataSyncTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => const DataSyncRoute(),
      );
    });
  }
}

class Map extends StatelessWidget {
  const Map({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(48.864716, 2.349014),
        zoom: 9.2,
      ),
      nonRotatedChildren: [
        AttributionWidget.defaultWidget(
          source: 'OpenStreetMap contributors',
          onSourceTapped: null,
        ),
      ],
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'org.fieldkit.app',
        ),
      ],
    );
  }
}

class ListStationsRoute extends StatelessWidget {
  const ListStationsRoute({super.key, required this.stations});

  final List<Station> stations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stations'),
      ),
      body: ListView.builder(
        itemCount: stations.length + 1,
        itemBuilder: (context, index) {
          // This is a huge hack, but was the fastest way to get this working
          // and shouldn't leak outside of this class.
          if (index == 0) {
            return const SizedBox(height: 300, child: Map());
          }

          return ListTile(
            title: Text(stations[index - 1].name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ViewStationRoute(station: stations[index - 1]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ViewStationRoute extends StatelessWidget {
  const ViewStationRoute({super.key, required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(station.name),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Back'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class DataSyncRoute extends StatelessWidget {
  const DataSyncRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sync'),
      ),
      body: const Center(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _pageIndex,
          children: const <Widget>[
            StationsTab(),
            DataSyncTab(),
            SettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Stations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.computer),
            label: 'Settings',
          ),
        ],
        currentIndex: _pageIndex,
        onTap: (int index) {
          setState(
            () {
              _pageIndex = index;
            },
          );
        },
      ),
    );
  }
}

class OurApp extends StatefulWidget {
  final AppEnv env;
  const OurApp({Key? key, required this.env}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _OurAppState();
  }
}

class _OurAppState extends State<OurApp> {
  @override
  void initState() {
    super.initState();
    developer.log("app-state:initialize");
    widget.env.dispatcher.addListener(_listener);
  }

  @override
  void dispose() {
    super.dispose();
    widget.env.dispatcher.removeListener(_listener);
  }

  void _listener(DomainMessage e) async {}

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ValueListenableProvider.value(value: widget.env.appState),
        ],
        child: MaterialApp(
          title: 'FieldKit',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: const HomePage(),
        ));
  }
}
