import 'package:caldor/calibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'diagnostics.dart';
import 'gen/api.dart';

class LocalizedModule {
  String key;
  String name;
  AssetImage icon;
  AssetImage iconGray;

  CalibrationTemplate? get calibrationTemplate =>
      CalibrationTemplate.forModuleKey(key);

  bool get canCalibrate => calibrationTemplate != null;

  LocalizedModule(
      {required this.key,
      required this.name,
      required this.icon,
      required this.iconGray});

  static LocalizedModule get(
      ModuleConfig module, AppLocalizations localizations) {
    switch (module.key) {
      case "modules.water.temp":
        return LocalizedModule(
          key: module.key,
          name: localizations.modulesWaterTemp,
          icon: const AssetImage("resources/images/icon_module_water_temp.png"),
          iconGray: const AssetImage(
              "resources/images/icon_module_water_temp_gray.png"),
        );
      case "modules.water.ph":
        return LocalizedModule(
          key: module.key,
          name: localizations.modulesWaterPh,
          icon: const AssetImage("resources/images/icon_module_water_ph.png"),
          iconGray: const AssetImage(
              "resources/images/icon_module_water_ph_gray.png"),
        );
      case "modules.water.orp":
        return LocalizedModule(
          key: module.key,
          name: localizations.modulesWaterOrp,
          icon: const AssetImage("resources/images/icon_module_water_orp.png"),
          iconGray: const AssetImage(
              "resources/images/icon_module_water_orp_gray.png"),
        );
      case "modules.water.do":
        return LocalizedModule(
          key: module.key,
          name: localizations.modulesWaterDo,
          icon: const AssetImage("resources/images/icon_module_water_do.png"),
          iconGray: const AssetImage(
              "resources/images/icon_module_water_do_gray.png"),
        );
      case "modules.water.ec":
        return LocalizedModule(
          key: module.key,
          name: localizations.modulesWaterEc,
          icon: const AssetImage("resources/images/icon_module_water_ec.png"),
          iconGray: const AssetImage(
              "resources/images/icon_module_water_ec_gray.png"),
        );
      case "modules.water.depth":
        return LocalizedModule(
          key: module.key,
          name: localizations.modulesWaterDepth,
          icon: const AssetImage("resources/images/icon_module_generic.png"),
          iconGray:
              const AssetImage("resources/images/icon_module_generic_gray.png"),
        );
      case "modules.weather":
        return LocalizedModule(
          key: module.key,
          name: localizations.modulesWeather,
          icon: const AssetImage("resources/images/icon_module_weather.png"),
          iconGray:
              const AssetImage("resources/images/icon_module_weather_gray.png"),
        );
      case "modules.diagnostics":
        return LocalizedModule(
          key: module.key,
          name: localizations.modulesDiagnostics,
          icon: const AssetImage("resources/images/icon_module_generic.png"),
          iconGray:
              const AssetImage("resources/images/icon_module_generic_gray.png"),
        );
      case "modules.random":
        return LocalizedModule(
          key: module.key,
          name: localizations.modulesRandom,
          icon: const AssetImage("resources/images/icon_module_generic.png"),
          iconGray:
              const AssetImage("resources/images/icon_module_generic_gray.png"),
        );
      case "modules.distance":
        return LocalizedModule(
          key: module.key,
          name: localizations.modulesDistance,
          icon: const AssetImage("resources/images/icon_module_generic.png"),
          iconGray:
              const AssetImage("resources/images/icon_module_generic_gray.png"),
        );
      default:
        Loggers.main.e("Unknown module key: ${module.key}");
        return LocalizedModule(
          key: module.key,
          name: localizations.modulesUnknown,
          icon: const AssetImage("resources/images/icon_module_generic.png"),
          iconGray:
              const AssetImage("resources/images/icon_module_generic_gray.png"),
        );
    }
  }
}

class LocalizedSensor {
  String name;
  String uom;

  LocalizedSensor({required this.name, required this.uom});

