import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'common_widgets.dart';

class NoSuchStationPage extends StatelessWidget {
  const NoSuchStationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.unknownStationTitle),
      ),
      body: Center(
        child: ElevatedTextButton(
          text: AppLocalizations.of(context)!.backButtonTitle,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
