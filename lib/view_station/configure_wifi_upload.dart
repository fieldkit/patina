import 'package:fk/settings/accounts_page.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';

class EnableButton extends StatelessWidget {
  const EnableButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final StationConfiguration configuration =
        context.watch<StationConfiguration>();

    if (!configuration.canEnableWifiUploading()) {
      return ElevatedTextButton(
          text: localizations.login,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccountsPage(),
              ),
            );
          });
    }

    return ElevatedTextButton(
        onPressed: () async {
          Loggers.ui.i("wifi-upload:disable");
          final overlay = context.loaderOverlay;
          overlay.show();
          try {
            await configuration.enableWifiUploading();
          } catch (e) {
            Loggers.ui.e("error: $e");
          } finally {
            overlay.hide();
          }
        },
        text: localizations.networkAutomaticUploadEnable);
  }
}

class DisableButton extends StatelessWidget {
  const DisableButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final StationConfiguration configuration =
        context.read<StationConfiguration>();

    return ElevatedTextButton(
        onPressed: () async {
          Loggers.ui.i("wifi-upload:disable");
          final overlay = context.loaderOverlay;
          overlay.show();
          try {
            await configuration.disableWifiUploading();
          } catch (e) {
            Loggers.ui.e("error: $e");
          } finally {
            overlay.hide();
          }
        },
        text: localizations.networkAutomaticUploadDisable);
  }
}

class ConfigureAutomaticUploadListItem extends StatelessWidget {
  const ConfigureAutomaticUploadListItem({super.key});

  @override
  Widget build(BuildContext context) {
    final StationConfiguration configuration =
        context.watch<StationConfiguration>();

    final bool enabled =
        configuration.config.ephemeral?.transmission?.enabled ?? false;

    return ListTile(
      title: Text(AppLocalizations.of(context)!.settingsAutomaticUpload),
      trailing: enabled ? const DisableButton() : const EnableButton(),
    );
  }
}

class ConfigureAutomaticUploadPage extends StatelessWidget {
  const ConfigureAutomaticUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StationConfiguration configuration =
        context.watch<StationConfiguration>();

    final bool enabled = configuration.isAutomaticUploadEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(configuration.name),
      ),
      body: WH.padPage(Column(children: [
        if (!enabled) WH.align(WH.vertical(const EnableButton())),
        if (enabled) WH.align(WH.vertical(const DisableButton()))
      ])),
    );
  }
}
