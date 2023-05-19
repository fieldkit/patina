import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../gen/ffi.dart';

class DataSyncTab extends StatelessWidget {
  const DataSyncTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => Consumer<KnownStationsModel>(
          builder: (context, knownStations, child) {
            return DataSyncPage(
              known: knownStations,
              onDownload: (station) async {
                await knownStations.startDownload(deviceId: station.deviceId);
              },
              onUpload: (station) async {
                await knownStations.startUpload(deviceId: station.deviceId);
              },
            );
          },
        ),
      );
    });
  }
}

class DataSyncPage extends StatelessWidget {
  final KnownStationsModel known;
  final void Function(StationModel) onDownload;
  final void Function(StationModel) onUpload;

  const DataSyncPage({super.key, required this.known, required this.onDownload, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final stations = known.stations
        .where((station) => station.config != null)
        .map((station) => StationSyncStatus(
              station: station,
              onDownload: () => onDownload(station),
              onUpload: () => onUpload(station),
            ))
        .toList();

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.dataSync),
        ),
        body: ListView(children: stations));
  }
}

class StationSyncStatus extends StatelessWidget {
  final StationModel station;
  final VoidCallback onDownload;
  final VoidCallback onUpload;

  StationConfig get config => station.config!;

  const StationSyncStatus({super.key, required this.station, required this.onDownload, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final subtitle = Text("${config.data.records} readings.");

    return Container(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          ListTile(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(5),
            ),
            title: Container(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(config.name)),
            subtitle: subtitle,
            dense: false,
            onTap: () {},
          ),
          buildLower(context)
        ]));
  }

  Widget buildLower(BuildContext context) {
    if (station.syncing == null) {
      return Column(children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton(onPressed: onDownload, child: Text(AppLocalizations.of(context)!.download))),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton(onPressed: onUpload, child: Text(AppLocalizations.of(context)!.upload)))
      ]);
    }

    return const Column(children: [Text("Busy")]);
  }
}
