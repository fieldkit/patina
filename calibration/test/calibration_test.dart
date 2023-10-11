import 'package:calibration/calibration.dart';
import 'package:test/test.dart';

void main() {
  group('Calibration', () {
    test('Linear Curves', () {
      final coefficients = linearCurve([
        CalibrationPoint(standard: FixedStandard(4), reading: SensorReading(uncalibrated: 1.148333333, value: 0)),
        CalibrationPoint(standard: FixedStandard(7), reading: SensorReading(uncalibrated: 1.015666667, value: 0)),
        CalibrationPoint(standard: FixedStandard(10), reading: SensorReading(uncalibrated: 0.874, value: 0)),
      ].toList());

      expect(coefficients[0], closeTo(29.14029507863275, 0.0001));
      expect(coefficients[1], closeTo(-21.863359195489874, 0.0001));
    });

    test('Exponential Curves', () {
      final coefficients = exponentialCurve([
        CalibrationPoint(standard: FixedStandard(1000), reading: SensorReading(uncalibrated: 1.338, value: 0)),
        CalibrationPoint(standard: FixedStandard(10000), reading: SensorReading(uncalibrated: 0.676, value: 0)),
        CalibrationPoint(standard: FixedStandard(100000), reading: SensorReading(uncalibrated: 0.402, value: 0)),
      ].toList());

      expect(coefficients[0], closeTo(972.2996588725804, 0.0001));
      expect(coefficients[1], closeTo(3325515.352862578, 0.0001));
      expect(coefficients[2], closeTo(-8.741243398914417, 0.0001));
    });
  });
}
