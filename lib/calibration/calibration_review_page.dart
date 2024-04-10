import 'package:fk/calibration/calibration_review_widget.dart';
import 'package:fk/gen/api.dart';
import 'package:flutter/material.dart';

class CalibrationReviewPage extends StatelessWidget {
  final ModuleConfig module;

  const CalibrationReviewPage({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return CalibrationReviewWidget(
        module: module,
        onKeep: () {
          navigator.popUntil((route) => route.isFirst);
        });
  }
}
