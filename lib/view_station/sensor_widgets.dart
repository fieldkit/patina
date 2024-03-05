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
  final bool isConnected;
  final double? previousValue;

  const DisplaySensorValue(
      {super.key,
      required this.sensor,
      required this.localized,
      this.mainAxisSize = MainAxisSize.max,
      this.isConnected = true,
      this.previousValue});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double valueSize = screenWidth < 360 ? 18 : 24;
    double unitsSize = screenWidth < 360 ? 10 : 12;

    var valueFormatter = NumberFormat("0.##");
    var valueStyle = TextStyle(
      fontSize: valueSize,
      color: Colors.black54,
      fontWeight: FontWeight.w500,
    );
    var unitsStyle = TextStyle(
      fontSize: unitsSize,
      color: isConnected ? const Color.fromRGBO(64, 64, 64, 1) : Colors.grey,
      fontWeight: FontWeight.normal,
    );
    var value = sensor.value?.value;
    var uom = localized.uom;

    // Determine the direction of the value change
    Widget changeIcon = const SizedBox.shrink();
    if (previousValue != null && value != null) {
      if (value > previousValue!) {
        // Value is rising
        changeIcon = const Icon(Icons.arrow_upward, color: Colors.blue);
      } else if (value < previousValue!) {
        // Value is falling
        changeIcon = const Icon(Icons.arrow_downward, color: Colors.red);
      } else {
        // Value is unchanged, nothing
      }
    }

    var suffix = Container(
        padding: const EdgeInsets.only(left: 4),
        child: Text(uom, style: unitsStyle));

    if (value == null || !isConnected) {
      return Row(mainAxisSize: mainAxisSize, children: [
        Text("--", style: valueStyle),
        suffix,
        if (!isConnected)
          Text(" (Last reading)",
              style: TextStyle(fontSize: unitsSize, color: Colors.grey)),
      ]);
    }
    return Row(mainAxisSize: mainAxisSize, children: [
      Text(valueFormatter.format(value), style: valueStyle),
      suffix,
      changeIcon
    ]);
  }
}

class SensorInfo extends StatelessWidget {
  final SensorConfig sensor;
  final bool isConnected;

  const SensorInfo({
    super.key,
    required this.sensor,
    this.isConnected = true,
  });

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DisplaySensorValue(
                              sensor: sensor,
                              localized: localized,
                              isConnected: isConnected,
                              previousValue: sensor.previousValue?.value)),
                      Text(localized.name)
                    ]))));
  }
}

class SensorsGrid extends StatelessWidget {
  final List<Widget> children;

  const SensorsGrid({super.key, required this.children});

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

int defaultSensorSorter(SensorConfig a, SensorConfig b) =>
    a.number.compareTo(b.number);

class ModuleInfo extends StatefulWidget {
  final ModuleConfig module;

  const ModuleInfo({super.key, required this.module});

  @override
  State<ModuleInfo> createState() => _ModuleInfoState();
}

class _ModuleInfoState extends State<ModuleInfo> {
  bool _isExpanded = true; // Default state is expanded

  @override
  Widget build(BuildContext context) {
    final localized = LocalizedModule.get(widget.module);
    final bay = AppLocalizations.of(context)!.bayNumber(widget.module.position);

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
            trailing: IconButton(
              icon: _isExpanded
                  ? const Icon(
                      Icons.keyboard_arrow_up,
                      size: 30,
                      color: Colors.black54,
                    )
                  : const Icon(
                      Icons.keyboard_arrow_down,
                      size: 30,
                      color: Colors.black54,
                    ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ),
          if (_isExpanded) ...[
            // Calibration button and sensors grid are only shown if expanded
            _buildCalibrationButton(context, localized, widget.module),
            SensorsGrid(children: _buildSensorWidgets(widget.module.sensors)),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSensorWidgets(List<SensorConfig> sensors) {
    return sensors.map((sensor) {
      return SensorInfo(sensor: sensor);
    }).toList();
  }

  Widget _buildCalibrationButton(
      BuildContext context, LocalizedModule localized, ModuleConfig module) {
    if (!localized.canCalibrate) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    _calibrationPage(context, localized, module)),
          );
        },
        child: Text(AppLocalizations.of(context)!.calibrateButton),
      ),
    );
  }

  Widget _calibrationPage(
      BuildContext context, LocalizedModule localized, ModuleConfig module) {
    final moduleConfigurations = context.read<AppState>().moduleConfigurations;
    final config = CalibrationPointConfig.fromTemplate(
        module.identity, localized.calibrationTemplate!);

    return moduleConfigurations.find(module.identity).isCalibrated
        ? ClearCalibrationPage(config: config, module: module)
        : CalibrationPage(config: config);
  }
}
