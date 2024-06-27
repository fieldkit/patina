import 'package:collection/collection.dart';
import 'package:fk/diagnostics.dart';
import 'package:fk/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../gen/api.dart';

class StationFirmwarePage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const StationFirmwarePage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final stationOps = context.watch<StationOperations>();
    final operations = stationOps.getBusy<UpgradeOperation>(config.deviceId);
    final availableFirmware = context.watch<AvailableFirmwareModel>();

    if (operations.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context, localizations),
        body: ListView(
          children: [
            _buildStationCard(context, localizations),
            _buildFirmwareUpdateCard(context, localizations, availableFirmware),
            _buildFirmwareActionButton(
                context, localizations, availableFirmware),
            _buildQuickTipCard(context, localizations),
            AvailableFirmware(
                station: station,
                available: availableFirmware,
                operations: operations)
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: _buildAppBar(context, localizations),
        body: ListView(
          children: [
            _buildStationCard(context, localizations),
            ...operations.map((operation) => Column(
                  children: [
                    UpgradeProgressWidget(operation: operation),
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        child: ElevatedTextButton(
                            text: localizations.firmwareDismiss,
                            onPressed: operation.busy
                                ? null
                                : () {
                                    stationOps.dismiss(operation);
                                  })),
                  ],
                )),
          ],
        ),
      );
    }
  }

  AppBar _buildAppBar(BuildContext context, AppLocalizations localizations) {
    return AppBar(
      centerTitle: true,
      title: Column(
        children: [
          Text(localizations.firmwareTitle),
          Text(
            station.config!.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTipCard(
      BuildContext context, AppLocalizations localizations) {
    IconData bulb = const IconData(0xe37c, fontFamily: 'MaterialIcons');
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListTile(
            tileColor: const Color.fromARGB(255, 0xf9, 0xf9, 0xf9),
            leading: Icon(bulb),
            title: Text(localizations.quickTip,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(localizations.firmwareTip)));
  }

  Widget _buildStationCard(
      BuildContext context, AppLocalizations localizations) {
    final firmwareVersion = config.firmware.label;
    return Card(
      shadowColor: Colors.white,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
            tileColor: Colors.white,
            leading: SizedBox(
              width: 48.0,
              height: 48.0,
              child: Image(
                  image: station.connected
                      ? const AssetImage(AppIcons.stationConnected)
                      : const AssetImage(
                          AppIcons.stationNotConnected,
                        )),
            ),
            title: Text(station.config!.name,
                style: const TextStyle(fontSize: 18)),
            subtitle: Column(children: [
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(localizations.firmwareVersion(firmwareVersion),
                      style: const TextStyle(fontSize: 14))),
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                      station.connected
                          ? localizations.firmwareConnected
                          : localizations.firmwareNotConnected,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold))),
            ])),
      ),
    );
  }

  Widget _buildFirmwareUpdateCard(
      BuildContext context,
      AppLocalizations localizations,
      AvailableFirmwareModel availableFirmware) {
    bool isFirmwareNewer = false;
    for (var firmware in availableFirmware.firmware) {
      final time = DateTime.fromMillisecondsSinceEpoch(firmware.time);
      Loggers.ui.v(
          "$time ${firmware.label} ${LocalFirmwareBranchInfo.parse(firmware.label)}");
      if (FirmwareComparison.compare(firmware, config.firmware).newer) {
        isFirmwareNewer = true;
        break;
      }
    }
    final firmwareReleaseDate = _formatFirmwareReleaseDate();
    return Card(
      shadowColor: Colors.white,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
            tileColor: Colors.white,
            title: Text(!isFirmwareNewer
                ? localizations.firmwareUpdated
                : localizations.firmwareNotUpdated),
            subtitle:
                Text(localizations.firmwareReleased(firmwareReleaseDate))),
      ),
    );
  }

  Widget _buildFirmwareActionButton(
      BuildContext context,
      AppLocalizations localizations,
      AvailableFirmwareModel availableFirmware) {
    bool isFirmwareNewer = false;
    LocalFirmware? newFirmware;
    for (final firmware in availableFirmware.firmware) {
      if (FirmwareComparison.compare(firmware, config.firmware).newer) {
        isFirmwareNewer = true;
        newFirmware = firmware;
        break;
      }
    }

    final navigator = Navigator.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
      child: ElevatedTextButton(
        onPressed: isFirmwareNewer
            ? () {
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => PrepareFirmwareWidget(
                        station: station, firmware: newFirmware!),
                  ),
                );
              }
            : null,
        text: localizations.firmwareUpdate,
      ),
    );
  }

  String _formatFirmwareReleaseDate() {
    final formatter = DateFormat('MM-dd HH:mm:ss');
    return formatter
        .format(DateTime.fromMillisecondsSinceEpoch(config.firmware.time));
  }
}

