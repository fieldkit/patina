import 'package:caldor/calibration.dart';
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

class CalibrationPointConfig {
  final ModuleIdentity moduleIdentity;
  final CurveType curveType;
  final List<Standard> standardsRemaining;
  final bool offline;

  Standard get standard => standardsRemaining.first;

  bool get done => standardsRemaining.isEmpty;

  CalibrationPointConfig({required this.moduleIdentity, required this.curveType, required this.standardsRemaining, this.offline = false});

  static CalibrationPointConfig fromTemplate(ModuleIdentity moduleIdentity, CalibrationTemplate template) {
    return CalibrationPointConfig(
        moduleIdentity: moduleIdentity, curveType: template.curveType, standardsRemaining: List.from(template.standards));
  }

  CalibrationPointConfig popStandard() {
    return CalibrationPointConfig(
        moduleIdentity: moduleIdentity, curveType: curveType, standardsRemaining: standardsRemaining.skip(1).toList());
  }

  static CalibrationPointConfig waterPh(ModuleIdentity moduleIdentity) =>
      CalibrationPointConfig.fromTemplate(moduleIdentity, CalibrationTemplate.waterPh());

  static CalibrationPointConfig waterDissolvedOxygen(ModuleIdentity moduleIdentity) =>
      CalibrationPointConfig.fromTemplate(moduleIdentity, CalibrationTemplate.waterDissolvedOxygen());

  static CalibrationPointConfig waterEc(ModuleIdentity moduleIdentity) =>
      CalibrationPointConfig.fromTemplate(moduleIdentity, CalibrationTemplate.waterEc());

  static CalibrationPointConfig waterTemp(ModuleIdentity moduleIdentity) =>
      CalibrationPointConfig.fromTemplate(moduleIdentity, CalibrationTemplate.waterTemp());

  static CalibrationPointConfig showCase(ModuleIdentity moduleIdentity) =>
      CalibrationPointConfig.fromTemplate(moduleIdentity, CalibrationTemplate.showCase());
}
