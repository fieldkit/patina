import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
import '../gen/ffi.dart';
import '../no_stations_widget.dart';
import '../settings/accounts_page.dart';
import '../view_station/firmware_page.dart';

class DataSyncTab extends StatelessWidget {
  const DataSyncTab({super.key});

  @override
  Widget build(BuildContext context) {
    final KnownStationsModel knownStations = context.watch<KnownStationsModel>();
    final StationOperations stationOperations = context.watch<StationOperations>();
    final TasksModel tasks = context.watch<TasksModel>();

    return DataSyncPage(
      known: knownStations,
      stationOperations: stationOperations,
      tasks: tasks,
      onDownload: (station) async {
        await knownStations.startDownload(deviceId: station.deviceId);
      },
      onUpload: (task) async {
        await knownStations.startUpload(deviceId: task.deviceId, tokens: task.tokens, files: task.files);
      },
    );
  }
}

class MessageAndButton extends StatelessWidget {
  final String message;
  final String button;
  final VoidCallback? onPressed;

  const MessageAndButton({super.key, required this.message, required this.button, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      WH.align(Text(message)),
      WH.align(WH.vertical(ElevatedButton(onPressed: onPressed, child: Text(button)))),
    ]);
  }
}

class LoginRequiredWidget extends StatelessWidget {
  const LoginRequiredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return WH.padPage(MessageAndButton(
        button: "Login",
        message: "To upload data you need to login.",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountsPage(),
            ),
          );
        }));
  }
}

class DataSyncPage extends StatelessWidget {
  final KnownStationsModel known;
  final TasksModel tasks;
  final StationOperations stationOperations;
  final void Function(StationModel) onDownload;
  final void Function(UploadTask) onUpload;

  const DataSyncPage(
      {super.key,
      required this.known,
      required this.tasks,
      required this.stationOperations,
      required this.onDownload,
      required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final loginTasks = tasks.getAll<LoginTask>();

    final stations = known.stations.where((station) => station.config != null).map((station) {
      final uploadTask = tasks.getMaybeOne<UploadTask>(station.deviceId);
      final busy = stationOperations.isBusy(station.deviceId);
      Loggers.ui.i("data-sync: busy=$busy uploadTask=$uploadTask loginTasks=$loginTasks");
      return StationSyncStatus(
        station: station,
        onDownload: busy ? null : () => onDownload(station),
        onUpload: (!busy && uploadTask != null) ? () => onUpload(uploadTask) : null,
      );
    }).toList();

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.dataSyncTitle),
        ),
        body: ListView(children: [
          if (loginTasks.isNotEmpty) const LoginRequiredWidget(),
          if (stations.isEmpty) const NoStationsHelpWidget(),
          ...stations,
        ]));
  }
}

class SyncOptions extends StatelessWidget {
  final VoidCallback? onDownload;
  final VoidCallback? onUpload;

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

class UpgradeRequiredWidget extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const UpgradeRequiredWidget({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return WH.padPage(MessageAndButton(
        message: localizations.syncUpgradeRequiredMessage,
        button: localizations.syncManageFirmware,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StationFirmwarePage(
                station: station,
              ),
            ),
          );
        }));
  }
}

class StationSyncStatus extends StatelessWidget {
  final StationModel station;
  final VoidCallback? onDownload;
  final VoidCallback? onUpload;

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
    if (station.ephemeral?.capabilities.udp ?? false) {
      return SyncOptions(onDownload: onDownload, onUpload: onUpload);
    }
    return UpgradeRequiredWidget(station: station);
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
  final DownloadOperation progress;

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
  final UploadOperation progress;

  const UploadProgressPanel({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return WH.padColumn(Column(children: [WH.progressBar(progress.completed), WH.padBelowProgress(const SizedBox.shrink())]));
  }
}
