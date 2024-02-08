import 'package:fk/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:fk/app_state.dart';
import 'package:provider/provider.dart';

import '../calibration/calibration_model.dart';
import '../calibration/calibration_page.dart';
import '../calibration/clear_calibration_page.dart';
import '../gen/ffi.dart';
import '../meta.dart';
import 'package:fk/constants.dart';

class DisplaySensorValue extends StatelessWidget {
  final SensorConfig sensor;
  final LocalizedSensor localized;
  final MainAxisSize mainAxisSize;

  const DisplaySensorValue(
      {super.key,
      required this.sensor,
      required this.localized,
      this.mainAxisSize = MainAxisSize.max});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double valueSize = screenWidth < 360 ? 18 : 24;
    double unitsSize = screenWidth < 360 ? 10 : 12;

    var valueFormatter = NumberFormat("0.##");
    var valueStyle = TextStyle(
      fontSize: valueSize,
      color: AppColors.primaryColor,
      fontWeight: FontWeight.bold,
    );
    var unitsStyle = TextStyle(
      fontSize: unitsSize,
      color: const Color.fromRGBO(64, 64, 64, 1),
      fontWeight: FontWeight.normal,
    );
    var value = sensor.value?.value;
    var uom = localized.uom;

    var suffix = Container(
        padding: const EdgeInsets.only(left: 4),
        child: Text(uom, style: unitsStyle));

    if (value == null) {
      return Row(
          mainAxisSize: mainAxisSize,
          children: [Text("--", style: valueStyle), suffix]);
    }
    return Row(mainAxisSize: mainAxisSize, children: [
      Text(valueFormatter.format(value), style: valueStyle),
      suffix
    ]);
  }
}

class SensorInfo extends StatelessWidget {
  final SensorConfig sensor;

  const SensorInfo({super.key, required this.sensor});

  @override
  Widget build(BuildContext context) {
    final localized = LocalizedSensor.get(sensor);

    return Container(
        padding: const EdgeInsets.all(10),
        child: ColoredBox(
            color: const Color.fromRGBO(232, 232, 232, 1),
            child: Container(
                padding: const EdgeInsets.all(6),
                child: Column(children: [
                  Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DisplaySensorValue(
                          sensor: sensor, localized: localized)),
                  Text(
                    localized.name,
                    textAlign: TextAlign.left,
                  )
                ]))));
  }
}

class SensorsGrid extends StatelessWidget {
  final List<Widget> children;

  const SensorsGrid({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double boxSize = screenWidth < 240 ? screenWidth : (screenWidth / 2.3);

    return Wrap(
      alignment: WrapAlignment.start,
      children: children.map((child) {
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(
            width: boxSize,
            child: child,
          ),
        );
      }).toList(),
    );
  }
}

int defaultSensorSorter(SensorConfig a, SensorConfig b) {
  return a.number.compareTo(b.number);
}

class ModuleInfo extends StatelessWidget {
  final ModuleConfig module;

  const ModuleInfo({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final moduleConfigurations = context.watch<ModuleConfigurations>();
    final localized = LocalizedModule.get(module);
    final bay = AppLocalizations.of(context)!.bayNumber(module.position);

    final List<Widget> sensors =
        module.sensors.sorted(defaultSensorSorter).map((sensor) {
      return SensorInfo(sensor: sensor);
    }).toList();

    final Widget maybeCalibration = localized.canCalibrate
        ? Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                calibrationPage() {
                  final config = CalibrationPointConfig.fromTemplate(
                      module.identity, localized.calibrationTemplate!);
                  if (moduleConfigurations.find(module.identity).isCalibrated) {
                    return ClearCalibrationPage(config: config, module: module);
                  } else {
                    return CalibrationPage(config: config);
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
              },
              // style: ElevatedButton.styleFrom(),
              child: Text(AppLocalizations.of(context)!.calibrateButton),
            ))
        : const SizedBox.shrink();

    return Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromRGBO(212, 212, 212, 1),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: Column(children: [
          ListTile(
              leading: Image(image: localized.icon),
              title: Text(localized.name),
              subtitle: Text(bay)),
          maybeCalibration,
          SensorsGrid(children: sensors),
        ]));
  }
}
