import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
import '../gen/ffi.dart';

class EnableButton extends StatelessWidget {
  final String deviceId;

  const EnableButton({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final StationConfiguration configuration =
        context.read<StationConfiguration>();

    return ElevatedButton(
        onPressed: () async {
          Loggers.ui.i("wifi-upload:disable");
          final overlay = context.loaderOverlay;
          overlay.show();
          try {
            await configuration.enableWifiUploading(deviceId);
          } catch (e) {
            Loggers.ui.e("error: $e");
          } finally {
            overlay.hide();
          }
        },
        child: Text(localizations.networkAutomaticUploadEnable));
  }
}

class DisableButton extends StatelessWidget {
  final String deviceId;

  const DisableButton({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final StationConfiguration configuration =
        context.read<StationConfiguration>();

    return ElevatedButton(
        onPressed: () async {
          Loggers.ui.i("wifi-upload:disable");
          final overlay = context.loaderOverlay;
          overlay.show();
          try {
            await configuration.disableWifiUploading(deviceId);
          } catch (e) {
            Loggers.ui.e("error: $e");
          } finally {
            overlay.hide();
          }
        },
        child: Text(localizations.networkAutomaticUploadDisable));
  }
}

class ConfigureAutomaticUploadListItem extends StatelessWidget {
  final StationModel station;

  bool get enabled => station.ephemeral?.transmission?.enabled ?? false;

  const ConfigureAutomaticUploadListItem({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.settingsAutomaticUpload),
      trailing: enabled
          ? DisableButton(deviceId: station.deviceId)
          : EnableButton(deviceId: station.deviceId),
    );
  }
}

class ConfigureAutomaticUploadPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const ConfigureAutomaticUploadPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final StationConfiguration configuration =
        context.watch<StationConfiguration>();

    Loggers.ui.i("station $station $config");

    final bool enabled =
        configuration.isAutomaticUploadEnabled(station.deviceId);

    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: WH.padPage(Column(children: [
        if (!enabled)
          WH.align(WH.vertical(EnableButton(deviceId: station.deviceId))),
        if (enabled)
          WH.align(WH.vertical(DisableButton(deviceId: station.deviceId)))
      ])),
    );
  }
}
