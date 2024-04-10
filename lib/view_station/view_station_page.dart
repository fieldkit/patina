import 'package:fk/common_widgets.dart';
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

    final circle = Container(
        decoration:
            const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Text(
          "00:00:00",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ));

    return Flex(
      direction: Axis.vertical,
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
                      leading: Image.asset(
                          "resources/images/battery/normal_40.png",
                          cacheWidth: 16),
                      title: Text(AppLocalizations.of(context)!.batteryLife),
                      subtitle: Text("$battery%")),
                  ListTile(
                      leading: Image.asset("resources/images/memory/icon.png",
                          cacheWidth: 16),
                      title: Text(AppLocalizations.of(context)!.memoryUsage),
                      subtitle: Text("${bytesUsed}b of 512MB")),
                ],
              ))
            ])),
        if (deployTask != null)
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            child: ElevatedTextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DeployStationRoute(deviceId: station.deviceId),
                    ),
                  );
                },
                text: AppLocalizations.of(context)!.deployButton),
          ),
        Column(children: modules)
      ],
    );
  }
}