class FirmwareItem extends StatelessWidget {
  final FirmwareComparison comparison;
  final List<UpgradeOperation> operations;
  final VoidCallback onUpgrade;
  final bool canUpgrade;

  const FirmwareItem(
      {super.key,
      required this.comparison,
      required this.operations,
      required this.onUpgrade,
      required this.canUpgrade});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final title = comparison.label;
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    GenericListItemHeader header() {
      if (comparison.newer) {
        return GenericListItemHeader(
            title: AppLocalizations.of(context)!.firmwareVersion(title),
            subtitle: AppLocalizations.of(context)!
                .firmwareReleased(formatter.format(comparison.time)));
      } else {
        return GenericListItemHeader(
          title: AppLocalizations.of(context)!.firmwareVersion(title),
          subtitle: AppLocalizations.of(context)!
              .firmwareReleased(formatter.format(comparison.time)),
          titleStyle: const TextStyle(color: Colors.black54, fontSize: 16),
          subtitleStyle: const TextStyle(color: Colors.black54),
        );
      }
    }

    pad(child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        child: child);

    return ExpandableBorderedListItem(
        header: header(),
        expanded: comparison.newer || operations.isNotEmpty,
        children: [
          ...operations.map(
            (operation) => UpgradeProgressWidget(operation: operation),
          ),
          ElevatedTextButton(
            onPressed: canUpgrade ? onUpgrade : null,
            text: comparison.newer
                ? localizations.firmwareUpgrade
                : localizations.firmwareSwitch,
          ),
        ].map((child) => pad(child)).toList());
  }
}

class FirmwareBranch extends StatelessWidget {
  final StationModel station;
  final List<(LocalFirmware, LocalFirmwareBranchInfo)> firmware;

  const FirmwareBranch(
      {super.key, required this.station, required this.firmware});

  StationConfig get config => station.config!;

  @override
  Widget build(BuildContext context) {
    final stationOps = context.watch<StationOperations>();
    final operations = stationOps.getBusy<UpgradeOperation>(config.deviceId);
    final navigator = Navigator.of(context);

    final items = firmware
        .where((row) => row.$1.module == "fk-core")
        .map((row) => FirmwareItem(
            comparison: FirmwareComparison.compare(row.$1, config.firmware),
            operations:
                operations.where((op) => op.firmwareId == row.$1.id).toList(),
            canUpgrade:
                station.connected && operations.where((op) => op.busy).isEmpty,
            onUpgrade: () async {
              navigator.push(
                MaterialPageRoute(
                  builder: (context) =>
                      PrepareFirmwareWidget(station: station, firmware: row.$1),
                ),
              );
            }))
        .toList();

    return Column(children: [
      items[0],
      ExpandableItems(
          heading: Text("${items.length - 1} more"),
          children: items.skip(1).toList())
    ]);
  }
}

class AvailableFirmware extends StatelessWidget {
  final StationModel station;
  final AvailableFirmwareModel available;
  final List<UpgradeOperation> operations;

  const AvailableFirmware(
      {super.key,
      required this.station,
      required this.available,
      required this.operations});

