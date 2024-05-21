import 'dart:async';

import 'package:fk/connections.dart';
import 'package:fk/diagnostics.dart';
import 'package:fk/preferences.dart';
import 'package:fk/reader/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:fk/settings/accounts_page.dart';

import 'gen/api.dart';
import 'gen/frb_generated.dart';

import 'constants.dart';
import 'app_state.dart';
import 'dispatcher.dart';
import 'home_page.dart';

final logger = Loggers.main;

Future<String> _getStoragePath() async {
  final fromEnv = dotenv.env['FK_APP_SUPPORT_PATH'];
  if (fromEnv != null) {
    return fromEnv;
  }

  final location = await getApplicationSupportDirectory();
  return location.path;
}

Future<void> _startNative(
    Configuration config, AppEventDispatcher dispatcher) async {
  createLogSink().listen((logRow) {
    var display = logRow.trim();
    Loggers.bridge.i(display);
  });

  // This is here because the initial native logs were getting chopped off, no
  // idea why and yes this is a hack.
  await Future.delayed(const Duration(milliseconds: 100));

  await for (final e in startNative(
    storagePath: config.storagePath,
    portalBaseUrl: config.portalBaseUrl,
  )) {
    Loggers.sdkMessages.v("$e");
    dispatcher.dispatch(e);
  }
}

class Configuration {
  final String storagePath;
  final String portalBaseUrl;

  Configuration({
    required this.storagePath,
    required this.portalBaseUrl,
  });
}

Future<Configuration> _loadConfiguration() async {
  await dotenv.load(fileName: ".env");

  final storagePath = await _getStoragePath();
  final portalBaseUrl =
      dotenv.env['FK_PORTAL_URL'] ?? "https://api.fieldkit.org";

  return Configuration(storagePath: storagePath, portalBaseUrl: portalBaseUrl);
}

// Restoring this from the original Flutter designs after update

final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: AppColors.primaryColor,
  foregroundColor: Colors.white,
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);

Future<AppEnv> initializeCurrentEnv(
    Configuration config, AppEventDispatcher dispatcher) async {
  Loggers.initialize(config.storagePath);

  logger.i("storage: ${config.storagePath}");
  logger.i("portal: ${config.portalBaseUrl}");

  final completer = Completer<AppEnv>();

  void listener(DomainMessage e) {
    // Remove the listener because we'll continue to be called after the first
    // message and the completer will be done.
    dispatcher.removeListener(listener);
    completer.complete(AppEnv.appState(dispatcher));
  }

  dispatcher.addListener(listener);

  void run() async {
    try {
      await _startNative(config, dispatcher);
    } catch (err, stack) {
      logger.e('Native module error: $err $stack');
    } finally {
      dispatcher.removeListener(listener);
    }
  }

  run();

  return completer.future;
}

class OurApp extends StatefulWidget {
  final AppEnv env;
  final Locale locale;

  const OurApp({super.key, required this.env, required this.locale});

  @override
  State<OurApp> createState() => _OurAppState();

  static setLocale(BuildContext context, Locale value) {
    final state = context.findAncestorStateOfType<_OurAppState>()!;
    state.setLocale(value);

    final prefs = AppPreferences();
    prefs.setLocale(value.languageCode);
  }

  static State<OurApp> of(BuildContext context) =>
      context.findAncestorStateOfType<State<OurApp>>()!;
}

class _OurAppState extends State<OurApp> {
  Locale? _locale;

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ValueListenableProvider.value(value: widget.env.appState),
        ],
        child: ProvideAccountsWidget(
          child: MaterialApp(
            onGenerateTitle: (BuildContext context) =>
                AppLocalizations.of(context)!.fieldKit,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('es'),
            ],
            locale: _locale ?? widget.locale,
            title: 'FieldKit',
            theme: ThemeData(
              textButtonTheme: TextButtonThemeData(style: flatButtonStyle),
              elevatedButtonTheme:
                  ElevatedButtonThemeData(style: raisedButtonStyle),
              primaryColor: Colors.white, // changes the default AppBar color
              hintColor:
                  Colors.grey, // changes the default color of many widgets
              brightness:
                  Brightness.light, // changes the AppBar content color to dark
              primaryTextTheme: const TextTheme(
                titleLarge: TextStyle(
                  color: Color.fromARGB(255, 48, 44, 44),
                ),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                iconTheme: IconThemeData(
                  color: Color.fromARGB(255, 44, 37, 37),
                ),
                titleTextStyle: TextStyle(
                  color: Color.fromARGB(255, 48, 44, 44),
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                ),
                shape: Border(
                    bottom: BorderSide(
                        color: Color.fromARGB(255, 221, 221, 221), width: 2)),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              scaffoldBackgroundColor:
                  Colors.white, // changes the default Scaffold background color
            ),
            home: const LoaderOverlay(
                child: MonitorConnectionWidget(
                    child: ProvideContentFlowsWidget(
                        eager: true, child: HomePage()))),
          ),
        ));
  }
}

void main() async {
  await RustLib.init();

  // Necessary so we can call path_provider from startup, otherwise this is done
  // inside runApp. 'The "instance" getter on the ServicesBinding binding mixin
  // is only available once that binding has been initialized.'
  WidgetsFlutterBinding.ensureInitialized();

  final config = await _loadConfiguration();

  final env = await initializeCurrentEnv(config, AppEventDispatcher());

  final refName = getCommitRefName();
  final sha = getCommitSha();

  final prefs = AppPreferences();
  final locale = Locale(await prefs.getLocale());

  logger.i("Initialized: ref=$refName sha=$sha locale=$locale");

  runApp(OurApp(env: env, locale: locale));
}
