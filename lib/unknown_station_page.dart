import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NoSuchStationPage extends StatelessWidget {
  const NoSuchStationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.unknownStationTitle),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text(AppLocalizations.of(context)!.backButtonTitle),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
