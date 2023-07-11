import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../gen/ffi.dart';
import '../unknown_station_page.dart';

import 'firmware_page.dart';

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
          title: Text(AppLocalizations.of(context)!.settingsGeneral),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          title: Text(AppLocalizations.of(context)!.settingsNetwork),
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
          title: Text(AppLocalizations.of(context)!.settingsFirmware),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StationFirmwarePage(
                  station: station,
                ),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          title: Text(AppLocalizations.of(context)!.settingsModules),
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
          title: Text(AppLocalizations.of(context)!.settingsWifi),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConfigureWiFiPage(
                  station: station,
                ),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          title: Text(AppLocalizations.of(context)!.settingsLora),
          onTap: () {},
        ),
        const Divider(),
      ]),
    );
  }
}

class ConfigureWiFiPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const ConfigureWiFiPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: ListView(children: [
        ListTile(
          title: Text(AppLocalizations.of(context)!.settingsAutomaticUpload),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConfigureAutomaticUploadPage(
                  station: station,
                ),
              ),
            );
          },
        ),
        const Divider(),
      ]),
    );
  }
}

class ConfigureAutomaticUploadPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const ConfigureAutomaticUploadPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: const Column(children: []),
    );
  }
}
