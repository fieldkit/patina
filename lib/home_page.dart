import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'my_stations_page.dart';
import 'settings/settings_page.dart';
import 'sync/sync_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

final GlobalKey<NavigatorState> stationsNavigatorKey = GlobalKey();
final GlobalKey<NavigatorState> dataNavigatorKey = GlobalKey();
final GlobalKey<NavigatorState> settingsNavigatorKey = GlobalKey();

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _pageIndex,
          children: <Widget>[
            // Should we just push this to the top?
            MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: state.knownStations),
                  ChangeNotifierProvider.value(value: state.firmware),
                  ChangeNotifierProvider.value(value: state.stationOperations),
                  ChangeNotifierProvider.value(value: state.tasks),
                ],
                child: Navigator(
                    key: stationsNavigatorKey,
                    onGenerateRoute: (RouteSettings settings) {
                      return MaterialPageRoute(settings: settings, builder: (context) => const StationsTab());
                    })),
            MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: state.knownStations),
                  ChangeNotifierProvider.value(value: state.firmware),
                  ChangeNotifierProvider.value(value: state.stationOperations),
                ],
                child: Navigator(
                    key: dataNavigatorKey,
                    onGenerateRoute: (RouteSettings settings) {
                      return MaterialPageRoute(settings: settings, builder: (context) => const DataSyncTab());
                    })),
            Navigator(
                key: settingsNavigatorKey,
                onGenerateRoute: (RouteSettings settings) {
                  return MaterialPageRoute(
                      settings: settings,
                      builder: (BuildContext context) {
                        return const SettingsTab();
                      });
                })
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.stationsTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.business),
            label: AppLocalizations.of(context)!.dataSyncTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.computer),
            label: AppLocalizations.of(context)!.settingsTab,
          ),
        ],
        currentIndex: _pageIndex,
        onTap: (int index) {
          final navigator = Navigator.of(context);
          debugPrint("home-page: Tap $index $navigator");
          if (_pageIndex == index) {
            final List<GlobalKey<NavigatorState>> keys = [stationsNavigatorKey, dataNavigatorKey, settingsNavigatorKey];
            final NavigatorState? navigator = keys[index].currentState;
            if (navigator != null) {
              while (navigator.canPop()) {
                navigator.pop();
              }
            }
          } else {
            setState(
              () {
                _pageIndex = index;
              },
            );
          }
        },
      ),
    );
  }
}
