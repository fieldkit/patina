import 'dart:math';

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
