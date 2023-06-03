import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import 'calibration_model.dart';
import 'calibration_page.dart';

class ClearCalibrationPage extends StatelessWidget {
  final CalibrationPointConfig config;

  const ClearCalibrationPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final moduleConfigurations = context.read<AppState>().moduleConfigurations;

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.calibrationTitle),
        ),
        body: Column(
          children: <Widget>[
            ElevatedButton(
                child: const Text("Clear"),
                onPressed: () async {
                  debugPrint("clearing calibration");
                  final navigator = Navigator.of(context);
                  try {
                    await moduleConfigurations.clear(config.moduleIdentity);
                    debugPrint("cleared!");
                  } catch (e) {
                    debugPrint("Exception clearing: $e");
                  }
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => CalibrationPage(config: config),
                    ),
                  );
                }),
            ElevatedButton(
                child: const Text("Keep"),
                onPressed: () {
                  debugPrint("keeping calibration");
                  final navigator = Navigator.of(context);
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => CalibrationPage(config: config),
                    ),
                  );
                }),
          ].map(WH.padPage).toList(),
        ));
  }
}
