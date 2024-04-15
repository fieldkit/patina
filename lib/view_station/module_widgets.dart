import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flows/flows.dart';
import 'package:fk/common_widgets.dart';
import 'package:fk/providers.dart';
import 'package:fk/view_station/sensor_widgets.dart';
import 'package:fk/app_state.dart';

import '../calibration/calibration_model.dart';
import '../calibration/calibration_page.dart';
import '../calibration/clear_calibration_page.dart';
import '../gen/api.dart';
import '../meta.dart';

class ModuleInfo extends StatelessWidget {
  final ModuleConfig module;
  final bool showSensors;
  final bool alwaysShowCalibrate;

  const ModuleInfo(
      {super.key,
      required this.module,
      required this.showSensors,
      required this.alwaysShowCalibrate});

  @override
  Widget build(BuildContext context) {
    final localized = LocalizedModule.get(module);
    final bay = AppLocalizations.of(context)!.bayNumber(module.position);
    final moduleConfigurations = context.watch<ModuleConfigurations>();
    final isCalibrated =
        moduleConfigurations.find(module.identity).isCalibrated;

    final List<Widget> sensors = showSensors
        ? module.sensors.sorted(defaultSensorSorter).map((sensor) {
            return SensorInfo(sensor: sensor);
          }).toList()
        : List<Widget>.empty();

    final Widget maybeCalibration =
        (localized.canCalibrate && (alwaysShowCalibrate || !isCalibrated))
            ? StartCalibrationButton(module: module)
            : const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromRGBO(212, 212, 212, 1),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(5))),
      child: Column(
        children: [
          ListTile(
              leading: Image(image: localized.icon),
              title: Text(localized.name),
              subtitle: Text(bay)),
          maybeCalibration,
          SensorsGrid(children: sensors),
        ],
      ),
    );
  }
}

class StartCalibrationButton extends StatelessWidget {
  final ModuleConfig module;

  const StartCalibrationButton({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final content = context.read<ContentFlows>();
    final moduleConfigurations = context.watch<ModuleConfigurations>();
    final isCalibrated =
        moduleConfigurations.find(module.identity).isCalibrated;

    return Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        child: ElevatedTextButton(
          onPressed: () {
            calibrationPage() {
              final config = CalibrationConfig.fromModule(module, content);
              if (isCalibrated) {
                return ClearCalibrationPage(config: config, module: module);
              } else {
                return CalibrationPage(config: config);
              }
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ModuleProviders(
                    moduleIdentity: module.identity, child: calibrationPage()),
              ),
            );
          },
          text: AppLocalizations.of(context)!.calibrateButton,
        ));
  }
}

int defaultSensorSorter(SensorConfig a, SensorConfig b) =>
    a.number.compareTo(b.number);

int defaultModuleSorter(ModuleConfig a, ModuleConfig b) {
  if (a.position == b.position) {
    return a.key.compareTo(b.key);
  }
  return a.position.compareTo(b.position);
}
