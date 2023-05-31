import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_rust_bridge_template/settings/accounts_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'gen/ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'app_state.dart';
import 'dispatcher.dart';
import 'home_page.dart';

Future<String> _getStoragePath() async {
  const fromEnv = String.fromEnvironment('FK_APP_SUPPORT_PATH');
  if (fromEnv.isNotEmpty) {
    return fromEnv;
  }

  final location = await getApplicationSupportDirectory();
  return location.path;
}

Future<void> _startNative(AppEventDispatcher dispatcher) async {
  api.createLogSink().listen((logRow) {
    var display = logRow.trim();
    debugPrint(display);
    developer.log(display);
  });

  final storagePath = await _getStoragePath();

  // This is here because the initial native logs were getting chopped off, no
  // idea why and yes this is a hack.
  await Future.delayed(const Duration(milliseconds: 100));

  await for (final e in api.startNative(storagePath: storagePath)) {
    var display = e.toString().trim();
    debugPrint(display);
    developer.log(display);
    dispatcher.dispatch(e);
  }
}

Future<AppEnv> initializeCurrentEnv(AppEventDispatcher dispatcher) async {
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
      await _startNative(dispatcher);
    } catch (err, stack) {
      debugPrint('Native module error: $err $stack');
    } finally {
      dispatcher.removeListener(listener);
    }
  }

  run();

  return completer.future;
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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ValueListenableProvider.value(value: widget.env.appState),
        ],
        child: ProvideAccountsWidget(
            child: MaterialApp(
          onGenerateTitle: (BuildContext context) => AppLocalizations.of(context)!.fieldKit,
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
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: const LoaderOverlay(child: HomePage()),
        )));
  }
}

void main() async {
  // Necessary so we can call path_provider from startup, otherwise this is done
  // inside runApp. 'The "instance" getter on the ServicesBinding binding mixin
  // is only available once that binding has been initialized.'
  WidgetsFlutterBinding.ensureInitialized();

  var env = await initializeCurrentEnv(AppEventDispatcher());

  debugPrint("initialized: $env");

  runApp(OurApp(env: env));
}
