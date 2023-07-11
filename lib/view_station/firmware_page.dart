import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  const FirmwareItem({super.key, required this.comparison, required this.operations, required this.onUpgrade, required this.canUpgrade});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final title = comparison.label;
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:MM:SS');

    GenericListItemHeader header() {
      if (comparison.newer) {
        return GenericListItemHeader(title: title, subtitle: formatter.format(comparison.time));
      } else {
        return GenericListItemHeader(
          title: title,
          subtitle: formatter.format(comparison.time),
          titleStyle: const TextStyle(color: Colors.grey),
          subtitleStyle: const TextStyle(color: Colors.grey),
        );
      }
    }

    pad(child) => Container(width: double.infinity, padding: const EdgeInsets.all(10), child: child);

    return ExpandableBorderedListItem(
        header: header(),
        expanded: comparison.newer,
        children: [
          ElevatedButton(onPressed: canUpgrade ? onUpgrade : null, child: Text(localizations.firmwareUpgrade)),
          ...operations.map((operation) => UpgradeProgressWidget(operation: operation))
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
    final operations = context.watch<StationOperations>().getAll<UpgradeOperation>(config.deviceId);
    final availableFirmware = context.watch<AvailableFirmwareModel>();
    final items = availableFirmware.firmware
        .where((firmware) => firmware.module == "fk-core")
        .map((firmware) => FirmwareItem(
            comparison: FirmwareComparison.compare(firmware, config.firmware),
            operations: operations.where((op) => op.firmwareId == firmware.id).toList(),
            canUpgrade: operations.where((op) => op.busy).isEmpty,
            onUpgrade: () async {
              await availableFirmware.upgrade(config.deviceId, firmware);
            }))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.firmwareTitle),
      ),
      body: ListView(
        children: items,
      ),
    );
  }
}
