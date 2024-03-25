import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'package:fk/common_widgets.dart';
import 'package:fk/gen/ffi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../app_state.dart';
import 'lora_network_form.dart';

class ConfigureLoraPage extends StatelessWidget {
  const ConfigureLoraPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StationConfiguration configuration =
        context.watch<StationConfiguration>();

    final LoraConfig? loraConfig = configuration.loraConfig;

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Column(
            children: [
              Text(AppLocalizations.of(context)!.loraConfigurationTitle),
              Text(
                configuration.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
        body: ListView(children: [
          if (loraConfig != null && !loraConfig.available)
            const MissingLoraModule(),
          if (loraConfig != null)
            DisplayLoraConfiguration(loraConfig: loraConfig)
        ]));
  }
}

class LoraConfigurationFormPage extends StatelessWidget {
  final void Function(LoraTransmissionConfig) onSave;
  final LoraConfig loraConfig;

  const LoraConfigurationFormPage(
      {super.key, required this.loraConfig, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          title: Text(localizations.loraConfigurationTitle),
        ),
        body: ListView(children: [
          LoraNetworkForm(
            config: LoraTransmissionConfig(
                band: loraConfig.band.toFrequencyInteger(),
                appKey: loraConfig.appKey,
                joinEui: loraConfig.joinEui),
            onSave: (saving) async {
              onSave(LoraTransmissionConfig(
                  band: saving.band,
                  appKey: saving.appKey,
                  joinEui: saving.joinEui,
                  schedule: const Schedule_Every(60 * 60)));
            },
          )
        ]));
  }
}

class MissingLoraModule extends StatelessWidget {
  const MissingLoraModule({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Text(
          localizations.loraNoModule,
          style: const TextStyle(fontSize: 18, color: Colors.red),
        ));
  }
}

class DisplayLoraConfiguration extends StatelessWidget {
  final LoraConfig loraConfig;

  const DisplayLoraConfiguration({super.key, required this.loraConfig});

  @override
  Widget build(BuildContext context) {
    final StationConfiguration configuration =
        context.read<StationConfiguration>();

    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return WH.padColumn(Column(children: [
      Text(localizations.loraBand, style: labelStyle()),
      Text(loraConfig.band.toLabel()),
      LabelledHexString(
          label: localizations.loraDeviceEui, bytes: loraConfig.deviceEui),
      LabelledHexString(
          label: localizations.loraDeviceAddress,
          bytes: loraConfig.deviceAddress),
      LabelledHexString(
          label: localizations.loraAppKey, bytes: loraConfig.appKey),
      LabelledHexString(
          label: localizations.loraJoinEui, bytes: loraConfig.joinEui),
      if (loraConfig.networkSessionKey.isNotEmpty)
        LabelledHexString(
            label: localizations.loraNetworkKey,
            bytes: loraConfig.networkSessionKey),
      if (loraConfig.appSessionKey.isNotEmpty)
        LabelledHexString(
            label: localizations.loraSessionKey,
            bytes: loraConfig.appSessionKey),
      const Divider(),
      ElevatedTextButton(
        text: localizations.settingsLoraEdit,
        onPressed: () async {
          final navigator = Navigator.of(context);

          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoraConfigurationFormPage(
                  loraConfig: loraConfig,
                  onSave: (LoraTransmissionConfig config) async {
                    final overlay = context.loaderOverlay;
                    overlay.show();
                    try {
                      await configuration
                          .configureLora(config); // TODO Schedule
                    } finally {
                      navigator.pop();
                      overlay.hide();
                    }
                  },
                ),
              ));
        },
      ),
      const Divider(),
      ElevatedTextButton(
        text: localizations.settingsLoraVerify,
        onPressed: () async {
          final overlay = context.loaderOverlay;
          overlay.show();
          try {
            await configuration.verifyLora();
          } finally {
            overlay.hide();
          }
        },
      )
    ]));
  }
}

class LabelledHexString extends StatelessWidget {
  final String label;
  final Uint8List bytes;

  const LabelledHexString(
      {super.key, required this.label, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      WH.align(Text(label, style: labelStyle())),
      WH.align(HexString(bytes: bytes)),
    ]);
  }
}

class HexString extends StatelessWidget {
  final Uint8List bytes;

  const HexString({super.key, required this.bytes});

  @override
  Widget build(BuildContext context) {
    // TODO Consider breaking this into WORDs or something.
    return Text(
      hex.encode(bytes),
      style: WH.monoStyle(16),
    );
  }
}

TextStyle labelStyle() {
  return const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
}
