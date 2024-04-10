import 'package:fk/providers.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../gen/api.dart';
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

    final valueFormatter = NumberFormat("0.##");
    final valueStyle = TextStyle(
      fontSize: valueSize,
      color: Colors.black54,
      fontWeight: FontWeight.w500,
    );
    final unitsStyle = TextStyle(
      fontSize: unitsSize,
      color: isConnected ? const Color.fromRGBO(64, 64, 64, 1) : Colors.grey,
      fontWeight: FontWeight.normal,
    );
    final value = sensor.value?.value;
    final uom = localized.uom;

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

    final suffix = Container(
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
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double width = constraints.maxWidth;
      double boxSize = width < 240 ? width : (width / 2.0);

      return Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            alignment: WrapAlignment.start,
            children: children.map((child) {
              return SizedBox(
                width: boxSize,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: child,
                ),
              );
            }).toList(),
          ));
    });
  }
}
