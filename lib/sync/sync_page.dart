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
          title: Text(AppLocalizations.of(context)!.dataSyncTitle),
        ),
        body: ListView(children: stations));
  }
}

class StationHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const StationHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    align(child) => Align(alignment: Alignment.topLeft, child: child);

    const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);

    final top = align(Container(
        padding: padding,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
        )));

    if (subtitle == null) {
      return top;
    }

    final bottom = align(Container(padding: padding, child: Text(subtitle!)));

    return Column(children: [top, bottom]);
  }
}

class SyncOptions extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onUpload;

  const SyncOptions({super.key, required this.onDownload, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.all(10);

    pad(child) => Container(width: double.infinity, padding: padding, child: child);

    final localizations = AppLocalizations.of(context)!;

    return Column(children: [
      pad(ElevatedButton(onPressed: onDownload, child: Text(localizations.download))),
      pad(ElevatedButton(onPressed: onUpload, child: Text(localizations.upload))),
    ]);
  }
}

class StationSyncStatus extends StatelessWidget {
  final StationModel station;
  final VoidCallback onDownload;
  final VoidCallback onUpload;

  StationConfig get config => station.config!;

  bool get isSyncing => station.syncing != null;

  const StationSyncStatus({super.key, required this.station, required this.onDownload, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromRGBO(212, 212, 212, 1),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: Column(children: [
          StationHeader(
              title: config.name,
              subtitle: isSyncing
                  ? localizations.syncPercentageComplete(station.syncing?.progress?.completed ?? 0)
                  : localizations.syncItemSubtitle(config.data.records)),
          isSyncing ? DownloadProgressPanel(progress: station.syncing!.progress) : SyncOptions(onDownload: onDownload, onUpload: onUpload)
        ]));
  }
}

class DownloadProgressPanel extends StatelessWidget {
  final DownloadProgress? progress;

  const DownloadProgressPanel({super.key, this.progress});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    padColumn(child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: child);
    padLabel(child) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: child);
    padBelowProgress(child) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: child);
    progressBar(value) => LinearProgressIndicator(value: value);

    if (progress == null) {
      return padColumn(Column(children: [
        progressBar(0.0),
        padBelowProgress(Text(localizations.syncWorking)),
      ]));
    }

    final label = localizations.syncProgressReadings(progress!.total, progress!.received);
    final started = DateTime.fromMillisecondsSinceEpoch(progress!.started);
    final elapsed = DateTime.now().difference(started);
    final subtitle = localizations.syncElapsed(elapsed.toString());

    return padColumn(Column(children: [
      progressBar(progress!.completed),
      padBelowProgress(Column(children: [
        padLabel(Text(label)),
        padLabel(Text(subtitle)),
      ]))
    ]));
  }
}
