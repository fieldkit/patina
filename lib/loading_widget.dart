import 'dart:async';

import 'package:fk/app_widget.dart';
import 'package:fk/constants.dart';
import 'package:fk/diagnostics.dart';
import 'package:fk/gen/api.dart';
import 'package:fk/preferences.dart';
import 'package:fk/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

import 'app_state.dart';
import 'dispatcher.dart';

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({super.key});

  @override
  State<StatefulWidget> createState() => _LoadingState();
}

class _LoadingState extends State<LoadingWidget> {
  final List<String> _values = List.empty(growable: true);

  Widget progress() {
    return Container(
        decoration: const BoxDecoration(
          gradient: AppColors.blueGradient,
        ),
        child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(children: [
              const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(100, 0, 100, 0),
                      child: LargeLogo(white: true),
                    ),
                  ]),
              Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _values
                      .map((e) => Center(
                              child: Text(
                            e,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          )))
                      .toList()),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: initialize(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data != null && snapshot.data?.message != null) {
              Loggers.ui.i("${snapshot.data}");
              _values.add(snapshot.data!.message!);
            } else {
              _values.clear();
              return OurApp(
                  env: snapshot.data!.env!, locale: snapshot.data!.locale!);
            }
          }

          return progress();
        });
  }
}

Stream<LoadingStep> initialize() async* {
  final prefs = AppPreferences();
  final locale = Locale(await prefs.getLocale());
  yield LoadingStep.info("Locale");

  // It would be nice to localize these, but it's obvious how outside of the
  // normal AppLocalizations framework.

  await Future.delayed(const Duration(milliseconds: 10));
  final config = await Configuration.load();
  yield LoadingStep.info("Configuration");
  await Future.delayed(const Duration(milliseconds: 10));

  final env = await _initializeCurrentEnv(config, AppEventDispatcher());
  yield LoadingStep.info("Environment");
  await Future.delayed(const Duration(milliseconds: 10));

  await env.appState.value!.portalAccounts.load();
  yield LoadingStep.info("Accounts");
  await Future.delayed(const Duration(milliseconds: 10));

  Loggers.main.i("Initialized: config=$config locale=$locale");

  yield LoadingStep.done(env, locale);
}

class LoadingStep {
  final String? message;
  final AppEnv? env;
  final Locale? locale;

  LoadingStep({required this.message, required this.env, required this.locale});

  static LoadingStep info(String m) {
    return LoadingStep(message: m, env: null, locale: null);
  }

  static LoadingStep done(AppEnv env, Locale locale) {
    return LoadingStep(message: null, env: env, locale: locale);
  }
}

class Configuration {
  final String? commitRefName;
  final String? commitSha;
  final String storagePath;
  final String portalBaseUrl;

  Configuration({
    required this.commitRefName,
    required this.commitSha,
    required this.storagePath,
    required this.portalBaseUrl,
  });

  static Future<Configuration> load() async {
    await dotenv.load(fileName: ".env");

    final storagePath = await Configuration._getStoragePath();

    final commitRefName = dotenv.env['CI_COMMIT_REF_NAME'];
    final commitSha = dotenv.env['CI_COMMIT_SHA'];
    final portal = dotenv.env['FK_PORTAL_URL'] ?? "https://api.fieldkit.org";

    return Configuration(
        commitRefName: commitRefName,
        commitSha: commitSha,
        storagePath: storagePath,
        portalBaseUrl: portal);
  }

  static Future<String> _getStoragePath() async {
    final fromEnv = dotenv.env['FK_APP_SUPPORT_PATH'];
    if (fromEnv != null) {
      return fromEnv;
    }

    final location = await getApplicationSupportDirectory();
    return location.path;
  }

  @override
  String toString() {
    return "Config(commitRefName=$commitRefName, commitSha=$commitSha, storagePath=$storagePath, portalBaseUrl=$portalBaseUrl)";
  }
}

Future<AppEnv> _initializeCurrentEnv(
    Configuration config, AppEventDispatcher dispatcher) async {
  Loggers.initialize(config.storagePath);

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
      Loggers.main.e('Native module error: $err $stack');
    } finally {
      dispatcher.removeListener(listener);
    }
  }

  run();

  return completer.future;
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
