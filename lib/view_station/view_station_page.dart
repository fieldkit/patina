import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../gen/ffi.dart';

import '../app_state.dart';
import '../meta.dart';
import '../unknown_station_page.dart';
import 'configure_station.dart';
import 'sensor_widgets.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfigureStationRoute(deviceId: station.deviceId),
                  ),
                );
              },
              child: const Text("Configure", style: TextStyle(color: Colors.white)))
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
    final battery = config.battery.percentage;
    final bytesUsed = config.meta.size + config.data.size;

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
                      subtitle: Text("$battery%")),
                  ListTile(
                      leading: Image.asset("resources/images/memory/icon.png", cacheWidth: 16),
                      title: const Text("Memory"),
                      subtitle: Text("$bytesUsed bytes of 512MB")),
                ],
              ))
            ])),
        Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          child: ElevatedButton(onPressed: () {}, child: const Text("Deploy")),
        ),
        Column(children: modules)
      ],
    );
  }
}
