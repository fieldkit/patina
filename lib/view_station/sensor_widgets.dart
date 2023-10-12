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

class DisplaySensorValue extends StatelessWidget {
  final SensorConfig sensor;
  final LocalizedSensor localized;
  final MainAxisSize mainAxisSize;

  static const _valueStyle = TextStyle(
    fontSize: 22,
    color: Color.fromRGBO(112, 112, 112, 1),
    fontWeight: FontWeight.normal,
    fontFamily: "Avenir",
  );

  const DisplaySensorValue({
    super.key,
    required this.sensor,
    required this.localized,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    final valueFormatter = NumberFormat("0.##");
    final value = sensor.value?.value;
    final uom = localized.uom;

    final suffix = Container(
      padding: const EdgeInsets.only(left: 6, top: 4),
      child: Text(uom, style: _valueStyle.copyWith(fontSize: 12)),
    );

    return Row(
      mainAxisSize: mainAxisSize,
      children: [
        Text(value == null ? "--" : valueFormatter.format(value),
            style: _valueStyle),
        suffix
      ],
    );
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
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                child: DisplaySensorValue(
                  sensor: sensor,
                  localized: localized,
                  mainAxisSize: MainAxisSize.max,
                ),
              ),
              Row(children: [Text(localized.name)])
            ],
          ),
        ),
      ),
    );
  }
}

class SensorsGrid extends StatelessWidget {
  final List<Widget> children;

  const SensorsGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Table(children: _generateRows());
  }

  List<TableRow> _generateRows() {
    final List<TableRow> rows = [];
    for (int i = 0; i < children.length; i += 2) {
      rows.add(TableRow(
        children: [
          children[i],
          if (i + 1 < children.length) children[i + 1] else Container(),
        ],
      ));
    }
    return rows;
  }
}

int defaultSensorSorter(SensorConfig a, SensorConfig b) =>
    a.number.compareTo(b.number);

class ModuleInfo extends StatelessWidget {
  final ModuleConfig module;

  const ModuleInfo({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final localized = LocalizedModule.get(module);
    final bay = AppLocalizations.of(context)!.bayNumber(module.position);

    final sensors = module.sensors
        .sorted(defaultSensorSorter)
        .map((sensor) => SensorInfo(sensor: sensor))
        .toList();

    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(212, 212, 212, 1)),
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Image(image: localized.icon),
            title: Text(localized.name),
            subtitle: Text(bay),
          ),
          _buildCalibrationButton(context, localized),
          SensorsGrid(children: sensors),
        ],
      ),
    );
  }

  Widget _buildCalibrationButton(
      BuildContext context, LocalizedModule localized) {
    if (!localized.canCalibrate) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => _calibrationPage(context, localized)),
          );
        },
        child: Text(AppLocalizations.of(context)!.calibrateButton),
      ),
    );
  }

  Widget _calibrationPage(BuildContext context, LocalizedModule localized) {
    final moduleConfigurations = context.read<AppState>().moduleConfigurations;
    final config = CalibrationPointConfig.fromTemplate(
        module.identity, localized.calibrationTemplate!);

    return moduleConfigurations.find(module.identity).isCalibrated
        ? ClearCalibrationPage(config: config)
        : CalibrationPage(config: config);
  }
}
