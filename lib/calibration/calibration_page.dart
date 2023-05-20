import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge_template/gen/ffi.dart';
import 'package:flutter_rust_bridge_template/meta.dart';
import 'package:flutter_rust_bridge_template/view_station/sensor_widgets.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'countdown.dart';

class CalibrationPage extends StatelessWidget {
  final CurrentCalibration? current;
  final CalibrationPointConfig config;

  const CalibrationPage({super.key, this.current, required this.config});

  Future<void> calibrateAndContinue(BuildContext context, SensorConfig sensor) async {
    final current = this.current ?? CurrentCalibration();
    final standard = config.standard!;

    current.addPoint(CalibrationPoint(standard: standard, reading: sensor.value!));

    debugPrint("calibration: $current");

    final nextConfig = config.popStandard();
    if (nextConfig.done) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CalibrationPage(
            config: nextConfig,
            current: current,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final knownStations = context.watch<KnownStationsModel>();
    final module = knownStations.findModule(config.moduleIdentity);
    final sensor = module?.calibrationSensor;
    if (sensor == null) {
      return const OopsBug();
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text("Calibration"),
        ),
        body: ProvideCountdown(
            child: CalibrationWait(
                config: config, sensor: sensor, canContinue: true, onCalibrateAndContinue: () => calibrateAndContinue(context, sensor))));
  }
}

class CalibrationWait extends StatelessWidget {
  final CalibrationPointConfig config;
  final SensorConfig sensor;
  final VoidCallback onCalibrateAndContinue;
  final bool canContinue;

  const CalibrationWait(
      {super.key, required this.config, required this.sensor, required this.onCalibrateAndContinue, required this.canContinue});

  @override
  Widget build(BuildContext context) {
    final children = [
      ReadingAndStandard(
        sensor: sensor,
        standard: config.standard!,
      ),
      const DisplayCountdown(),
      ElevatedButton(onPressed: canContinue ? () => onCalibrateAndContinue() : null, child: const Text("Calibrate"))
    ];

    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: e,
                    ))
                .toList()));
  }
}

class ReadingAndStandard extends StatelessWidget {
  final SensorConfig sensor;
  final Standard standard;

  const ReadingAndStandard({super.key, required this.sensor, required this.standard});

  @override
  Widget build(BuildContext context) {
    final localized = LocalizedSensor.get(sensor);
    final sensorValue = DisplaySensorValue(sensor: sensor, localized: localized, mainAxisSize: MainAxisSize.min);
    return Column(children: [
      sensorValue,
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromRGBO(212, 212, 212, 1),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(5))),
            padding: const EdgeInsets.all(8),
            child: Text(
              "${standard.value} Standard Value (${sensor.calibratedUom})",
            ),
          ))
    ]);
  }
}

class CalibrationPoint {
  final Standard standard;
  final SensorValue reading;

  CalibrationPoint({required this.standard, required this.reading});

  @override
  String toString() {
    return "CP($standard, ${reading.toDisplayString()})";
  }
}

class CurrentCalibration {
  final List<CalibrationPoint> _points = List.empty(growable: true);

  void addPoint(CalibrationPoint point) {
    _points.add(point);
  }

  @override
  String toString() => _points.toString();
}

class CalibrationPointConfig {
  final ModuleIdentity moduleIdentity;
  final List<Standard> standardsRemaining;

  Standard? get standard => standardsRemaining.first;

  bool get done => standardsRemaining.isEmpty;

  CalibrationPointConfig({required this.moduleIdentity, required this.standardsRemaining});

  CalibrationPointConfig popStandard() {
    return CalibrationPointConfig(moduleIdentity: moduleIdentity, standardsRemaining: standardsRemaining.skip(1).toList());
  }
}

class Standard {
  final double value;

  Standard(this.value);

  @override
  String toString() => "Standard($value)";
}

class OopsBug extends StatelessWidget {
  const OopsBug({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text("Oops, bug!?");
  }
}
