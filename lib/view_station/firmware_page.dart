import 'package:fk/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../gen/api.dart';

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
      return Text(localizations.firmwareFailed);
    }
    return const SizedBox.shrink();
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
          ElevatedTextButton(
            onPressed: canUpgrade ? onUpgrade : null,
            text: comparison.newer
                ? localizations.firmwareUpgrade
                : localizations.firmwareSwitch,
          ),
          ...operations
              .map((operation) => UpgradeProgressWidget(operation: operation))
        ].map((child) => pad(child)).toList());
  }
}

class StationFirmwarePage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const StationFirmwarePage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final stationOps = context.watch<StationOperations>();
    final busy = stationOps.isBusy(config.deviceId);
    final operations = stationOps.getBusy<UpgradeOperation>(config.deviceId);
    final availableFirmware = context.watch<AvailableFirmwareModel>();

    return Scaffold(
      appBar: _buildAppBar(context, localizations),
      body: ListView(
        children: [
          _buildStationCard(context, localizations),
          _buildFirmwareUpdateCard(context, localizations, availableFirmware),
          _buildFirmwareActionButton(context, localizations, availableFirmware),
          // _buildQuickTipCard(context, localizations), // Hide the quick tip card for now
          // TODO: Add quick tip card back once internet connection is available not just on restart for updates
          ..._buildFirmwareItems(availableFirmware, operations, busy, context)
        ],
      ),
    );
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
                    ? const AssetImage(AppIcons.StationConnected)
                    : const AssetImage(
                        AppIcons.StationNotConnected,
                      )),
          ),
          title:
              Text(station.config!.name, style: const TextStyle(fontSize: 18)),
          subtitle: Text(
              AppLocalizations.of(context)!.firmwareVersion(firmwareVersion),
              style: const TextStyle(fontSize: 14)),
          trailing: Text(
              station.connected
                  ? AppLocalizations.of(context)!.firmwareConnected
                  : AppLocalizations.of(context)!.firmwareNotConnected,
              style: const TextStyle(fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildFirmwareUpdateCard(
      BuildContext context,
      AppLocalizations localizations,
      AvailableFirmwareModel availableFirmware) {
    bool isFirmwareNewer = false;
    for (var firmware in availableFirmware.firmware) {
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
                ? AppLocalizations.of(context)!.firmwareUpdated
                : AppLocalizations.of(context)!.firmwareNotUpdated),
            subtitle: Text(AppLocalizations.of(context)!.firmwareReleased(
                firmwareReleaseDate))), // TODO: Double check that the date is actually fix, was just shorted
      ),
    );
  }

  Widget _buildFirmwareActionButton(
      BuildContext context,
      AppLocalizations localizations,
      AvailableFirmwareModel availableFirmware) {
    bool isFirmwareNewer = false;
    LocalFirmware? newFirmware;
    for (var firmware in availableFirmware.firmware) {
      if (FirmwareComparison.compare(firmware, config.firmware).newer) {
        isFirmwareNewer = true;
        newFirmware = firmware;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
      child: ElevatedTextButton(
        onPressed: isFirmwareNewer
            ? () async {
                await availableFirmware.upgrade(config.deviceId,
                    newFirmware ?? availableFirmware.firmware.last);
              }
            : null,
        text: localizations.firmwareUpdate,
      ),
    );
  }

  List<Widget> _buildFirmwareItems(AvailableFirmwareModel availableFirmware,
      List<UpgradeOperation> operations, bool busy, BuildContext context) {
    return availableFirmware.firmware
        .where((firmware) => firmware.module == "fk-core")
        .map((firmware) => FirmwareItem(
            comparison: FirmwareComparison.compare(firmware, config.firmware),
            operations:
                operations.where((op) => op.firmwareId == firmware.id).toList(),
            canUpgrade: station.connected &&
                !busy &&
                operations.where((op) => op.busy).isEmpty,
            onUpgrade: () async {
              await availableFirmware.upgrade(config.deviceId, firmware);
            }))
        .toList();
  }

  String _formatFirmwareReleaseDate() {
    final formatter = DateFormat('MM-dd HH:mm:ss');
    return formatter
        .format(DateTime.fromMillisecondsSinceEpoch(config.firmware.time));
  }
}
