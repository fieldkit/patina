import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:fk/common_widgets.dart';

import 'package:fk/diagnostics.dart';
import 'package:fk/gen/ffi.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import 'lora_network_form.dart';

class ConfigureLoraPage extends StatelessWidget {
  const ConfigureLoraPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StationConfiguration configuration =
        context.watch<StationConfiguration>();

    final LoraConfig? loraConfig = configuration.loraConfig;

    Loggers.ui.i("lora $loraConfig");

    return Scaffold(
        appBar: AppBar(
          title: Text(configuration.name),
        ),
        body: ListView(children: [
          if (loraConfig != null) CurrentLoraConfig(loraConfig: loraConfig)
        ]));
  }
}

class CurrentLoraConfig extends StatelessWidget {
  final LoraConfig loraConfig;

  const CurrentLoraConfig({super.key, required this.loraConfig});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      WH.padColumn(Column(children: [
        WH.align(const Text("Band")),
        WH.align(Text(loraConfig.band.toLabel())),
        WH.align(const Text("Device EUI")),
        WH.align(HexString(bytes: loraConfig.deviceEui)),
        WH.align(const Text("Device Address")),
        WH.align(HexString(bytes: loraConfig.deviceAddress)),
        WH.align(const Text("App Key")),
        WH.align(HexString(bytes: loraConfig.appKey)),
        WH.align(const Text("Join EUI")),
        WH.align(HexString(bytes: loraConfig.joinEui)),
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

/// [FormFieldValidator] that requires the field be a valid hex string.
FormFieldValidator<T> hexString<T>({
  String? errorText,
}) {
  return (T? valueCandidate) {
    if (valueCandidate is String) {
      try {
        hex.decode(valueCandidate);
      } catch (e) {
        return errorText ?? "Expected a valid hex string.";
      }
    }
    return null;
  };
}
