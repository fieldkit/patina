import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'package:fk/diagnostics.dart';
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
          title: Text(configuration.name),
        ),
        body: ListView(children: [
          if (loraConfig != null && !loraConfig.available)
            const MissingLoraModule(),
          if (loraConfig != null) CurrentLoraConfig(loraConfig: loraConfig)
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

class CurrentLoraConfig extends StatelessWidget {
  final LoraConfig loraConfig;

  const CurrentLoraConfig({super.key, required this.loraConfig});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return Column(children: [
      WH.padColumn(Column(children: [
        WH.align(Text(localizations.loraBand)),
        WH.align(Text(loraConfig.band.toLabel())),
        WH.align(LabelledHexString(
            label: localizations.loraDeviceEui, bytes: loraConfig.deviceEui)),
        WH.align(LabelledHexString(
            label: localizations.loraDeviceAddress,
            bytes: loraConfig.deviceAddress)),
        WH.align(LabelledHexString(
            label: localizations.loraAppKey, bytes: loraConfig.appKey)),
        WH.align(LabelledHexString(
            label: localizations.loraJoinEui, bytes: loraConfig.joinEui)),
        if (loraConfig.networkSessionKey.isNotEmpty)
          WH.align(LabelledHexString(
              label: localizations.loraNetworkKey,
              bytes: loraConfig.networkSessionKey)),
        if (loraConfig.appSessionKey.isNotEmpty)
          WH.align(LabelledHexString(
              label: localizations.loraSessionKey,
              bytes: loraConfig.appSessionKey)),
      ])),
      LoraNetworkForm(
        config: LoraTransmissionConfig(
            band: loraConfig.band.toFrequencyInteger(),
            appKey: loraConfig.appKey,
            joinEui: loraConfig.joinEui),
        onSave: (saving) async {
          Loggers.ui.i("save $saving");

          final StationConfiguration configuration =
              context.read<StationConfiguration>();

          final overlay = context.loaderOverlay;
          overlay.show();
          try {
            await configuration.configureLora(LoraTransmissionConfig(
                band: saving.band,
                appKey: saving.appKey,
                joinEui: saving.joinEui,
                schedule: const Schedule_Every(60 * 60))); // TODO Schedule
          } finally {
            overlay.hide();
          }
        },
      ),
    ]);
  }
}

class DisplayLoraBand extends StatelessWidget {
  final LoraBand band;

  const DisplayLoraBand({super.key, required this.band});

  @override
  Widget build(BuildContext context) {
    if (band == LoraBand.F868Mhz) {
      return const Text("868MHz");
    }
    if (band == LoraBand.F915Mhz) {
      return const Text("915MHz");
    }
    return const Text("None");
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

class LabelledHexString extends StatelessWidget {
  final String label;
  final Uint8List bytes;

  const LabelledHexString(
      {super.key, required this.label, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      WH.align(Text(label)),
      WH.align(HexString(bytes: bytes)),
    ]);
  }
}
