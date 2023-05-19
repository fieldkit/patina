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
      body: ProvideModuleByIdentity(
          moduleIdentity: moduleIdentity,
          child: ProvideCountdown(
              child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [const ReadingAndStandard(), const DisplayCountdown()]
                          .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: e,
                              ))
                          .toList())))),
    );
  }
}

class ReadingAndStandard extends StatelessWidget {
  const ReadingAndStandard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ModuleConfig>(builder: (context, module, child) {
      final sensor = module.calibrationSensor;
      if (sensor == null) {
        return const OopsBug();
      } else {
        final localized = LocalizedSensor.get(sensor);
        final sensorValue = sensor_widgets.SensorValue(sensor: sensor, localized: localized, mainAxisSize: MainAxisSize.min);
        return Column(children: [sensorValue, Text(module.key)]);
      }
    });
  }
}

class ProvideModuleByIdentity extends StatelessWidget {
  final ModuleIdentity moduleIdentity;
  final Widget child;

  const ProvideModuleByIdentity({super.key, required this.moduleIdentity, required this.child});

  @override
  Widget build(BuildContext context) {
    final knownStations = context.watch<KnownStationsModel>();
    final module = knownStations.findModule(moduleIdentity);
    if (module == null) {
      return const OopsBug();
    } else {
      return Provider<ModuleConfig>(
        create: (context) => module,
        dispose: (context, value) => {},
        child: child,
      );
    }
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
