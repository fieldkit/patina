import 'dart:math';
import 'package:fk_data_protocol/fk-data.pb.dart' as proto;

double _calibrateLinearValue(
    double x, List<proto.CalibrationPoint> calibration) {
  if (calibration.length < 2) {
    // Handle error: not enough calibration data
    return 0.0;
  }

  double a = calibration[0].uncalibrated[0];
  double b = calibration[1].uncalibrated[0];

  return a + b * x; // Apply linear calibration
}

double _calibrateExponentialValue(
    double x, List<proto.CalibrationPoint> calibration) {
  if (calibration.length < 3) {
    // Handle error: not enough calibration data
    return 0.0;
  }

  double a = calibration[0].uncalibrated[0];
  double b = calibration[1].uncalibrated[0];
  double c = calibration[2].uncalibrated[0];

  return a * exp(b * x) + c; // Apply exponential calibration
}

double calibrateValue(proto.CurveType curveType, double x,
    List<proto.CalibrationPoint> calibration) {
  switch (curveType) {
    case proto.CurveType.CURVE_LINEAR:
      return _calibrateLinearValue(x, calibration);
    case proto.CurveType.CURVE_EXPONENTIAL:
      return _calibrateExponentialValue(x, calibration);
    default:
      return 0.0;
  }
}
