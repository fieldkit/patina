import 'package:calibration/calibration.dart';
import 'package:flutter/foundation.dart';

import '../app_state.dart';
import '../gen/fk-data.pb.dart' as proto;

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

enum CalibrationKind {
  none,
}

class CurrentCalibration {
  final proto.CurveType curveType;
  final CalibrationKind kind;
  final List<CalibrationPoint> _points = List.empty(growable: true);

  CurrentCalibration({required this.curveType, this.kind = CalibrationKind.none});

  @override
  String toString() => _points.toString();

  void addPoint(CalibrationPoint point) {
    _points.add(point);
  }

  proto.ModuleConfiguration toDataProtocol() {
    final time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cps = _points
        .map((p) =>
            proto.CalibrationPoint(references: [p.standard.value!], uncalibrated: [p.reading.uncalibrated], factory: [p.reading.value]))
        .toList();
    final coefficients = calculateCoefficients();
    final calibration = proto.Calibration(
        time: time, kind: kind.index, type: curveType, points: cps, coefficients: proto.CalibrationCoefficients(values: coefficients));
    return proto.ModuleConfiguration(calibrations: [calibration]);
  }

  List<double> calculateCoefficients() {
    return linearCurve(_points);
  }

  Uint8List toBytes() {
    return toDataProtocol().writeToBuffer();
  }
}

class CalibrationPointConfig {
  final ModuleIdentity moduleIdentity;
  final proto.CurveType curveType;
  final List<Standard> standardsRemaining;
  final bool offline;

  Standard get standard => standardsRemaining.first;

  bool get done => standardsRemaining.isEmpty;

  CalibrationPointConfig({required this.moduleIdentity, required this.curveType, required this.standardsRemaining, this.offline = false});

  CalibrationPointConfig popStandard() {
    return CalibrationPointConfig(
        moduleIdentity: moduleIdentity, curveType: curveType, standardsRemaining: standardsRemaining.skip(1).toList());
  }

  static CalibrationPointConfig waterPh(ModuleIdentity moduleIdentity) => CalibrationPointConfig(
      moduleIdentity: moduleIdentity,
      curveType: proto.CurveType.CURVE_LINEAR,
      standardsRemaining: [FixedStandard(4), FixedStandard(7), FixedStandard(10)]);

  static CalibrationPointConfig waterDissolvedOxygen(ModuleIdentity moduleIdentity) => CalibrationPointConfig(
      moduleIdentity: moduleIdentity,
      curveType: proto.CurveType.CURVE_LINEAR,
      standardsRemaining: [UnknownStandard(), UnknownStandard(), UnknownStandard()]);

  static CalibrationPointConfig waterEc(ModuleIdentity moduleIdentity) => CalibrationPointConfig(
      moduleIdentity: moduleIdentity,
      curveType: proto.CurveType.CURVE_EXPONENTIAL,
      standardsRemaining: [UnknownStandard(), UnknownStandard(), UnknownStandard()]);

  static CalibrationPointConfig waterTemp(ModuleIdentity moduleIdentity) => CalibrationPointConfig(
      moduleIdentity: moduleIdentity,
      curveType: proto.CurveType.CURVE_EXPONENTIAL,
      standardsRemaining: [UnknownStandard(), UnknownStandard(), UnknownStandard()]);

  static CalibrationPointConfig showCase(ModuleIdentity moduleIdentity) => CalibrationPointConfig(
      moduleIdentity: moduleIdentity, curveType: proto.CurveType.CURVE_LINEAR, standardsRemaining: [UnknownStandard(), FixedStandard(10)]);
}
