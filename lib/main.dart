import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'ffi.dart' if (dart.library.html) 'ffi_web.dart';
import 'dart:async';
import 'dart:developer' as developer;

import 'dispatcher.dart';
import 'home_page.dart';

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
    debugPrint('Native module error: $e $st');
  }
}

Future<AppEnv> initializeCurrentEnv(AppEventDispatcher dispatcher) async {
  _runNative(dispatcher);

  return AppEnv.appState(dispatcher);
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

void main() async {
  var env = await initializeCurrentEnv(AppEventDispatcher());

  debugPrint("initialized: $env");

  runApp(OurApp(env: env));
}
