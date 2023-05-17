import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'gen/ffi.dart';

import 'app_state.dart';

class ViewStationRoute extends StatelessWidget {
  final String deviceId;

  const ViewStationRoute({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    debugPrint("view-station-route:build");
    return Consumer<KnownStationsModel>(
      builder: (context, knownStations, child) {
        debugPrint("view-station-route:build-children");
        var station = knownStations.find(deviceId);
        if (station == null) {
          return const NoSuchStationPage();
        } else {
          return ViewStationPage(station: station);
        }
      },
    );
  }
}

class ViewStationPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const ViewStationPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    // DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
        // bottom: const PreferredSize(preferredSize: Size.zero, child: Text("Ready to deploy")),
      ),
      body: ListView(children: [
        HighLevelsDetails(station: station),
      ]),
    );
  }
}

class HighLevelsDetails extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const HighLevelsDetails({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final modules = config.modules.sorted((a, b) => a.position.compareTo(b.position)).map((module) {
      return ModuleInfo(module: module);
    }).toList();

    var circle = Container(
        decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Text(
          "00:00:00",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ));
    return Column(
      children: [
        Container(
            padding: const EdgeInsets.only(top: 20),
            child: Row(children: [
              Expanded(child: SizedBox(height: 150, child: circle)),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ListTile(
                      leading: Image.asset("resources/images/battery/normal_40.png", cacheWidth: 16),
                      title: const Text("Battery Life"),
                      subtitle: const Text("98%")),
                  ListTile(
                      leading: Image.asset("resources/images/memory/icon.png", cacheWidth: 16),
                      title: const Text("Memory"),
                      subtitle: const Text("586KB of 512MB")),
                ],
              ))
            ])),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ElevatedButton(onPressed: () {}, child: const Text("Deploy")),
        ),
        Column(children: modules)
      ],
    );
  }
}

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

extension ListSorted<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) => [...this]..sort(compare);
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
          SensorsGrid(children: sensors),
        ]));
  }
}

class NoSuchStationPage extends StatelessWidget {
  const NoSuchStationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Which station?"),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Back'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class LocalizedModule {
  String name;
  AssetImage icon;

  LocalizedModule({required this.name, required this.icon});

  static LocalizedModule get(ModuleConfig module) {
    switch (module.key) {
      case "modules.water.temp":
        return LocalizedModule(icon: const AssetImage("resources/images/icon_module_water_temp.png"), name: "Water Temperature Module");
      case "modules.water.ph":
        return LocalizedModule(icon: const AssetImage("resources/images/icon_module_water_ph.png"), name: "pH Module");
      case "modules.water.orp":
        return LocalizedModule(icon: const AssetImage("resources/images/icon_module_water_orp.png"), name: "ORP Module");
      case "modules.water.do":
        return LocalizedModule(icon: const AssetImage("resources/images/icon_module_water_do.png"), name: "Dissolved Oxygen Module");
      case "modules.water.ec":
        return LocalizedModule(icon: const AssetImage("resources/images/icon_module_water_ec.png"), name: "Conductivity Module");
      case "modules.weather":
        return LocalizedModule(icon: const AssetImage("resources/images/icon_module_weather.png"), name: "Weather Module");
      case "modules.diagnostics":
        return LocalizedModule(icon: const AssetImage("resources/images/icon_module_generic.png"), name: "Diagnostics Module");
      case "modules.random":
        return LocalizedModule(icon: const AssetImage("resources/images/icon_module_generic.png"), name: "Random Module");
      default:
        debugPrint("Unknown module key: ${module.key}");
        return LocalizedModule(icon: const AssetImage("resources/images/icon_module_generic.png"), name: "Unknown Module");
    }
  }
}

class LocalizedSensor {
  String name;
  String uom;

  LocalizedSensor({required this.name, required this.uom});

  static LocalizedSensor get(SensorConfig sensor) {
    switch (sensor.fullKey) {
      case "modules.water.temp.temp":
        return LocalizedSensor(name: "Water Temperature", uom: sensor.calibratedUom);
      case "modules.water.ph.ph":
        return LocalizedSensor(name: "pH", uom: sensor.calibratedUom);
      case "modules.water.ec.ec":
        return LocalizedSensor(name: "Conductivity", uom: sensor.calibratedUom);
      case "modules.water.do.do":
        return LocalizedSensor(name: "Dissolved Oxygen", uom: sensor.calibratedUom);
      case "modules.water.orp.orp":
        return LocalizedSensor(name: "ORP", uom: sensor.calibratedUom);
      case "modules.diagnostics.battery_charge":
        return LocalizedSensor(name: "Battery", uom: sensor.calibratedUom);
      case "modules.diagnostics.battery_voltage":
        return LocalizedSensor(name: "Battery", uom: sensor.calibratedUom);
      case "modules.diagnostics.temperature":
        return LocalizedSensor(name: "Internal Temperature", uom: sensor.calibratedUom);
      case "modules.diagnostics.uptime":
        return LocalizedSensor(name: "Uptime", uom: sensor.calibratedUom);
      case "modules.diagnostics.memory":
        return LocalizedSensor(name: "Memory", uom: sensor.calibratedUom);
      case "modules.random.random_0":
        return LocalizedSensor(name: "Random 0", uom: sensor.calibratedUom);
      case "modules.random.random_1":
        return LocalizedSensor(name: "Random 1", uom: sensor.calibratedUom);
      case "modules.random.random_2":
        return LocalizedSensor(name: "Random 2", uom: sensor.calibratedUom);
      case "modules.random.random_3":
        return LocalizedSensor(name: "Random 3", uom: sensor.calibratedUom);
      default:
        debugPrint("Unknown sensor key: ${sensor.fullKey}");
        return LocalizedSensor(name: sensor.fullKey, uom: sensor.calibratedUom);
    }
  }
}
