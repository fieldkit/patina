import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fk/gen/api.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
import '../no_stations_widget.dart';
import '../view_station/firmware_page.dart';
import '../settings/edit_account_page.dart';

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
                    builder: (context) => EditAccountPage(
                        original: PortalAccount(
                            email: "", name: "", tokens: null, active: false)),
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

class StatusMessagePanel extends StatelessWidget {
  final StationModel station;
  final DownloadTask? downloadTask;
  final UploadTask? uploadTask;

  const StatusMessagePanel(
      {super.key,
      required this.downloadTask,
      required this.uploadTask,
      required this.station});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final readingsDown = downloadable;
    final readingsUp = uploadable;
    if (downloadable > 0) {
      if (uploadable > 0) {
        return padAll(Text(localizations.syncReadingsWaitingDownloadAndUpload(
            readingsDown, readingsUp)));
      } else {
        return padAll(
            Text(localizations.syncReadingsWaitingDownload(readingsDown)));
      }
    } else {
      if (uploadable > 0) {
        return padAll(
            Text(localizations.syncReadingsWaitingUpload(readingsUp)));
      } else {
        final syncStatus = station.syncStatus;
        if (syncStatus != null &&
            syncStatus.downloaded == syncStatus.uploaded) {
          return padAll(
              Text(localizations.syncReadingsNoneWaiting(syncStatus.uploaded)));
        } else {
          return padAll(Text(localizations.syncReadingsNone));
        }
      }
    }
  }

  int get downloadable {
    final task = downloadTask;
    if (task == null) {
      return 0;
    }
    return task.total - (task.first ?? 0);
  }

  int get uploadable => (uploadTask?.total ?? 0);
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

    // If there are no readings to download hide the button
    final task = downloadTask;
    if (task == null || !task.hasReadings) {
      return const SizedBox.shrink();
    }

    return padAll(buildDownloadButton(context));
  }

  Widget buildDownloadButton(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedTextButton(
        onPressed: () => onDownload(downloadTask!),
        text: localizations.download,
      ),
    );
  }
}

class UploadPanel extends StatelessWidget {
  final StationModel station;
  final void Function(UploadTask) onUpload;
  final UploadTask? uploadTask;

  const UploadPanel(
      {super.key,
      required this.station,
      required this.onUpload,
      required this.uploadTask});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (uploadTask == null) {
      // Nothing to upload.
      return const SizedBox.shrink();
    }

    // Show message about problems with the internet. This will be fairly common.
    if (uploadTask?.problem == UploadProblem.connectivity) {
      return padAll(Text(localizations.syncNoInternet));
    }

    if (uploadTask?.problem == UploadProblem.authentication) {
      // We could show a message, but right now we show a Login button at the
      // top of the page.
      return const SizedBox.shrink();
    }

    return padAll(SizedBox(
        width: double.infinity,
        child: ElevatedTextButton(
            onPressed: () => onUpload(uploadTask!),
            text: localizations.upload)));
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
      final status = StatusMessagePanel(
          station: station, downloadTask: downloadTask, uploadTask: uploadTask);
      final download = DownloadPanel(
          station: station, downloadTask: downloadTask, onDownload: onDownload);
      final upload = UploadPanel(
        station: station,
        uploadTask: uploadTask,
        onUpload: onUpload,
      );
      Loggers.ui.i(
          "data-sync: busy=$busy downloadTask=$downloadTask uploadTask=$uploadTask loginTasks=$loginTasks");

      return StationSyncStatus(
          station: station,
          busy: busy,
          status: status,
          download: download,
          upload: upload);
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

class AcknowledgeSyncWidget extends StatefulWidget {
  final bool downloading;
  final bool uploading;
  final Widget child;

  const AcknowledgeSyncWidget({
    super.key,
    required this.downloading,
    required this.uploading,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _AcknowledgeSyncState();
}

enum Ack {
  unnecessary,
  download,
  upload,
}

class _AcknowledgeSyncState extends State<AcknowledgeSyncWidget> {
  Ack _ack = Ack.unnecessary;

  @override
  void didUpdateWidget(covariant AcknowledgeSyncWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.downloading != widget.downloading && !widget.downloading) {
      _ack = Ack.download;
    }

    if (oldWidget.uploading != widget.uploading && !widget.uploading) {
      _ack = Ack.upload;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (_ack == Ack.unnecessary) {
      return widget.child;
    } else {
      return Column(children: [
        Text(
          _ack == Ack.download
              ? localizations.syncDownloadSuccess
              : localizations.syncUploadSuccess,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
        ),
        padAll(SizedBox(
            width: double.infinity,
            child: ElevatedTextButton(
                text: localizations.syncDismissOk,
                onPressed: () {
                  setState(() {
                    _ack = Ack.unnecessary;
                  });
                })))
      ]);
    }
  }
}

class StationSyncStatus extends StatelessWidget {
  final StationModel station;
  final bool busy;
  final StatusMessagePanel status;
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
    required this.status,
    required this.download,
    required this.upload,
  });

  Widget _body(BuildContext context) {
    if (isDownloading) {
      return DownloadProgressPanel(progress: station.syncing!.download!);
    }
    if (isUploading) {
      return UploadProgressPanel(progress: station.syncing!.upload!);
    }
    if (isSyncing || busy) {
      final localizations = AppLocalizations.of(context)!;
      return WH.padColumn(Column(children: [
        WH.progressBar(0.0),
        WH.padBelowProgress(Text(localizations.syncWorking)),
      ]));
    }
    return Column(children: [
      status,
      download,
      upload,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final title = config.name;
    final subtitle = isSyncing
        ? localizations.syncPercentageComplete(station.syncing?.completed ?? 0)
        : null;
    final header = GenericListItemHeader(title: title, subtitle: subtitle);

    final body = AcknowledgeSyncWidget(
        downloading: isDownloading,
        uploading: isUploading,
        child: _body(context));

    return BorderedListItem(header: header, children: [body]);
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
