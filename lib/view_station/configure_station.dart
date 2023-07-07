import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
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

class FirmwareComparison {
  final String label;
  final DateTime time;
  final DateTime otherTime;
  final bool newer;

  FirmwareComparison({required this.label, required this.time, required this.otherTime, required this.newer});

  factory FirmwareComparison.compare(LocalFirmware local, FirmwareInfo station) {
    final other = DateTime.fromMillisecondsSinceEpoch(station.time * 1000);
    final time = DateTime.fromMillisecondsSinceEpoch(local.time);
    return FirmwareComparison(label: local.label, time: time, otherTime: other, newer: time.isAfter(other));
  }
}

class UpgradeProgressWidget extends StatelessWidget {
  final UpgradeOperation operation;

  const UpgradeProgressWidget({super.key, required this.operation});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final status = operation.status;
    if (status is UpgradeStatus_Starting) {
      return Column(children: [
        WH.progressBar(0.0),
        WH.padBelowProgress(const Text("Starting...")),
      ]);
    }
    if (status is UpgradeStatus_Uploading) {
      return Column(children: [
        WH.progressBar(status.field0.completed),
        WH.padBelowProgress(Text(localizations.syncWorking)),
      ]);
    }
    if (status is UpgradeStatus_Restarting) {
      return const Text("Restarting...");
    }
    if (status is UpgradeStatus_Completed) {
      return const Text("Completed");
    }
    if (status is UpgradeStatus_Failed) {
      return const Text("Failed");
    }
    return const SizedBox.shrink();
  }
}

class StationFirmwarePage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const StationFirmwarePage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final localFirmware = context.watch<LocalFirmwareModel>();
    final items = localFirmware.firmware.where((firmware) => firmware.module == "fk-core").map((firmware) {
      final operations =
          context.watch<StationOperations>().getAll<UpgradeOperation>(config.deviceId).where((op) => op.firmwareId == firmware.id);
      final comparison = FirmwareComparison.compare(firmware, config.firmware);
      final title = comparison.label;
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:MM:SS');
      // debugPrint("${comparison.time} > ${comparison.otherTime} = ${comparison.newer} (${comparison.label} vs ${config.firmware.label})");

      GenericListItemHeader header() {
        if (comparison.newer) {
          return GenericListItemHeader(title: title, subtitle: formatter.format(comparison.time));
        } else {
          return GenericListItemHeader(
            title: title,
            subtitle: formatter.format(comparison.time),
            titleStyle: const TextStyle(color: Colors.grey),
            subtitleStyle: const TextStyle(color: Colors.grey),
          );
        }
      }

      pad(child) => Container(width: double.infinity, padding: const EdgeInsets.all(10), child: child);

      return BorderedListItem(
          header: header(),
          expanded: comparison.newer,
          children: [
            ElevatedButton(
                onPressed: () async {
                  await localFirmware.upgrade(config.deviceId, firmware);
                },
                child: const Text("Upgrade")),
            ...operations.map((operation) => UpgradeProgressWidget(operation: operation))
          ].map((child) => pad(child)).toList());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Firmware"),
      ),
      body: ListView(
        children: items,
      ),
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
