import 'package:fk/preferences.dart';
import 'package:fk/settings/help_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
final GlobalKey<NavigatorState> helpNavigatorKey = GlobalKey();

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;
  bool _showWelcome = true;
  int _openCount = 0;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    final appPrefs = AppPreferences();
    _openCount = await appPrefs.getOpenCount() ?? 0;
    await _checkIfFirstTimeToday();
  }

  Future<void> _checkIfFirstTimeToday() async {
    final appPrefs = AppPreferences();
    bool showWelcomeScreen = false;
    DateTime today = DateTime.now();
    DateTime? lastOpened = await appPrefs.getLastOpened();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _openCount++;
    });

    print('open count: $_openCount');

    if (showWelcomeScreen) {
      setState(() {
        _showWelcome = true;
      });
    } else if (lastOpened == null ||
        lastOpened.day != today.day ||
        lastOpened.month != today.month ||
        lastOpened.year != today.year) {
      await appPrefs.setLastOpened(today);
      if (_openCount < 3) {
        setState(() {
          _showWelcome = true;
        });
        await prefs.setBool('showWelcome', true);
      } else {
        setState(() {
          _showWelcome = false;
        });
        await prefs.setBool('showWelcome', false);
      }
    } else {
      setState(() {
        _showWelcome = prefs.getBool('showWelcome') ?? false;
      });
    }
    print('show welcome: $_showWelcome');
  }

  void setPageIndex(int index) {
    setState(() {
      _pageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.done) {
            return SafeArea(
              child: _showWelcome
                  ? WelcomeScreen(
                      onDone: () async {
                        setState(() {
                          _showWelcome = false;
                        });
                        final appPrefs = AppPreferences();
                        await appPrefs.setOpenCount(_openCount);
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('showWelcome', false);
                      },
                    )
                  : IndexedStack(
                      index: _pageIndex,
                      children: <Widget>[
                        MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(
                                value: context.read<AppState>().moduleConfigurations),
                            ChangeNotifierProvider.value(
                                value: context.read<AppState>().knownStations),
                            ChangeNotifierProvider.value(
                                value: context.read<AppState>().firmware),
                            ChangeNotifierProvider.value(
                                value: context.read<AppState>().stationOperations),
                            ChangeNotifierProvider.value(
                                value: context.read<AppState>().tasks),
                          ],
                          child: Navigator(
                            key: stationsNavigatorKey,
                            onGenerateRoute: (RouteSettings settings) {
                              return MaterialPageRoute(
                                  settings: settings,
                                  builder: (context) => const StationsTab());
                            },
                          ),
                        ),
                        MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(
                                value: context.read<AppState>().knownStations),
                            ChangeNotifierProvider.value(
                                value: context.read<AppState>().firmware),
                            ChangeNotifierProvider.value(
                                value: context.read<AppState>().stationOperations),
                            ChangeNotifierProvider.value(
                                value: context.read<AppState>().tasks),
                          ],
                          child: Navigator(
                            key: dataNavigatorKey,
                            onGenerateRoute: (RouteSettings settings) {
                              return MaterialPageRoute(
                                  settings: settings,
                                  builder: (context) => const DataSyncTab());
                            },
                          ),
                        ),
                        Navigator(
                          key: settingsNavigatorKey,
                          onGenerateRoute: (RouteSettings settings) {
                            return MaterialPageRoute(
                                settings: settings,
                                builder: (BuildContext context) {
                                  return const SettingsTab();
                                });
                          },
                        ),
                        Navigator(
                          key: helpNavigatorKey,
                          onGenerateRoute: (RouteSettings settings) {
                            return MaterialPageRoute(
                                settings: settings,
                                builder: (BuildContext context) {
                                  return const HelpTab();
                                });
                          },
                        ),
                      ],
                    ),
            );
          } else {
            return const Center(child: Text('Error initializing app.'));
          }
        },
      ),
      bottomNavigationBar: _showWelcome
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF2C3E50),
              unselectedLabelStyle: const TextStyle(fontSize: 12.0),
              selectedLabelStyle: const TextStyle(
                  fontSize: 12.0, fontWeight: FontWeight.w700),
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Image.asset(
                      'resources/images/icon_station_inactive.png',
                      width: 24,
                      height: 24),
                  activeIcon: Image.asset(
                      'resources/images/icon_station_active.png',
                      width: 24,
                      height: 24),
                  label: AppLocalizations.of(context)!.stationsTab,
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                      'resources/images/icon_data_sync_inactive.png',
                      width: 24,
                      height: 24),
                  activeIcon: Image.asset(
                      'resources/images/icon_data_sync_active.png',
                      width: 24,
                      height: 24),
                  label: AppLocalizations.of(context)!.dataSyncTab,
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                      'resources/images/icon_settings_inactive.png',
                      width: 24,
                      height: 24),
                  activeIcon: Image.asset(
                      'resources/images/icon_settings_active.png',
                      width: 24,
                      height: 24),
                  label: AppLocalizations.of(context)!.settingsTab,
                ),
                BottomNavigationBarItem(
                  icon: SvgPicture.asset(
                      "resources/images/icon_help_settings.svg",
                      semanticsLabel: AppLocalizations.of(context)!
                          .helpSettingsIconInactive,
                      colorFilter: const ColorFilter.mode(
                          Color(0xFF9a9fa6), BlendMode.srcIn)),
                  activeIcon: SvgPicture.asset(
                      "resources/images/icon_help_settings.svg",
                      semanticsLabel:
                          AppLocalizations.of(context)!.helpSettingsIconActive,
                      colorFilter: const ColorFilter.mode(
                          Color(0xFF2c3e50), BlendMode.srcIn)),
                  label: AppLocalizations.of(context)!.helpTab,
                ),
              ],
              currentIndex: _pageIndex,
              onTap: (int index) {
                setPageIndex(index);
              },
            ),
    );
  }
}

class CustomPageRoute<T> extends MaterialPageRoute<T> {
  CustomPageRoute({required super.builder, super.settings});

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (settings.name == '/settings') {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    } else {
      return super
          .buildTransitions(context, animation, secondaryAnimation, child);
    }
  }
}
