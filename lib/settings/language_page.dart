import 'package:fk/app_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          title: Text(localizations.settingsLanguage),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: ListView(padding: const EdgeInsets.all(16.0), children: <Widget>[
          SelectLocaleWidget(
              locale: const Locale("en"), label: localizations.languageEnglish),
          SelectLocaleWidget(
              locale: const Locale("es"), label: localizations.languageSpanish),
        ]));
  }
}

class SelectLocaleWidget extends StatelessWidget {
  final Locale locale;
  final String label;

  const SelectLocaleWidget(
      {super.key, required this.locale, required this.label});

  @override
  Widget build(BuildContext context) {
    final Locale active = Localizations.localeOf(context);

    return CheckboxListTile(
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (checked) {
        if (checked == true) {
          OurApp.setLocale(context, locale);
        }
      },
      value: active.languageCode == locale.languageCode,
    );
  }
}
