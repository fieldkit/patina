import 'package:flutter/material.dart';

import 'gen/ffi.dart';

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

extension ListSorted<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) => [...this]..sort(compare);
}
