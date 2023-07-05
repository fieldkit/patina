import 'dart:math';

import 'package:data/data.dart';

class SensorReading {
  final double uncalibrated;
  final double value;

  SensorReading({required this.uncalibrated, required this.value});

  String toDisplayString() {
    return "Reading($value, $uncalibrated)";
  }
}

class CalibrationPoint {
  final Standard standard;
  final SensorReading reading;

  CalibrationPoint({required this.standard, required this.reading});

  @override
  String toString() {
    return "CP($standard, ${reading.toDisplayString()})";
  }
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

List<double> exponentialCurve(List<CalibrationPoint> points) {
  ParametrizedUnaryFunction<double> fn = ParametrizedUnaryFunction.list(DataType.float, 3, (params) {
    return (double t) {
      return params[0] + params[1] * exp(t * params[2]);
    };
  });

  // Pete 4/6/2022
  final lm = LevenbergMarquardt(fn,
      initialValues: [1000.0, 1500000.0, -7.0].toVector(),
      gradientDifference: 10e-2,
      maxIterations: 100,
      errorTolerance: 10e-3,
      damping: 1.5);

  final xs = points.map((p) => p.reading.uncalibrated).toVector();
  final ys = points.map((p) => p.standard.value!).toVector();

  final v = lm.fit(xs: xs, ys: ys);

  return v.parameters;
}

List<double> linearCurve(List<CalibrationPoint> points) {
  final n = points.length;
  final x = points.map((p) => p.reading.uncalibrated).toList();
  final y = points.map((p) => p.standard.value!).toList();

  final indices = List<int>.generate(n, (i) => i);
  final xMean = x.average();
  final yMean = y.average();
  final numerParts = indices.map((i) => (x[i] - xMean) * (y[i] - yMean));
  final denomParts = indices.map((i) => pow((x[i] - xMean), 2));
  final numer = numerParts.sum();
  final denom = denomParts.sum();

  final m = numer / denom;
  final b = yMean - m * xMean;

  return [b, m];
}
