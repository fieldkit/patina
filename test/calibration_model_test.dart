import 'package:fk/calibration/calibration_model.dart';
import 'package:fk/gen/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calibration', () {
    test('Linear Curves', () {
      final coefficients = linearCurve([
        CalibrationPoint(standard: FixedStandard(4), reading: SensorValue(uncalibrated: 1.148333333, value: 0, time: DateTime.now())),
        CalibrationPoint(standard: FixedStandard(7), reading: SensorValue(uncalibrated: 1.015666667, value: 0, time: DateTime.now())),
        CalibrationPoint(standard: FixedStandard(10), reading: SensorValue(uncalibrated: 0.874, value: 0, time: DateTime.now())),
      ].toList());

      expect(coefficients[0], moreOrLessEquals(29.14029507863275));
      expect(coefficients[1], moreOrLessEquals(-21.863359195489874));
    });

    test('Exponential Curves', () {
      final coefficients = exponentialCurve([
        CalibrationPoint(standard: FixedStandard(1000), reading: SensorValue(uncalibrated: 1.338, value: 0, time: DateTime.now())),
        CalibrationPoint(standard: FixedStandard(10000), reading: SensorValue(uncalibrated: 0.676, value: 0, time: DateTime.now())),
        CalibrationPoint(standard: FixedStandard(100000), reading: SensorValue(uncalibrated: 0.402, value: 0, time: DateTime.now())),
      ].toList());

      expect(coefficients[0], moreOrLessEquals(972.2996588725804));
      expect(coefficients[1], moreOrLessEquals(3325515.352862578));
      expect(coefficients[2], moreOrLessEquals(-8.741243398914417));
    });
  });
}
