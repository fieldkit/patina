import 'package:caldor/calibration.dart';
import 'package:flutter/material.dart';

import 'diagnostics.dart';
import 'gen/ffi.dart';

class LocalizedModule {
  String key;
  String name;
  AssetImage icon;

  CalibrationTemplate? get calibrationTemplate =>
      CalibrationTemplate.forModuleKey(key);

  bool get canCalibrate => calibrationTemplate != null;

  LocalizedModule({required this.key, required this.name, required this.icon});

  static LocalizedModule get(ModuleConfig module) {
    switch (module.key) {
      case "modules.water.temp":
        return LocalizedModule(
            key: module.key,
            icon:
                const AssetImage("resources/images/icon_module_water_temp.png"),
            name: "Water Temperature Module");
      case "modules.water.ph":
        return LocalizedModule(
            key: module.key,
            icon: const AssetImage("resources/images/icon_module_water_ph.png"),
            name: "pH Module");
      case "modules.water.orp":
        return LocalizedModule(
            key: module.key,
            icon:
                const AssetImage("resources/images/icon_module_water_orp.png"),
            name: "ORP Module");
      case "modules.water.do":
        return LocalizedModule(
            key: module.key,
            icon: const AssetImage("resources/images/icon_module_water_do.png"),
            name: "Dissolved Oxygen Module");
      case "modules.water.ec":
        return LocalizedModule(
            key: module.key,
            icon: const AssetImage("resources/images/icon_module_water_ec.png"),
            name: "Conductivity Module");
      case "modules.water.depth":
        return LocalizedModule(
            key: module.key,
            icon: const AssetImage("resources/images/icon_module_generic.png"),
            name: "Water Depth Module");
      case "modules.weather":
        return LocalizedModule(
            key: module.key,
            icon: const AssetImage("resources/images/icon_module_weather.png"),
            name: "Weather Module");
      case "modules.diagnostics":
        return LocalizedModule(
            key: module.key,
            icon: const AssetImage("resources/images/icon_module_generic.png"),
            name: "Diagnostics Module");
      case "modules.random":
        return LocalizedModule(
            key: module.key,
            icon: const AssetImage("resources/images/icon_module_generic.png"),
            name: "Random Module");
      case "modules.distance":
        return LocalizedModule(
            key: module.key,
            icon: const AssetImage("resources/images/icon_module_generic.png"),
            name: "Distance Module");
      default:
        Loggers.main.e("Unknown module key: ${module.key}");
        return LocalizedModule(
            key: module.key,
            icon: const AssetImage("resources/images/icon_module_generic.png"),
            name: "Unknown Module");
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
        return LocalizedSensor(
            name: "Water Temperature", uom: sensor.calibratedUom);
      case "modules.water.ph.ph":
        return LocalizedSensor(name: "pH", uom: sensor.calibratedUom);
      case "modules.water.ec.ec":
        return LocalizedSensor(name: "Conductivity", uom: sensor.calibratedUom);
      case "modules.water.do.do":
        return LocalizedSensor(
            name: "Dissolved Oxygen", uom: sensor.calibratedUom);
      case "modules.water.do.pressure":
        return LocalizedSensor(name: "Air Pressure", uom: sensor.calibratedUom);
      case "modules.water.do.temperature":
        return LocalizedSensor(
            name: "Air Temperature", uom: sensor.calibratedUom);
      case "modules.water.orp.orp":
        return LocalizedSensor(name: "ORP", uom: sensor.calibratedUom);

      case "modules.water.depth.temp":
        return LocalizedSensor(
            name: "Water Temperature", uom: sensor.calibratedUom);
      case "modules.water.depth.depth":
        return LocalizedSensor(
            name: "Water Depth (Pressure)", uom: sensor.calibratedUom);

      case "modules.diagnostics.temperature":
        return LocalizedSensor(
            name: "Internal Temperature", uom: sensor.calibratedUom);
      case "modules.diagnostics.uptime":
        return LocalizedSensor(name: "Uptime", uom: sensor.calibratedUom);
      case "modules.diagnostics.memory":
        return LocalizedSensor(name: "Memory", uom: sensor.calibratedUom);
      case "modules.diagnostics.free_memory":
        return LocalizedSensor(name: "Free Memory", uom: sensor.calibratedUom);

      case "modules.diagnostics.battery_charge":
        return LocalizedSensor(name: "Battery", uom: sensor.calibratedUom);
      case "modules.diagnostics.battery_voltage":
        return LocalizedSensor(name: "Battery", uom: sensor.calibratedUom);

      case "modules.diagnostics.battery_vbus":
        return LocalizedSensor(
            name: "Battery (VBus)", uom: sensor.calibratedUom);
      case "modules.diagnostics.battery_vs":
        return LocalizedSensor(name: "Battery (Vs)", uom: sensor.calibratedUom);
      case "modules.diagnostics.battery_ma":
        return LocalizedSensor(name: "Battery (ma)", uom: sensor.calibratedUom);
      case "modules.diagnostics.battery_power":
        return LocalizedSensor(
            name: "Battery (Power)", uom: sensor.calibratedUom);

      case "modules.diagnostics.solar_vbus":
        return LocalizedSensor(name: "Solar (VBus)", uom: sensor.calibratedUom);
      case "modules.diagnostics.solar_vs":
        return LocalizedSensor(name: "Solar (Vs)", uom: sensor.calibratedUom);
      case "modules.diagnostics.solar_ma":
        return LocalizedSensor(name: "Solar (ma)", uom: sensor.calibratedUom);
      case "modules.diagnostics.solar_power":
        return LocalizedSensor(
            name: "Solar (Power)", uom: sensor.calibratedUom);

      case "modules.weather.rain":
        return LocalizedSensor(name: "Rain", uom: sensor.calibratedUom);
      case "modules.weather.wind_speed":
        return LocalizedSensor(name: "Wind Speed", uom: sensor.calibratedUom);
      case "modules.weather.wind_direction":
        return LocalizedSensor(
            name: "Wind Direction", uom: sensor.calibratedUom);
      case "modules.weather.humidity":
        return LocalizedSensor(name: "Humidity", uom: sensor.calibratedUom);
      case "modules.weather.temperature_1":
        return LocalizedSensor(
            name: "Temperature 1", uom: sensor.calibratedUom);
      case "modules.weather.temperature_2":
        return LocalizedSensor(
            name: "Temperature 2", uom: sensor.calibratedUom);
      case "modules.weather.pressure":
        return LocalizedSensor(name: "Pressure", uom: sensor.calibratedUom);
      case "modules.weather.wind_dir":
        return LocalizedSensor(
            name: "Wind Direction", uom: sensor.calibratedUom);
      case "modules.weather.wind_dir_mv":
        return LocalizedSensor(
            name: "Wind Direction Raw ADC", uom: sensor.calibratedUom);
      case "modules.weather.wind_hr_max_speed":
        return LocalizedSensor(
            name: "Wind Max Speed (1 hour)", uom: sensor.calibratedUom);
      case "wind_hr_max_dir":
        return LocalizedSensor(
            name: "Wind Max Direction (1 hour)", uom: sensor.calibratedUom);
      case "modules.weather.wind_10m_max_speed":
        return LocalizedSensor(
            name: "Wind Max Speed (10 minutes)", uom: sensor.calibratedUom);
      case "modules.weather.wind_10m_max_dir":
        return LocalizedSensor(
            name: "Wind Max Direction (10 minutes)", uom: sensor.calibratedUom);
      case "modules.weather.wind_2m_avg_speed":
        return LocalizedSensor(
            name: "Wind Average Speed (2 minutes)", uom: sensor.calibratedUom);
      case "modules.weather.wind_2m_avg_dir":
        return LocalizedSensor(
            name: "Wind Average Direction (2 minutes)",
            uom: sensor.calibratedUom);
      case "modules.weather.rain_this_hour":
        return LocalizedSensor(
            name: "Rain This Hour", uom: sensor.calibratedUom);
      case "modules.weather.rain_prev_hour":
        return LocalizedSensor(
            name: "Rain Previous Hour", uom: sensor.calibratedUom);
      case "modules.weather.wind_hr_max_dir":
        return LocalizedSensor(
            name: "Wind Max Speed (1 Hour)", uom: sensor.calibratedUom);

      case "modules.distance.distance_0":
        return LocalizedSensor(name: "Distance 0", uom: sensor.calibratedUom);
      case "modules.distance.distance_1":
        return LocalizedSensor(name: "Distance 1", uom: sensor.calibratedUom);
      case "modules.distance.distance_2":
        return LocalizedSensor(name: "Distance 2", uom: sensor.calibratedUom);

      case "modules.random.random_0":
        return LocalizedSensor(name: "Random 0", uom: sensor.calibratedUom);
      case "modules.random.random_1":
        return LocalizedSensor(name: "Random 1", uom: sensor.calibratedUom);
      case "modules.random.random_2":
        return LocalizedSensor(name: "Random 2", uom: sensor.calibratedUom);
      case "modules.random.random_3":
        return LocalizedSensor(name: "Random 3", uom: sensor.calibratedUom);
      case "modules.random.random_4":
        return LocalizedSensor(name: "Random 4", uom: sensor.calibratedUom);
      case "modules.random.random_5":
        return LocalizedSensor(name: "Random 5", uom: sensor.calibratedUom);
      case "modules.random.random_6":
        return LocalizedSensor(name: "Random 6", uom: sensor.calibratedUom);
      case "modules.random.random_7":
        return LocalizedSensor(name: "Random 7", uom: sensor.calibratedUom);
      case "modules.random.random_8":
        return LocalizedSensor(name: "Random 8", uom: sensor.calibratedUom);
      default:
        Loggers.main.e("Unknown sensor key: ${sensor.fullKey}");
        return LocalizedSensor(name: sensor.fullKey, uom: sensor.calibratedUom);
    }
  }
}

extension ListSorted<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) => [...this]..sort(compare);
}

extension StringOverrides on SensorValue {
  String toDisplayString() {
    return "Reading($value, $uncalibrated)";
  }
}
