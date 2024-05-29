import 'package:fk/common_widgets.dart';
import 'package:fk/constants.dart';
import 'package:fk/deploy/deploy_page.dart';
import 'package:fk/providers.dart';
import 'package:fk/view_station/module_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../gen/api.dart';

import '../app_state.dart';
import '../meta.dart';
import '../unknown_station_page.dart';
import 'configure_station.dart';

class ViewStationRoute extends StatelessWidget {
  final String deviceId;

  const ViewStationRoute({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Consumer<KnownStationsModel>(
      builder: (context, knownStations, child) {
        var station = knownStations.find(deviceId);
        if (station == null) {
          return const NoSuchStationPage();
        } else {
          return StationProviders(
              deviceId: deviceId, child: ViewStationPage(station: station));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ConfigureStationRoute(deviceId: station.deviceId),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context)!.configureButton,
                  style: const TextStyle(color: Colors.grey)))
        ],
      ),
      body: ListView(children: [
        HighLevelsDetails(station: station),
      ]),
    );
  }
}

class BatteryIndicator extends StatelessWidget {
  final bool enabled;
  final double level;

  const BatteryIndicator(
      {super.key, required this.enabled, required this.level});

  String icon() {
    final String prefix = enabled ? "normal" : "grayed";
    if (level >= 95) {
      return "resources/images/battery/${prefix}_100.png";
    }
    if (level >= 80) {
      return "resources/images/battery/${prefix}_80.png";
    }
    if (level >= 60) {
      return "resources/images/battery/${prefix}_60.png";
    }
    if (level >= 40) {
      return "resources/images/battery/${prefix}_40.png";
    }
    if (level >= 20) {
      return "resources/images/battery/${prefix}_20.png";
    }
    return "resources/images/battery/${prefix}_0.png";
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return ListTile(
        leading: Image.asset(icon(), cacheWidth: 16),
        title: Text(localizations.batteryLife),
        subtitle: Text("$level%"));
  }
}

class MemoryIndicator extends StatelessWidget {
  final bool enabled;
  final int bytesUsed;

  const MemoryIndicator(
      {super.key, required this.enabled, required this.bytesUsed});

  String icon() {
    if (enabled) {
      return "resources/images/memory/icon.png";
    }
    return "resources/images/memory/icon_gray.png";
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return ListTile(
        leading: Image.asset(icon(), cacheWidth: 16),
        title: Text(localizations.memoryUsage),
        subtitle: Text("${bytesUsed}b of 512MB"));
  }
}

class TimerCircle extends StatelessWidget {
  final bool enabled;
  final int? deployed;

  const TimerCircle({super.key, required this.enabled, required this.deployed});

  Color color() {
    if (enabled) {
      if (deployed == null) {
        return Colors.black;
      } else {
        return AppColors.logoBlue;
      }
    }
    return Colors.grey;
  }

  String label() {
    if (deployed == null) {
      return "00:00:00";
    } else {
      final deployed =
          DateTime.fromMillisecondsSinceEpoch(this.deployed! * 1000);
      final e = DateTime.now().toUtc().difference(deployed);
      final days = e.inDays;
      final hours = e.inHours - (days * 24);
      final minutes = e.inMinutes - (hours * 60);
      final paddedHours = hours.toString().padLeft(2, '0');
      final paddedMins = minutes.toString().padLeft(2, '0');
      return "$days:$paddedHours:$paddedMins";
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
        decoration: BoxDecoration(color: color(), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label(),
              style: const TextStyle(fontSize: 20, color: Colors.white)),
          Text(localizations.daysHoursMinutes,
              style: const TextStyle(fontSize: 12, color: Colors.white)),
        ]));
  }
}

class HighLevelsDetails extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const HighLevelsDetails({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final TasksModel tasks = context.watch<TasksModel>();
    final DeployTask? deployTask =
        tasks.getMaybeOne<DeployTask>(station.deviceId);

    final battery = config.battery.percentage;
    final bytesUsed = config.meta.size + config.data.size;

    final modules = config.modules.sorted(defaultModuleSorter).map((module) {
      return ModuleInfo(
        module: module,
        showSensors: true,
        alwaysShowCalibrate: false,
      );
    }).toList();

    return Flex(
      direction: Axis.vertical,
      children: [
        Container(
            padding: const EdgeInsets.only(top: 20),
            child: Row(children: [
              Expanded(
                  child: SizedBox(
                      height: 150,
                      child: TimerCircle(
                          enabled: station.connected,
                          deployed: station.ephemeral?.deployment?.startTime))),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  BatteryIndicator(enabled: station.connected, level: battery),
                  MemoryIndicator(
                      enabled: station.connected, bytesUsed: bytesUsed),
                ],
              ))
            ])),
        Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          child: ElevatedTextButton(
              onPressed: deployTask != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DeployStationRoute(deviceId: station.deviceId),
                        ),
                      );
                    }
                  : null,
              text: AppLocalizations.of(context)!.deployButton),
        ),
        Column(children: modules)
      ],
    );
  }
}