  @override
  Widget build(BuildContext context) {
    final byBranch = available.firmware
        .map((el) => (el, LocalFirmwareBranchInfo.parse(el.label)))
        .where((el) => el.$2 != null)
        .map((el) => (el.$1, el.$2!))
        .groupListsBy((el) => el.$2.branch);
    return Column(
        children: byBranch.values
            .map((value) => FirmwareBranch(station: station, firmware: value))
            .toList());
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
        WH.padBelowProgress(Text(localizations.firmwareStarting)),
      ]);
    }
    if (status is UpgradeStatus_Uploading) {
      return Column(children: [
        WH.progressBar(status.field0.completed),
        WH.padBelowProgress(Text(localizations.firmwareUploading)),
      ]);
    }
    if (status is UpgradeStatus_Restarting) {
      return Text(localizations.firmwareRestarting);
    }
    if (status is UpgradeStatus_ReconnectTimeout) {
      return Text(localizations.firmwareReconnectTimeout);
    }
    if (status is UpgradeStatus_Completed) {
      return Text(localizations.firmwareCompleted);
    }
    if (status is UpgradeStatus_Failed) {
      if (operation.error == UpgradeError.sdCard) {
        return const SdCardError();
      } else {
        return Text(localizations.firmwareFailed);
      }
    }
    return const SizedBox.shrink();
  }
}

class PrepareFirmwareWidget extends StatelessWidget {
  final StationModel station;
  final LocalFirmware firmware;

  const PrepareFirmwareWidget(
      {super.key, required this.station, required this.firmware});

  @override
  Widget build(BuildContext context) {
    final availableFirmware = context.read<AvailableFirmwareModel>();
    final localizations = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);

    fullWidthButton(Widget button) {
      return Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        child: button,
      );
    }

    final ButtonStyle cancelButtonStyle = TextButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.primaryColor,
      minimumSize: const Size(88, 36),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );

    return Scaffold(
        appBar: AppBar(
          title: Text(localizations.firmwarePrepareTitle),
        ),
        body: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Expanded(
                  child: Column(children: [
                Row(
                  children: [
                    const BulletNumber(number: 1),
                    Expanded(
                        child: Text(
                      localizations.firmwarePrepareTime,
                      softWrap: true,
                    ))
                  ],
                ),
                Row(
                  children: [
                    const BulletNumber(number: 2),
                    Expanded(
                        child: Text(
                      localizations.firmwarePrepareSd,
                      softWrap: true,
                    )),
                  ],
                ),
                Row(
                  children: [
                    const BulletNumber(number: 3),
                    Expanded(
                        child: Text(
                      localizations.firmwarePreparePower,
                      softWrap: true,
                    )),
                  ],
                ),
                Row(
                  children: [
                    const BulletNumber(number: 4),
                    Expanded(
                        child: Text(
                      localizations.firmwarePrepareConnection,
                      softWrap: true,
                    )),
                  ],
                ),
              ])),
              Column(
                children: [
                  fullWidthButton(ElevatedTextButton(
                    onPressed: () async {
                      navigator.pop();
                      await availableFirmware.upgrade(
                          station.deviceId, firmware);
                    },
                    text: localizations.firmwareContinue,
                  )),
                  fullWidthButton(ElevatedTextButton(
                      onPressed: () async {
                        navigator.pop();
                      },
                      text: localizations.firmwareCancel,
                      style: cancelButtonStyle))
                ],
              ),
            ])));
  }
}

class BulletNumber extends StatelessWidget {
  final int number;

  const BulletNumber({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.logoBlue,
          ),
          child: Text(number.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 45.0)),
        ));
  }
}

class SdCardError extends StatelessWidget {
  const SdCardError({super.key});

  @override
  Widget build(BuildContext context) {
    const IconData warning = IconData(0xe6cb, fontFamily: 'MaterialIcons');
    final localizations = AppLocalizations.of(context)!;
    return ListTile(
        iconColor: const Color.fromARGB(255, 0xf9, 0x00, 0x00),
        leading: const Icon(warning),
        title: Text(localizations.firmwareSdCardError,
            style: const TextStyle(fontWeight: FontWeight.bold)));
  }
}

class ExpandableItems extends StatefulWidget {
  final Widget heading;
  final List<Widget> children;

  const ExpandableItems(
      {super.key, required this.heading, required this.children});

  @override
  State<StatefulWidget> createState() => _ExpandableBorderedListItemState();
}

class _ExpandableBorderedListItemState extends State<ExpandableItems> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        child: _expanded
            ? Column(children: [widget.heading, ...widget.children])
            : Column(children: [widget.heading]));
  }
}
