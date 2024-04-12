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
  final List<Standard> standardsRemaining;

  Standard get standard => standardsRemaining.first;

  bool get done => standardsRemaining.isEmpty;

  CalibrationConfig._internal({
    required this.moduleIdentity,
    required this.curveType,
    required this.standardsRemaining,
  });

  static CalibrationConfig fromModule(ModuleConfig module) {
    final localized = LocalizedModule.get(module);
    final template = localized.calibrationTemplate!;
    return CalibrationConfig._internal(
        moduleIdentity: module.identity,
        curveType: template.curveType,
        standardsRemaining: List.from(template.standards));
  }

  CalibrationConfig popStandard() {
    return CalibrationConfig._internal(
        moduleIdentity: moduleIdentity,
        curveType: curveType,
        standardsRemaining: standardsRemaining.skip(1).toList());
  }
}
