import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../gen/ffi.dart';
import '../no_stations_widget.dart';

class DataSyncTab extends StatelessWidget {
  const DataSyncTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
          settings: settings,
          builder: (context) => Consumer<PortalAccounts>(
                builder: (context, portalAccounts, child) {
                  return Consumer<KnownStationsModel>(
                    builder: (context, knownStations, child) {
                      return DataSyncPage(
                        known: knownStations,
                        onDownload: (station) async {
                          await knownStations.startDownload(deviceId: station.deviceId);
                        },
                        onUpload: (station) async {
                          final tokens = portalAccounts.accounts[0].tokens;
                          if (tokens != null) {
                            await knownStations.startUpload(deviceId: station.deviceId, tokens: tokens);
                          } else {
                            debugPrint("No tokens!");
                          }
                        },
                      );
                    },
                  );
                },
              ));
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
        body: ListView(children: [...stations, if (stations.isEmpty) const NoStationsHelpWidget()]));
  }
}

class SyncOptions extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onUpload;

  const SyncOptions({super.key, required this.onDownload, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    pad(child) => Container(width: double.infinity, padding: const EdgeInsets.all(10), child: child);

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
  bool get isDownloading => station.syncing?.download != null;
  bool get isUploading => station.syncing?.upload != null;

  const StationSyncStatus({super.key, required this.station, required this.onDownload, required this.onUpload});

  Widget _progress(BuildContext context) {
    if (isDownloading) return DownloadProgressPanel(progress: station.syncing!.download!);
    if (isUploading) return UploadProgressPanel(progress: station.syncing!.upload!);
    if (isSyncing) {
      final localizations = AppLocalizations.of(context)!;
      return WH.padColumn(Column(children: [
        WH.progressBar(0.0),
        WH.padBelowProgress(Text(localizations.syncWorking)),
      ]));
    }
    return SyncOptions(onDownload: onDownload, onUpload: onUpload);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final title = config.name;
    final subtitle = isSyncing
        ? localizations.syncPercentageComplete(station.syncing?.completed ?? 0)
        : localizations.syncItemSubtitle(config.data.records);

    return BorderedListItem(header: GenericListItemHeader(title: title, subtitle: subtitle), children: [_progress(context)]);
  }
}

class DownloadProgressPanel extends StatelessWidget {
  final DownloadProgress progress;

  const DownloadProgressPanel({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final label = localizations.syncProgressReadings(progress.total, progress.received);
    final started = DateTime.fromMillisecondsSinceEpoch(progress.started);
    final elapsed = DateTime.now().difference(started);
    final subtitle = localizations.syncElapsed(elapsed.toString());

    return WH.padColumn(Column(children: [
      WH.progressBar(progress.completed),
      WH.padBelowProgress(Column(children: [
        WH.padLabel(Text(label)),
        WH.padLabel(Text(subtitle)),
      ]))
    ]));
  }
}

class UploadProgressPanel extends StatelessWidget {
  final UploadProgress progress;

  const UploadProgressPanel({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return WH.padColumn(Column(children: [WH.progressBar(progress.completed), WH.padBelowProgress(const SizedBox.shrink())]));
  }
}
