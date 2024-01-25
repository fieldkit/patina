import 'package:fk/constants.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
import '../gen/ffi.dart';
import 'configure_wifi_upload.dart';
import 'wifi_network_form.dart';

class ConfigureWiFiPage extends StatelessWidget {
  final StationModel station;

  String get deviceId => station.deviceId;

  StationConfig get config => station.config!;

  bool get bothSlotsFilled => station.ephemeral?.networks.length == 2;

  const ConfigureWiFiPage({super.key, required this.station});

  Widget tooManyNetworks(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Text(localizations.networkNoMoreSlots);
  }

  Widget addNetworkButton(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ElevatedButton(
        style: ButtonStyle(
          backgroundColor:
              MaterialStateProperty.all<Color>(AppColors.primaryColor),
          padding: MaterialStateProperty.all<EdgeInsets>(
              const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0)),
        ),
        child: Text(
          localizations.networkAddButton,
          style: WH.buttonStyle(18),
        ),
        onPressed: () async {
          await onAddNetwork(context);
        });
  }

  @override
  Widget build(BuildContext context) {
    final StationConfiguration configuration =
        context.watch<StationConfiguration>();

    final List<WifiNetworkListItem> networks = configuration
        .getStationNetworks(deviceId)
        .where((network) => network.ssid.isNotEmpty)
        .map((network) => WifiNetworkListItem(
            network: network,
            onRemove: () async {
              await onRemoveNetwork(context, network);
            }))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: ListView(
          children: WH.divideWith(() => const Divider(), [
        ...networks,
        Container(
            padding: const EdgeInsets.all(24.0),
            child: bothSlotsFilled
                ? tooManyNetworks(context)
                : addNetworkButton(context)),
        ConfigureAutomaticUploadListItem(station: station),
      ])),
    );
  }

  Future<void> onAddNetwork(BuildContext context) async {
    final StationConfiguration configuration =
        context.read<StationConfiguration>();
    final navigator = Navigator.of(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WifiNetworkForm(
            onSave: (WifiNetwork network) async {
              Loggers.ui.i("$deviceId adding network");

              final overlay = context.loaderOverlay;
              overlay.show();
              try {
                await configuration.addNetwork(deviceId,
                    station.ephemeral?.networks ?? List.empty(), network);
              } catch (e) {
                Loggers.ui.e("$deviceId $e");
              } finally {
                navigator.pop();
                overlay.hide();
              }
            },
            original: WifiNetwork(ssid: "", password: "", preferred: false)),
      ),
    );
  }

  Future<void> onRemoveNetwork(
      BuildContext context, NetworkConfig network) async {
    final StationConfiguration configuration =
        context.read<StationConfiguration>();

    await showDialog(
        context: context,
        builder: (context) {
          final localizations = AppLocalizations.of(context)!;
          final navigator = Navigator.of(context);

          return AlertDialog(
            title: Text(localizations.confirmClearCalibrationTitle),
            content: Text(localizations.confirmDelete),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    navigator.pop();
                  },
                  child: Text(localizations.confirmCancel)),
              TextButton(
                  onPressed: () async {
                    navigator.pop();

                    Loggers.ui.i("$deviceId remove network");
                    final overlay = context.loaderOverlay;
                    overlay.show();
                    try {
                      await configuration.removeNetwork(deviceId, network);
                    } catch (e) {
                      Loggers.ui.e("$deviceId $e");
                    } finally {
                      overlay.hide();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.confirmYes))
            ],
          );
        });
  }
}

class WifiNetworkListItem extends StatelessWidget {
  final NetworkConfig network;
  final VoidCallback onRemove;

  const WifiNetworkListItem({
    super.key,
    required this.network,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ListTile(
      title: Text(network.ssid),
      trailing: ElevatedButton(
          child: Text(localizations.networkRemoveButton),
          onPressed: () async {
            onRemove();
          }),
    );
  }
}
