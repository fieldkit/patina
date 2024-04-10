import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
import '../gen/api.dart';
import 'configure_wifi_upload.dart';
import 'wifi_network_form.dart';

class ConfigureWiFiPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  bool get bothSlotsFilled => station.ephemeral?.networks.length == 2;

  const ConfigureWiFiPage({super.key, required this.station});

  Widget tooManyNetworks(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Text(localizations.networkNoMoreSlots);
  }

  Widget addNetworkButton(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return ElevatedTextButton(
        text: localizations.networkAddButton,
        onPressed: () async {
          await onAddNetwork(context);
        });
  }

  @override
  Widget build(BuildContext context) {
    final StationConfiguration configuration =
        context.watch<StationConfiguration>();

    final List<Widget> networks = configuration.networks
        .where((network) => network.ssid.isNotEmpty)
        .map((network) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: WifiNetworkListItem(
                network: network,
                onRemove: () async {
                  await onRemoveNetwork(context, network);
                })))
        .toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            Text(AppLocalizations.of(context)!.networksTitle),
            Text(
              config.name,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: ListView(
          children: WH.divideWith(() => const Divider(), [
        ...networks,
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 22),
            child: bothSlotsFilled
                ? tooManyNetworks(context)
                : addNetworkButton(context)),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: ConfigureAutomaticUploadListItem()),
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
              Loggers.ui.i("adding network");

              final overlay = context.loaderOverlay;
              overlay.show();
              try {
                await configuration.addNetwork(
                    station.ephemeral?.networks ?? List.empty(), network);
              } catch (e) {
                Loggers.ui.e("$e");
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
            title: Text(localizations.confirmRemoveNetwork),
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

                    Loggers.ui.i("remove network");
                    final overlay = context.loaderOverlay;
                    overlay.show();
                    try {
                      await configuration.removeNetwork(network);
                    } catch (e) {
                      Loggers.ui.e("$e");
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
      trailing: ElevatedTextButton(
          text: localizations.networkRemoveButton,
          onPressed: () async {
            onRemove();
          }),
    );
  }
}
