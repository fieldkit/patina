import 'package:fk/calibration/calibration_review_widget.dart';
import 'package:fk/gen/api.dart';
import 'package:fk/providers.dart';
import 'package:flutter/material.dart';

import '../diagnostics.dart';
import 'calibration_model.dart';
import 'calibration_page.dart';

class ClearCalibrationPage extends StatelessWidget {
  final CalibrationConfig config;
  final ModuleConfig module;

  const ClearCalibrationPage(
      {super.key, required this.config, required this.module});

  @override
  Widget build(BuildContext context) {
    return CalibrationReviewWidget(
        module: module,
        onAfterClear: () {
          Loggers.cal.i("clearing calibration");
          final navigator = Navigator.of(context);
          navigator.push(
            MaterialPageRoute(
              builder: (context) => ModuleProviders(
                  moduleIdentity: config.moduleIdentity,
                  child: CalibrationPage(config: config)),
            ),
          );
        },
        onKeep: () {
          Loggers.cal.i("keeping calibration");
          final navigator = Navigator.of(context);
          navigator.push(
            MaterialPageRoute(
              builder: (context) => CalibrationPage(config: config),
            ),
          );
        },
        onBack: () {
          Loggers.cal.i("back from calibration");
          final navigator = Navigator.of(context);
          navigator.pop();
        });
  }
}
