import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:fk/app_state.dart';
import 'package:fk/connections.dart';
import 'package:fk/constants.dart';
import 'package:fk/home_page.dart';
import 'package:fk/preferences.dart';
import 'package:fk/reader/screens.dart';
import 'package:fk/settings/accounts_page.dart';

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

  ThemeData theme() {
    final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(88, 36),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );

    final ButtonStyle flatButtonStyle = TextButton.styleFrom(
      minimumSize: const Size(88, 36),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );

    return ThemeData(
      fontFamily: 'Avenir',
      textButtonTheme: TextButtonThemeData(style: flatButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: raisedButtonStyle),
      primaryColor: Colors.white, // changes the default AppBar color
      hintColor: Colors.grey, // changes the default color of many widgets
      brightness: Brightness.light, // changes the AppBar content color to dark
      primaryTextTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Color.fromARGB(255, 48, 44, 44),
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Color.fromARGB(255, 44, 37, 37),
        ),
        titleTextStyle: TextStyle(
          fontFamily: "Avenir-Medium",
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
    );
  }

  Iterable<Locale> locales() {
    return const [
      Locale('en'),
      Locale('es'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context)!.fieldKit,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: locales(),
      locale: _locale ?? widget.locale,
      theme: theme(),
      home: MultiProvider(
        providers: [
          ValueListenableProvider.value(value: widget.env.appState),
        ],
        child: const LoaderOverlay(
            child: MonitorConnectionWidget(
                child: ProvideContentFlowsWidget(
                    eager: true,
                    child: ProvideAccountsWidget(child: HomePage())))),
      ),
    );
  }
}
