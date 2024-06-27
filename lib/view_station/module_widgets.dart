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
    final StationConfiguration station = context.watch<StationConfiguration>();
    final localizations = AppLocalizations.of(context)!;
    final localized = LocalizedModule.get(module, localizations);
    final bay = localizations.bayNumber(module.position);
    final moduleConfigurations = context.watch<ModuleConfigurations>();
    final isCalibrated =
        moduleConfigurations.find(module.identity).isCalibrated;

    final List<Widget> sensors = showSensors
        ? module.sensors.sorted(defaultSensorSorter).map((sensor) {
            return SensorInfo(
              sensor: sensor,
              isConnected: station.config.connected,
            );
          }).toList()
        : List<Widget>.empty();

    final Widget maybeCalibration =
        (localized.canCalibrate && (alwaysShowCalibrate || !isCalibrated))
            ? StartCalibrationButton(module: module, stationName: station.name)
            : const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromRGBO(212, 212, 212, 1),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(2))),
      child: Column(
        children: [
          ListTile(
              leading: Image(
                  image: station.config.connected
                      ? localized.icon
                      : localized.iconGray),
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
  final String stationName;

  const StartCalibrationButton(
      {super.key, required this.module, required this.stationName});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final content = context.read<ContentFlows>();
    final ModuleConfigurations moduleConfigurations =
        context.watch<ModuleConfigurations>();
    final StationConfiguration station = context.watch<StationConfiguration>();
    final isCalibrated =
        moduleConfigurations.find(module.identity).isCalibrated;

    return Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        child: ElevatedTextButton(
          onPressed: station.config.connected
              ? () {
                  calibrationPage() {
                    final config = CalibrationConfig.fromModule(
                        module, localizations, content);
                    if (isCalibrated) {
                      return ClearCalibrationPage(
                        config: config,
                        module: module,
                        stationName: stationName,
                      );
                    } else {
                      return CalibrationPage(
                        config: config,
                        stationName: stationName,
                      );
                    }
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ModuleProviders(
                          moduleIdentity: module.identity,
                          child: calibrationPage()),
                    ),
                  );
                }
              : null,
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
