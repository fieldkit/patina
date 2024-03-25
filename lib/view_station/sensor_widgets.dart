import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fk/constants.dart';

import '../gen/ffi.dart';
import '../meta.dart';

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

    final valueFormatter = NumberFormat("0.##");
    final valueStyle = TextStyle(
      fontSize: valueSize,
      color: AppColors.primaryColor,
      fontWeight: FontWeight.bold,
    );
    final unitsStyle = TextStyle(
      fontSize: unitsSize,
      color: const Color.fromRGBO(64, 64, 64, 1),
      fontWeight: FontWeight.normal,
    );
    final value = sensor.value?.value;
    final uom = localized.uom;

    final suffix = Container(
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
