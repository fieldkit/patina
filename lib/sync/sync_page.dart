import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fk/gen/api.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
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
        await knownStations.startDownloading(
            deviceId: task.deviceId, first: task.first);
      },
      onUpload: (task) async {
        await knownStations.startUploading(
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
          ElevatedTextButton(
            onPressed: onPressed,
            text: button,
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
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: MessageAndButton(
              title: localizations.alertTitle,
              button: localizations.login,
              message: localizations.dataLoginMessage,
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

Widget padAll(Widget child) {
  return Container(
      width: double.infinity, padding: const EdgeInsets.all(14), child: child);
}

Widget padVertical(Widget child) {
  return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: child);
}

class DownloadPanel extends StatelessWidget {
  final StationModel station;
  final void Function(DownloadTask) onDownload;
  final DownloadTask? downloadTask;

  const DownloadPanel(
      {super.key,
      required this.station,
      required this.onDownload,
      this.downloadTask});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (!station.connected || station.ephemeral == null) {
      return padAll(Text(localizations.syncDisconnected));
    }

    if (!(station.ephemeral?.capabilities.udp ?? false)) {
      return UpgradeRequiredWidget(station: station);
    }

    if (downloadTask == null) {
      return padAll(Text(localizations.syncNoDownload));
    }

    return padAll(Column(children: [
      padVertical(Text(availableReadings(context))),
      buildDownloadButton(context, downloadTask, onDownload),
    ]));
  }

  Widget buildDownloadButton(BuildContext context, DownloadTask? downloadTask, void Function(DownloadTask) onDownload) {
        final localizations = AppLocalizations.of(context)!;
        final DownloadTask? task = downloadTask;
        if (task == null || task.first == null) { // If there are no readings to download hide the button
          return const SizedBox.shrink();
        } else {
          final num first = task.first as num;
          if (task.total - first != 0) { // If there are readings to download show the button
          return SizedBox(
            width: double.infinity,
            child: ElevatedTextButton(
              onPressed: () => onDownload(downloadTask!),
              text: localizations.download,
            ),
          );
          } else {
            return const SizedBox.shrink();
          }
        }
      }

  String availableReadings(BuildContext context) {
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
}

class UploadPanel extends StatelessWidget {
  final StationModel station;
  final void Function(UploadTask) onUpload;
  final UploadTask? uploadTask;
  final bool hasLoginTasks;

  const UploadPanel(
      {super.key,
      required this.station,
      required this.onUpload,
      required this.uploadTask,
      required this.hasLoginTasks});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (uploadTask == null) {
      if (hasLoginTasks) {
        return const SizedBox.shrink();
      } else {
        return padAll(Text(localizations.syncNoUpload));
      }
    }

    if (uploadTask?.problem == UploadProblem.connectivity) {
      return padAll(Text(localizations.syncNoInternet));
    }

    if (uploadTask?.problem == UploadProblem.authentication) {
      // We could do this, but right now we show a Login button at the top of the page.
      // return Text("Not logged in to portal.");
      return const SizedBox.shrink();
    }

    return padAll(Column(children: [
      padVertical(Text(availableReadings(context))),
      SizedBox(
          width: double.infinity,
          child: ElevatedTextButton(
              onPressed: () => onUpload(uploadTask!),
              text: localizations.upload))
    ]));
  }

  String availableReadings(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final UploadTask? task = uploadTask;
    if (task == null) {
      return localizations.syncWorking;
    } else {
      return localizations.readingsPendingUpload(task.total);
    }
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
      final download = DownloadPanel(
          station: station, downloadTask: downloadTask, onDownload: onDownload);
      final upload = UploadPanel(
        station: station,
        uploadTask: uploadTask,
        onUpload: onUpload,
        hasLoginTasks: loginTasks.isNotEmpty,
      );
      Loggers.ui.i(
          "data-sync: busy=$busy downloadTask=$downloadTask uploadTask=$uploadTask loginTasks=$loginTasks");
      return StationSyncStatus(
          station: station, busy: busy, download: download, upload: upload);
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

class StationSyncStatus extends StatelessWidget {
  final StationModel station;
  final bool busy;
  final Widget download;
  final Widget upload;

  StationConfig get config => station.config!;

  bool get isSyncing => station.syncing != null;
  bool get isFailed => station.syncing?.failed == true;
  bool get isDownloading => station.syncing?.download != null;
  bool get isUploading => station.syncing?.upload != null;

  const StationSyncStatus({
    super.key,
    required this.station,
    required this.busy,
    required this.download,
    required this.upload,
  });

  Widget _progress(BuildContext context) {
    if (isDownloading) {
      return DownloadProgressPanel(progress: station.syncing!.download!);
    }
    if (isUploading) {
      return UploadProgressPanel(progress: station.syncing!.upload!);
    }
    if ((isSyncing || busy) && !isFailed) {
      final localizations = AppLocalizations.of(context)!;
      return WH.padColumn(Column(children: [
        WH.progressBar(0.0),
        WH.padBelowProgress(Text(localizations.syncWorking)),
      ]));
    }
    return Column(children: [download, upload]);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final title = config.name;
    final subtitle = isSyncing
        ? localizations.syncPercentageComplete(station.syncing?.completed ?? 0)
        : null;

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
