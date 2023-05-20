import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge_template/gen/ffi.dart';
import 'package:flutter_rust_bridge_template/meta.dart';
import 'package:flutter_rust_bridge_template/view_station/sensor_widgets.dart' as sensor_widgets;
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'countdown.dart';

class CalibrationPage extends StatelessWidget {
  final ModuleIdentity moduleIdentity;

  const CalibrationPage({super.key, required this.moduleIdentity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calibration"),
      ),
      body: ProvideCountdown(
          child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ReadingAndStandard(
                      moduleIdentity: moduleIdentity,
                    ),
                    const DisplayCountdown()
                  ]
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: e,
                          ))
                      .toList()))),
    );
  }
}

class ReadingAndStandard extends StatelessWidget {
  final ModuleIdentity moduleIdentity;

  const ReadingAndStandard({super.key, required this.moduleIdentity});

  @override
  Widget build(BuildContext context) {
    final knownStations = context.watch<KnownStationsModel>();
    final module = knownStations.findModule(moduleIdentity);
    final sensor = module?.calibrationSensor;
    if (sensor == null) {
      return const OopsBug();
    }

    final localized = LocalizedSensor.get(sensor);
    final sensorValue = sensor_widgets.SensorValue(sensor: sensor, localized: localized, mainAxisSize: MainAxisSize.min);
    return Column(children: [sensorValue]);
  }
}

class StartCalibration {
  final SensorConfig sensor;

  StartCalibration({required this.sensor});
}

class CurrentCalibration extends ChangeNotifier {}

class OopsBug extends StatelessWidget {
  const OopsBug({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text("Oops, bug!?");
  }
}
