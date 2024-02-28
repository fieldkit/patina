import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../constants.dart';
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
    final KnownStationsModel knownStations =
        context.watch<KnownStationsModel>();
    final StationOperations stationOperations =
        context.watch<StationOperations>();
    final TasksModel tasks = context.watch<TasksModel>();

    return DataSyncPage(
      known: knownStations,
      stationOperations: stationOperations,
      tasks: tasks,
      onDownload: (task) async {
        await knownStations.startDownload(
            deviceId: task.deviceId, first: task.first);
      },
      onUpload: (task) async {
        await knownStations.startUpload(
            deviceId: task.deviceId, tokens: task.tokens!, files: task.files);
      },
    );
  }
}

class MessageAndButton extends StatelessWidget {
  final String title;
  final String message;
  final String button;
  final VoidCallback? onPressed;

  const MessageAndButton(
      {super.key,
      required this.title,
      required this.message,
      required this.button,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      WH.align(
        Text(
          title,
          style: const TextStyle(fontSize: 20.0),
        ),
      ),
      WH.align(
        Text(
          message,
          style: const TextStyle(fontSize: 16.0),
        ),
      ),
      WH.align(
        WH.vertical(
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            ),
            child: Text(button),
          ),
        ),
      ),
    ]);
  }
}

class LoginRequiredWidget extends StatelessWidget {
  const LoginRequiredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: MessageAndButton(
              title: AppLocalizations.of(context)!.alertTitle,
              button: AppLocalizations.of(context)!.login,
              message: AppLocalizations.of(context)!.dataLoginMessage,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountsPage(),
                  ),
                );
              }),
        ),
      ),
    );
  }
}

class DataSyncPage extends StatelessWidget {
  final KnownStationsModel known;
  final TasksModel tasks;
  final StationOperations stationOperations;
  final void Function(DownloadTask) onDownload;
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

    final stations = known.stations
        .where((station) => station.config != null)
        .map((station) {
      final downloadTask = tasks.getMaybeOne<DownloadTask>(station.deviceId);
      final uploadTask = tasks.getMaybeOne<UploadTask>(station.deviceId);
      final busy = stationOperations.isBusy(station.deviceId);
      Loggers.ui.i(
          "data-sync: busy=$busy downloadTask=$downloadTask uploadTask=$uploadTask loginTasks=$loginTasks");
      return StationSyncStatus(
        station: station,
        downloadTask: downloadTask,
        uploadTask: uploadTask,
        onDownload: (!busy && downloadTask != null)
            ? () => onDownload(downloadTask)
            : null,
        onUpload: (!busy && uploadTask != null && uploadTask.allowed)
            ? () => onUpload(uploadTask)
            : null,
      );
    }).toList();

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.dataSyncTitle),
        ),
        body: ListView(children: [
          if (loginTasks.isNotEmpty) const LoginRequiredWidget(),
          if (stations.isEmpty) const NoStationsHelpWidget(showImage: true),
          ...stations,
        ]));
  }
}

class SyncOptions extends StatelessWidget {
  final VoidCallback? onDownload;
  final VoidCallback? onUpload;

  const SyncOptions(
      {super.key, required this.onDownload, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    pad(child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        child: child);

    final localizations = AppLocalizations.of(context)!;

    return Column(children: [
      pad(ElevatedButton(
          onPressed: onDownload, child: Text(localizations.download))),
      pad(ElevatedButton(
          onPressed: onUpload, child: Text(localizations.upload))),
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
        title: localizations.alertTitle,
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
  final DownloadTask? downloadTask;
  final UploadTask? uploadTask;
  final VoidCallback? onDownload;
  final VoidCallback? onUpload;

  StationConfig get config => station.config!;

  bool get isSyncing => station.syncing != null;
  bool get isDownloading => station.syncing?.download != null;
  bool get isUploading => station.syncing?.upload != null;

  const StationSyncStatus(
      {super.key,
      required this.station,
      required this.downloadTask,
      required this.uploadTask,
      required this.onDownload,
      required this.onUpload});

  Widget _progress(BuildContext context) {
    if (isDownloading) {
      return DownloadProgressPanel(progress: station.syncing!.download!);
    }
    if (isUploading) {
      return UploadProgressPanel(progress: station.syncing!.upload!);
    }
    if (isSyncing) {
      final localizations = AppLocalizations.of(context)!;
      return WH.padColumn(Column(children: [
        WH.progressBar(0.0),
        WH.padBelowProgress(Text(localizations.syncWorking)),
      ]));
    }
    Loggers.ui.i("udp=${station.ephemeral?.capabilities.udp}");
    if (station.ephemeral?.capabilities.udp ?? false) {
      return SyncOptions(onDownload: onDownload, onUpload: onUpload);
    }
    return UpgradeRequiredWidget(station: station);
  }

  String downloadSubtitle(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final DownloadTask? task = downloadTask;
    if (task == null) {
      return localizations.syncWorking;
    } else {
      final int? first = task.first;
      if (first != null) {
        return localizations.readingsAvailableAndAlreadyHave(
            first, task.total - first);
      } else {
        return localizations.readingsAvailable(task.total);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final title = config.name;
    final subtitle = isSyncing
        ? localizations.syncPercentageComplete(station.syncing?.completed ?? 0)
        : downloadSubtitle(context);

    return BorderedListItem(
        header: GenericListItemHeader(title: title, subtitle: subtitle),
        children: [_progress(context)]);
  }
}

class DownloadProgressPanel extends StatelessWidget {
  final DownloadOperation progress;

  const DownloadProgressPanel({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final label =
        localizations.syncProgressReadings(progress.total, progress.received);
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
    return WH.padColumn(Column(children: [
      WH.progressBar(progress.completed),
      WH.padBelowProgress(const SizedBox.shrink())
    ]));
  }
}
