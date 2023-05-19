import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../gen/ffi.dart';
import '../meta.dart';

class SensorValue extends StatelessWidget {
  final SensorConfig sensor;
  final LocalizedSensor localized;

  const SensorValue({super.key, required this.sensor, required this.localized});

  @override
  Widget build(BuildContext context) {
    var valueFormatter = NumberFormat("0.##", "en_US");
    var valueStyle = const TextStyle(
      fontSize: 18,
      color: Colors.red,
      fontWeight: FontWeight.bold,
    );
    var unitsStyle = const TextStyle(
      fontSize: 18,
      color: Color.fromRGBO(64, 64, 64, 1),
      fontWeight: FontWeight.normal,
    );
    var value = sensor.value?.value;
    var uom = localized.uom;

    var suffix = Container(padding: const EdgeInsets.only(left: 6), child: Text(uom, style: unitsStyle));

    if (value == null) {
      return Row(children: [Text("--", style: valueStyle), suffix]);
    }
    return Row(children: [Text(valueFormatter.format(value), style: valueStyle), suffix]);
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
                  Container(padding: const EdgeInsets.only(bottom: 8), child: SensorValue(sensor: sensor, localized: localized)),
                  Row(children: [Text(localized.name)])
                ]))));
  }
}

class SensorsGrid extends StatelessWidget {
  final List<Widget> children;

  const SensorsGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final List<TableRow> rows = List.empty(growable: true);
    final iter = children.iterator;
    while (true) {
      final List<Widget> columns = List.empty(growable: true);
      var finished = false;
      if (iter.moveNext()) {
        columns.add(iter.current);
        if (iter.moveNext()) {
          columns.add(iter.current);
        } else {
          columns.add(Container());
          finished = true;
        }

        rows.add(TableRow(children: columns));
      } else {
        finished = true;
      }

      if (finished) {
        break;
      }
    }

    return Table(children: rows);
  }
}

class ModuleInfo extends StatelessWidget {
  final ModuleConfig module;

  const ModuleInfo({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final localized = LocalizedModule.get(module);
    final bay = "Bay ${module.position}";

    final List<Widget> sensors = module.sensors.sorted((a, b) => a.number.compareTo(b.number)).map((sensor) {
      return SensorInfo(sensor: sensor);
    }).toList();

    return Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromRGBO(212, 212, 212, 1),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: Column(children: [
          ListTile(leading: Image(image: localized.icon), title: Text(localized.name), subtitle: Text(bay)),
          Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                // style: ElevatedButton.styleFrom(),
                child: const Text("Calibrate"),
              )),
          SensorsGrid(children: sensors),
        ]));
  }
}