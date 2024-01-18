import 'package:fk_data_protocol/fk-data.pb.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../constants.dart';
import '../app_state.dart';
import '../common_widgets.dart';
import '../gen/ffi.dart';

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
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:MM:SS');

    GenericListItemHeader header() {
      if (comparison.newer) {
        return GenericListItemHeader(
            title: title, subtitle: formatter.format(comparison.time));
      } else {
        return GenericListItemHeader(
          title: title,
          subtitle: formatter.format(comparison.time),
          titleStyle: const TextStyle(color: Colors.grey),
          subtitleStyle: const TextStyle(color: Colors.grey),
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
          ElevatedButton(
              onPressed: canUpgrade ? onUpgrade : null,
              child: Text(localizations.firmwareUpgrade)),
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

    // Extract the current firmware version and its release date
    final firmwareVersion = config.firmware.label;
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(config.firmware.time);
    final String firmwareReleaseDate = formatter.format(dateTime);

    // Determine if the firmware is up to date
    var isFirmwareUpToDate = true; // Default to true, modify as needed
    for (var firmware in availableFirmware.firmware) {
      var comparison = FirmwareComparison.compare(firmware, config.firmware);
      if (comparison.newer) {
        isFirmwareUpToDate = false;
        break;
      }
    }

    // Generate firmware items
    final items = availableFirmware.firmware
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.firmwareTitle),
            Text(
              station.config!.name,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          Card(
            shadowColor: Colors.white,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                tileColor: Colors.white,
                leading: SizedBox(
                  width: 48.0, // Adjust the width as needed
                  height: 48.0, // Adjust the height as needed
                  child: Image(
                      image: station.connected
                          ? const AssetImage(
                              "resources/images/Icon_Station_Connected.png")
                          : const AssetImage(
                              "resources/images/Icon_Station_Not_Connected.png",
                            )),
                ),
                title: Text(station.config!.name,
                    style: const TextStyle(fontSize: 18)),
                subtitle: Text(AppLocalizations.of(context)!
                    .firmwareVersion(firmwareVersion)),
                // TODO: Remove trailing text for connnected to match old app design
                trailing: Text(
                    station.connected
                        ? AppLocalizations.of(context)!.firmwareConnected
                        : AppLocalizations.of(context)!.firmwareNotConnected,
                    style: const TextStyle(fontSize: 14)),
              ),
            ),
          ),
          Card(
            shadowColor: Colors.white,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                  tileColor: Colors.white,
                  title: Text(isFirmwareUpToDate
                      ? AppLocalizations.of(context)!.firmwareUpdated
                      : AppLocalizations.of(context)!.firmwareNotUpdated),
                  subtitle: Text(AppLocalizations.of(context)!.firmwareReleased(
                      firmwareReleaseDate))), // TODO: Fix release date, currently 1970
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
            child: ElevatedButton(
              onPressed: isFirmwareUpToDate
                  ? null
                  : () {
                      // TODO: Add logic to initiate firmware update
                    },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 201, 201, 201),
                textStyle: const TextStyle(fontSize: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 18.0),
              ),
              child: Text(AppLocalizations.of(context)!.firmwareUpdate),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Add logic to check for new firmware
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.primaryColor, width: 1),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 18.0),
              ),
              child: Text(AppLocalizations.of(context)!.firmwareCheck,
                  style: const TextStyle(
                      color: AppColors.primaryColor, fontSize: 16)),
            ),
          ),
          Card(
            color: const Color.fromARGB(255, 252, 252, 252),
            child: Container(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                    leading: const Icon(Icons.lightbulb),
                    title: Text(AppLocalizations.of(context)!.quickTip),
                    subtitle: Text(AppLocalizations.of(context)!.firmwareTip))),
          ),
          ...items
        ],
      ),
    );
  }
}
