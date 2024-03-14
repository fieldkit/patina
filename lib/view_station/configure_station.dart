import 'package:fk/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../gen/ffi.dart';
import '../unknown_station_page.dart';

import 'configure_lora.dart';
import 'configure_wifi_networks.dart';
import 'firmware_page.dart';
import 'station_events.dart';

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
          return StationProviders(
              deviceId: deviceId,
              child: ConfigureStationPage(station: station));
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
        title: Text(AppLocalizations.of(context)!.settingsTitle),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 0),
              Text(config.name),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          /*
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsGeneral),
            onTap: () {},
          ),
          const Divider(),
          */
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsWifi),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StationProviders(
                      deviceId: station.deviceId,
                      child: ConfigureWiFiPage(
                        station: station,
                      )),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsLora),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StationProviders(
                      deviceId: station.deviceId,
                      child: const ConfigureLoraPage()),
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
                  builder: (context) => StationProviders(
                      deviceId: station.deviceId,
                      child: StationFirmwarePage(
                        station: station,
                      )),
                ),
              );
            },
          ),
          const Divider(),
          /*
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsModules),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.endDeployment),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.forgetStation),
            onTap: () {},
          ),
          const Divider(),
          */
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsEvents),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StationProviders(
                      deviceId: station.deviceId,
                      child: const ViewStationEventsPage()),
                ),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
