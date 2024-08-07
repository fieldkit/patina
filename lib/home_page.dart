import 'package:fk/diagnostics.dart';
import 'package:fk/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'my_stations_page.dart';
import 'settings/settings_page.dart';
import 'sync/sync_page.dart';
import 'welcome.dart';

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
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    _checkIfFirstTimeToday();
  }

  _checkIfFirstTimeToday() async {
    final appPrefs = AppPreferences();
    bool showWelcomeScreen = dotenv.env['SHOW_WELCOME_SCREEN'] == 'true';
    if (showWelcomeScreen) {
      Loggers.ui.i("Forced welcome screen");
      DateTime today = DateTime.now();
      await appPrefs.setLastOpened(today);

      setState(() {
        _showWelcome = true; // Always show welcome page when the app opens
      });
    } else {
      DateTime? lastOpened = await appPrefs.getLastOpened();
      DateTime today = DateTime.now();

      if (lastOpened == null ||
          lastOpened.day != today.day ||
          lastOpened.month != today.month ||
          lastOpened.year != today.year) {
        await appPrefs.setLastOpened(today);
        setState(() {
          _showWelcome = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Scaffold(
      body: SafeArea(
        child:
            _showWelcome // Change to _showWelcome to true to test welcome feature
                ? WelcomeScreen(
                    onDone: () {
                      setState(() {
                        _showWelcome = false;
                      });
                    },
                  )
                : IndexedStack(
                    index: _pageIndex,
                    children: <Widget>[
                      // Should we just push this to the top?
                      MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(
                                value: state.moduleConfigurations),
                            ChangeNotifierProvider.value(
                                value: state.knownStations),
                            ChangeNotifierProvider.value(value: state.firmware),
                            ChangeNotifierProvider.value(
                                value: state.stationOperations),
                            ChangeNotifierProvider.value(value: state.tasks),
                          ],
                          child: Navigator(
                              key: stationsNavigatorKey,
                              onGenerateRoute: (RouteSettings settings) {
                                return MaterialPageRoute(
                                    settings: settings,
                                    builder: (context) => const StationsTab());
                              })),
                      MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(
                                value: state.knownStations),
                            ChangeNotifierProvider.value(value: state.firmware),
                            ChangeNotifierProvider.value(
                                value: state.stationOperations),
                            ChangeNotifierProvider.value(value: state.tasks),
                          ],
                          child: Navigator(
                              key: dataNavigatorKey,
                              onGenerateRoute: (RouteSettings settings) {
                                return MaterialPageRoute(
                                    settings: settings,
                                    builder: (context) => const DataSyncTab());
                              })),
                      Navigator(
                          key: settingsNavigatorKey,
                          onGenerateRoute: (RouteSettings settings) {
                            return MaterialPageRoute(
                                settings: settings,
                                builder: (BuildContext context) {
                                  return const SettingsTab();
                                });
                          }),
                    ],
                  ),
      ),
      bottomNavigationBar: _showWelcome
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF2C3E50),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Image.asset(
                      'resources/images/Icon_Station_inactive2.png',
                      width: 24,
                      height: 24),
                  activeIcon: Image.asset(
                      'resources/images/Icon_Station_active2.png',
                      width: 24,
                      height: 24),
                  label: AppLocalizations.of(context)!.stationsTab,
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                      'resources/images/Icon_DataSync_inactive2.png',
                      width: 24,
                      height: 24),
                  activeIcon: Image.asset(
                      'resources/images/Icon_DataSync_active2.png',
                      width: 24,
                      height: 24),
                  label: AppLocalizations.of(context)!.dataSyncTab,
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                      'resources/images/Icon_Settings_inactive2.png',
                      width: 24,
                      height: 24),
                  activeIcon: Image.asset(
                      'resources/images/Icon_Settings_active2.png',
                      width: 24,
                      height: 24),
                  label: AppLocalizations.of(context)!.settingsTab,
                ),
              ],
              currentIndex: _pageIndex,
              onTap: (int index) {
                if (_pageIndex == index) {
                  final List<GlobalKey<NavigatorState>> keys = [
                    stationsNavigatorKey,
                    dataNavigatorKey,
                    settingsNavigatorKey
                  ];
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
