import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
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
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsGeneral),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.settingsNetworks),
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
          ConfigureAutomaticUploadListItem(station: station),
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
          ListTile(
            title: Text(AppLocalizations.of(context)!.endDeployment),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.forgetStation),
            onTap: () {},
          ),
        ],
      ),
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

class ConfigureAutomaticUploadListItem extends StatelessWidget {
  final StationModel station;

  const ConfigureAutomaticUploadListItem({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
        ConfigureAutomaticUploadListItem(station: station),
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
    final StationConfiguration configuration =
        context.watch<AppState>().configuration;

    Loggers.ui.i("station $station $config");

    final enabled = station.ephemeral?.transmission?.enabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: WH.padPage(Column(children: [
        if (!enabled)
          WH.align(WH.vertical(ElevatedButton(
              onPressed: () async {
                Loggers.ui.i("wifi-upload:enable");
                await configuration.enableWifiUploading(station.deviceId);
              },
              child: const Text("Enable")))),
        if (enabled)
          WH.align(WH.vertical(ElevatedButton(
              onPressed: () async {
                Loggers.ui.i("wifi-upload:disable");
                await configuration.disableWifiUploading(station.deviceId);
              },
              child: const Text("Disable"))))
      ])),
    );
  }
}
