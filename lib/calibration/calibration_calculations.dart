import 'dart:math';
import 'package:fk_data_protocol/fk-data.pb.dart' as proto;

List<Map<String, double>> createLinearCurve(List<double> calibration,
    {int numPoints = 100}) {
  var points = <Map<String, double>>[];

  if (calibration.length < 2) {
    // Handle error: not enough calibration data
    return points;
  }

  double a = calibration[0];
  double b = calibration[1];

  // Define the range of x values
  double xMin = 0; // adjust as needed
  double xMax = 10; // adjust as needed
  double xStep = (xMax - xMin) / (numPoints - 1);

  for (int i = 0; i < numPoints; i++) {
    double x = xMin + i * xStep;
    double y = a + b * x; // Linear equation
    points.add({'x': x, 'y': y});
  }

  return points;
}

List<Map<String, double>> createExponentialCurve(List<double> calibration,
    {int numPoints = 100}) {
  var points = <Map<String, double>>[];

  if (calibration.length < 3) {
    // Handle error: not enough calibration data
    return points;
  }

  double a = calibration[0];
  double b = calibration[1];
  double c = calibration[2];

  // Define the range of x values
  double xMin = 0; // adjust as needed
  double xMax = 10; // adjust as needed
  double xStep = (xMax - xMin) / (numPoints - 1);

  for (int i = 0; i < numPoints; i++) {
    double x = xMin + i * xStep;
    double y = a * exp(b * x) + c; // Exponential equation
    points.add({'x': x, 'y': y});
  }

  return points;
}

double _calibrateLinearValue(
    double x, List<proto.CalibrationPoint> calibration) {
  if (calibration.length < 2) {
    // Handle error: not enough calibration data
    return 0.0;
  }

  double a = calibration[0].uncalibrated[0]; // TODO Jacob, is this right?
  double b = calibration[1].uncalibrated[0]; // Especially the last [0]?

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