  static LocalizedSensor get(
      SensorConfig sensor, AppLocalizations localizations) {
    switch (sensor.fullKey) {
      case "modules.water.temp.temp":
        return LocalizedSensor(
            name: localizations.sensorWaterTemperature,
            uom: sensor.calibratedUom);
      case "modules.water.ph.ph":
        return LocalizedSensor(
            name: localizations.sensorWaterPh, uom: sensor.calibratedUom);
      case "modules.water.ec.ec":
        return LocalizedSensor(
            name: localizations.sensorWaterEc, uom: sensor.calibratedUom);
      case "modules.water.do.do":
        return LocalizedSensor(
            name: localizations.sensorWaterDo, uom: sensor.calibratedUom);
      case "modules.water.do.pressure":
        return LocalizedSensor(
            name: localizations.sensorWaterDoPressure,
            uom: sensor.calibratedUom);
      case "modules.water.do.temperature":
        return LocalizedSensor(
            name: localizations.sensorWaterDoTemperature,
            uom: sensor.calibratedUom);
      case "modules.water.orp.orp":
        return LocalizedSensor(
            name: localizations.sensorWaterOrp, uom: sensor.calibratedUom);

      case "modules.water.depth.temp":
        return LocalizedSensor(
            name: localizations.sensorWaterDepthTemperature,
            uom: sensor.calibratedUom);
      case "modules.water.depth.depth":
        return LocalizedSensor(
            name: localizations.sensorWaterDepthPressure,
            uom: sensor.calibratedUom);

      case "modules.diagnostics.temperature":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsTemperature,
            uom: sensor.calibratedUom);
      case "modules.diagnostics.uptime":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsUptime,
            uom: sensor.calibratedUom);
      case "modules.diagnostics.memory":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsMemory,
            uom: sensor.calibratedUom);
      case "modules.diagnostics.free_memory":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsFreeMemory,
            uom: sensor.calibratedUom);

      case "modules.diagnostics.battery_charge":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsBatteryCharge,
            uom: sensor.calibratedUom);
      case "modules.diagnostics.battery_voltage":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsBatteryVoltage,
            uom: sensor.calibratedUom);

      case "modules.diagnostics.battery_vbus":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsBatteryVBus,
            uom: sensor.calibratedUom);
      case "modules.diagnostics.battery_vs":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsBatteryVs,
            uom: sensor.calibratedUom);
      case "modules.diagnostics.battery_ma":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsBatteryMa,
            uom: sensor.calibratedUom);
      case "modules.diagnostics.battery_power":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsBatteryPower,
            uom: sensor.calibratedUom);

      case "modules.diagnostics.solar_vbus":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsSolarVBus,
            uom: sensor.calibratedUom);
      case "modules.diagnostics.solar_vs":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsSolarVs,
            uom: sensor.calibratedUom);
      case "modules.diagnostics.solar_ma":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsSolarMa,
            uom: sensor.calibratedUom);
      case "modules.diagnostics.solar_power":
        return LocalizedSensor(
            name: localizations.sensorDiagnosticsSolarPower,
            uom: sensor.calibratedUom);

      case "modules.weather.rain":
        return LocalizedSensor(
            name: localizations.sensorWeatherRain, uom: sensor.calibratedUom);
      case "modules.weather.wind_speed":
        return LocalizedSensor(
            name: localizations.sensorWeatherWindSpeed,
            uom: sensor.calibratedUom);
      case "modules.weather.wind_direction":
        return LocalizedSensor(
            name: localizations.sensorWeatherWindDirection,
            uom: sensor.calibratedUom);
      case "modules.weather.humidity":
        return LocalizedSensor(
            name: localizations.sensorWeatherHumidity,
            uom: sensor.calibratedUom);
      case "modules.weather.temperature_1":
        return LocalizedSensor(
            name: localizations.sensorWeatherTemperature1,
            uom: sensor.calibratedUom);
      case "modules.weather.temperature_2":
        return LocalizedSensor(
            name: localizations.sensorWeatherTemperature2,
            uom: sensor.calibratedUom);
      case "modules.weather.pressure":
        return LocalizedSensor(
            name: localizations.sensorWeatherPressure,
            uom: sensor.calibratedUom);
      case "modules.weather.wind_dir":
        return LocalizedSensor(
            name: localizations.sensorWeatherWindDir,
            uom: sensor.calibratedUom);
      case "modules.weather.wind_dir_mv":
        return LocalizedSensor(
            name: localizations.sensorWeatherWindDirMv,
            uom: sensor.calibratedUom);
      case "modules.weather.wind_hr_max_speed":
        return LocalizedSensor(
            name: localizations.sensorWeatherWindHrMaxSpeed,
            uom: sensor.calibratedUom);
      case "wind_hr_max_dir":
        return LocalizedSensor(
            name: localizations.sensorWeatherWindHrMaxDir,
            uom: sensor.calibratedUom);
      case "modules.weather.wind_10m_max_speed":
        return LocalizedSensor(
            name: localizations.sensorWeatherWind10mMaxSpeed,
            uom: sensor.calibratedUom);
      case "modules.weather.wind_10m_max_dir":
        return LocalizedSensor(
            name: localizations.sensorWeatherWind10mMaxDir,
            uom: sensor.calibratedUom);
      case "modules.weather.wind_2m_avg_speed":
        return LocalizedSensor(
            name: localizations.sensorWeatherWind2mAvgSpeed,
            uom: sensor.calibratedUom);
      case "modules.weather.wind_2m_avg_dir":
        return LocalizedSensor(
            name: localizations.sensorWeatherWind2mAvgDir,
            uom: sensor.calibratedUom);
      case "modules.weather.rain_this_hour":
        return LocalizedSensor(
            name: localizations.sensorWeatherRainThisHour,
            uom: sensor.calibratedUom);
      case "modules.weather.rain_prev_hour":
        return LocalizedSensor(
            name: localizations.sensorWeatherRainPrevHour,
            uom: sensor.calibratedUom);
      case "modules.weather.wind_hr_max_dir":
        return LocalizedSensor(
            name: localizations.sensorWeatherWindHrMaxDir,
            uom: sensor.calibratedUom);

      case "modules.distance.distance_0":
        return LocalizedSensor(
            name: localizations.sensorDistanceDistance0,
            uom: sensor.calibratedUom);
      case "modules.distance.distance_1":
        return LocalizedSensor(
            name: localizations.sensorDistanceDistance1,
            uom: sensor.calibratedUom);
      case "modules.distance.distance_2":
        return LocalizedSensor(
            name: localizations.sensorDistanceDistance2,
            uom: sensor.calibratedUom);
      case "modules.distance.calibration":
        return LocalizedSensor(
            name: localizations.sensorDistanceCalibration,
            uom: sensor.calibratedUom);

      case "modules.random.random_0":
        return LocalizedSensor(
            name: localizations.sensorRandomRandom0, uom: sensor.calibratedUom);
      case "modules.random.random_1":
        return LocalizedSensor(
            name: localizations.sensorRandomRandom1, uom: sensor.calibratedUom);
      case "modules.random.random_2":
        return LocalizedSensor(
            name: localizations.sensorRandomRandom2, uom: sensor.calibratedUom);
      case "modules.random.random_3":
        return LocalizedSensor(
            name: localizations.sensorRandomRandom3, uom: sensor.calibratedUom);
      case "modules.random.random_4":
        return LocalizedSensor(
            name: localizations.sensorRandomRandom4, uom: sensor.calibratedUom);
      case "modules.random.random_5":
        return LocalizedSensor(
            name: localizations.sensorRandomRandom5, uom: sensor.calibratedUom);
      case "modules.random.random_6":
        return LocalizedSensor(
            name: localizations.sensorRandomRandom6, uom: sensor.calibratedUom);
      case "modules.random.random_7":
        return LocalizedSensor(
            name: localizations.sensorRandomRandom7, uom: sensor.calibratedUom);
      case "modules.random.random_8":
        return LocalizedSensor(
            name: localizations.sensorRandomRandom8, uom: sensor.calibratedUom);
      case "modules.random.random_9":
        return LocalizedSensor(
            name: localizations.sensorRandomRandom9, uom: sensor.calibratedUom);
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
