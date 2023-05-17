import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../gen/ffi.dart';
import '../unknown_station_page.dart';

class ConfigureStationRoute extends StatelessWidget {
  final String deviceId;

  const ConfigureStationRoute({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Consumer<KnownStationsModel>(
      builder: (context, knownStations, child) {
        var station = knownStations.find(deviceId);
        if (station == null) {
          return const NoSuchStationPage();
        } else {
          return ConfigureStationPage(station: station);
        }
      },
    );
  }
}

class ConfigureStationPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const ConfigureStationPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: ListView(children: [
        ListTile(
          title: const Text("General"),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          title: const Text("Networks"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConfigureNetworksPage(
                  station: station,
                ),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          title: const Text("Firmware"),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          title: const Text("Modules"),
          onTap: () {},
        ),
        const Divider(),
      ]),
    );
  }
}

class ConfigureNetworksPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const ConfigureNetworksPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: ListView(children: [
        ListTile(
          title: const Text("WiFi"),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          title: const Text("LoRa"),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          title: const Text("Automatic Upload"),
          onTap: () {},
        ),
        const Divider(),
      ]),
    );
  }
}
