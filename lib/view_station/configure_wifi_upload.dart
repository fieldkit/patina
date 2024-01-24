import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
import '../gen/ffi.dart';

Widget enableButton(String deviceId, StationConfiguration configuration,
    AppLocalizations localizations) {
  return ElevatedButton(
      onPressed: () async {
        Loggers.ui.i("wifi-upload:enable");
        await configuration.enableWifiUploading(deviceId);
      },
      child: Text(localizations.networkAutomaticUploadEnable));
}

Widget disableButton(String deviceId, StationConfiguration configuration,
    AppLocalizations localizations) {
  return ElevatedButton(
      onPressed: () async {
        Loggers.ui.i("wifi-upload:disable");
        await configuration.disableWifiUploading(deviceId);
      },
      child: Text(localizations.networkAutomaticUploadDisable));
}

class ConfigureAutomaticUploadListItem extends StatelessWidget {
  final StationModel station;

  bool get enabled => station.ephemeral?.transmission?.enabled ?? false;

  const ConfigureAutomaticUploadListItem({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final StationConfiguration configuration =
        context.watch<AppState>().configuration;

    return ListTile(
      title: Text(AppLocalizations.of(context)!.settingsAutomaticUpload),
      /*
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfigureAutomaticUploadPage(
              station: station,
            ),
          ),
        );
      },
      */
      trailing: enabled
          ? disableButton(station.deviceId, configuration, localizations)
          : enableButton(station.deviceId, configuration, localizations),
    );
  }
}

class ConfigureAutomaticUploadPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const ConfigureAutomaticUploadPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final StationConfiguration configuration =
        context.watch<StationConfiguration>();

    Loggers.ui.i("station $station $config");

    final enabled = station.ephemeral?.transmission?.enabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.name),
      ),
      body: WH.padPage(Column(children: [
        if (!enabled)
          WH.align(WH.vertical(
              enableButton(station.deviceId, configuration, localizations))),
        if (enabled)
          WH.align(WH.vertical(
              disableButton(station.deviceId, configuration, localizations)))
      ])),
    );
  }
}
