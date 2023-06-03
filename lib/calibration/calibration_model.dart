import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:flutter_rust_bridge_template/gen/ffi.dart';
import 'package:flutter_rust_bridge_template/meta.dart';

import '../app_state.dart';
import '../gen/fk-data.pb.dart' as proto;
import '../gen/bridge_definitions.dart';

class CalibrationPoint {
  final Standard standard;
  final SensorValue reading;

  CalibrationPoint({required this.standard, required this.reading});

  @override
  String toString() {
    return "CP($standard, ${reading.toDisplayString()})";
  }
}

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

List<double> exponentialCurve(List<CalibrationPoint> points) {
  /*
  final x = points.map((p) => p.reading.uncalibrated).toList();
  final y = points.map((p) => p.standard.value!).toList();

  function calibrationFunction([a, b, c]: [number, number, number]): (v: number) => number {
    return (t) => a + b * Math.exp(t * c);
  }

  // Pete 4/6/2022
  const options = {
      damping: 1.5,
      initialValues: _.clone([1000, 1500000, -7]),
      gradientDifference: 10e-2,
      maxIterations: 100,
      errorTolerance: 10e-3,
  };

  final fittedParams = levenbergMarquardt(data, calibrationFunction, options);
  const [a, b, c] = fittedParams.parameterValues;
  const coefficients = { a, b, c };
  */

  return [];
}

List<double> linearCurve(List<CalibrationPoint> points) {
  final n = points.length;
  final x = points.map((p) => p.reading.uncalibrated).toList();
  final y = points.map((p) => p.standard.value!).toList();

  final indices = List<int>.generate(n, (i) => i);
  final xMean = x.average;
  final yMean = y.average;
  final numerParts = indices.map((i) => (x[i] - xMean) * (y[i] - yMean));
  final denomParts = indices.map((i) => pow((x[i] - xMean), 2));
  final numer = numerParts.sum;
  final denom = denomParts.sum;

  final m = numer / denom;
  final b = yMean - m * xMean;

  return [b, m];
}

class CurrentCalibration {
  final proto.CurveType curveType;
  final List<CalibrationPoint> _points = List.empty(growable: true);

  CurrentCalibration({required this.curveType});

  @override
  String toString() => _points.toString();

  void addPoint(CalibrationPoint point) {
    _points.add(point);
  }

  proto.Calibration toDataProtocol() {
    final time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cps = _points
        .map((p) =>
            proto.CalibrationPoint(references: [p.standard.value!], uncalibrated: [p.reading.uncalibrated], factory: [p.reading.value]))
        .toList();
    final coefficients = calculateCoefficients();
    return proto.Calibration(time: time, type: curveType, points: cps, coefficients: proto.CalibrationCoefficients(values: coefficients));
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

abstract class Standard {
  bool get acceptable;

  double? get value;
}

class FixedStandard extends Standard {
  final double _value;

  FixedStandard(this._value);

  @override
  String toString() => "FixedStandard($_value)";

  @override
  bool get acceptable => true;

  @override
  double get value => _value;
}

class UnknownStandard extends Standard {
  @override
  String toString() => "Unknown()";

  @override
  bool get acceptable => false;

  @override
  double? get value => null;
}

class UserStandard extends Standard {
  final double _value;

  UserStandard(this._value);

  @override
  String toString() => "UserStandard($_value)";

  @override
  bool get acceptable => true;

  @override
  double get value => _value;
}
