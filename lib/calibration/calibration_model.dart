import 'package:caldor/calibration.dart';
import 'package:fk/gen/api.dart';
import 'package:fk/meta.dart';
import 'package:flutter/foundation.dart';

import '../app_state.dart';

class ActiveCalibration extends ChangeNotifier {
  double? _standard;

  double? get standard => _standard;

  bool get invalid => _standard == null;

  void haveStandard(double? standard) {
    _standard = standard;
    notifyListeners();
  }

  @override
  String toString() => "Active(standard = $_standard)";

  UserStandard userStandard() {
    return UserStandard(_standard!);
  }
}

class CalibrationConfig {
  final ModuleIdentity moduleIdentity;
  final CurveType curveType;
  final List<Standard> standards;
  final List<Step> steps;

  Standard get standard => standards.first;

  bool get done => standards.isEmpty;

  Step? get step => steps.firstOrNull;

  CalibrationConfig._internal({
    required this.moduleIdentity,
    required this.curveType,
    required this.standards,
    required this.steps,
  });

  static CalibrationConfig fromModule(ModuleConfig module) {
    final localized = LocalizedModule.get(module);
    final template = localized.calibrationTemplate!;
    // final help = CalibrationHelp.fromModule(module);
    final List<Step> steps = [
      // HelpStep(screen: "calibration.water.temp.01"),
      // HelpStep(screen: "calibration.water.temp.02"),
      // HelpStep(screen: "calibration.water.temp.03"),
      StandardStep(standard: template.standards[0]),
      // HelpStep(screen: "calibration.water.temp.01"),
      // HelpStep(screen: "calibration.water.temp.02"),
      // HelpStep(screen: "calibration.water.temp.03"),
      StandardStep(standard: template.standards[1]),
      // HelpStep(screen: "calibration.water.temp.01"),
      // HelpStep(screen: "calibration.water.temp.02"),
      // HelpStep(screen: "calibration.water.temp.03"),
      StandardStep(standard: template.standards[2])
    ];
    return CalibrationConfig._internal(
        moduleIdentity: module.identity,
        curveType: template.curveType,
        steps: steps,
        standards: List.from(template.standards));
  }

  CalibrationConfig popStandard() {
    standards.removeAt(0);
    return this;
  }
}

class CalibrationHelp {
  final List<List<String>> standards;

  CalibrationHelp({required this.standards});

  static CalibrationHelp fromModule(ModuleConfig module) {
    switch (module.key) {
      case "modules.water.temp":
        return CalibrationHelp(standards: [
          ["calibration.water.temp.01", "calibration.water.temp.02"],
          ["calibration.water.temp.01", "calibration.water.temp.02"],
          ["calibration.water.temp.01", "calibration.water.temp.02"]
        ]);
      case "modules.water.ph":
        return CalibrationHelp(standards: List.empty());
      case "modules.water.orp":
        return CalibrationHelp(standards: List.empty());
      case "modules.water.do":
        return CalibrationHelp(standards: List.empty());
      case "modules.water.ec":
        return CalibrationHelp(standards: List.empty());
    }
    return CalibrationHelp(standards: List.empty());
  }
}

class Step {}

class HelpStep extends Step {
  final String screen;

  HelpStep({required this.screen});
}

class StandardStep extends Step {
  final Standard standard;

  StandardStep({required this.standard});
}
