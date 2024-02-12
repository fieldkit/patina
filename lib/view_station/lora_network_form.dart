import 'dart:typed_data';
import 'package:convert/convert.dart';

import 'package:fk/common_widgets.dart';
import 'package:fk/constants.dart';
import 'package:fk/diagnostics.dart';
import 'package:fk/gen/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoraNetworkForm extends StatefulWidget {
  final LoraTransmissionConfig config;
  final void Function(LoraTransmissionConfig) onSave;

  const LoraNetworkForm(
      {super.key, required this.config, required this.onSave});

  @override
  State<LoraNetworkForm> createState() => _LoraNetworkFormState();
}

class _LoraNetworkFormState extends State<LoraNetworkForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;

    return FormBuilder(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FormBuilderDropdown<LoraBand>(
            name: 'band',
            initialValue: FormHelpers.fromFrequencyInteger(widget.config.band),
            items: [LoraBand.F915Mhz, LoraBand.F868Mhz]
                .map<DropdownMenuItem<LoraBand>>((LoraBand value) {
              return DropdownMenuItem<LoraBand>(
                value: value,
                child: Text(value.toLabel()),
              );
            }).toList(),
          ),
          FormBuilderTextField(
            name: 'appKey',
            initialValue: hex.encode(widget.config.appKey ?? List.empty()),
            style: WH.monoStyle(16),
            decoration: const InputDecoration(labelText: "App Key"),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.equalLength(32),
              hexString(errorText: localizations.hexStringValidationFailed),
            ]),
          ),
          FormBuilderTextField(
            name: 'joinEui',
            initialValue: hex.encode(widget.config.joinEui ?? List.empty()),
            style: WH.monoStyle(16),
            decoration: const InputDecoration(
              labelText: "Join EUI",
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.equalLength(16),
              hexString(errorText: localizations.hexStringValidationFailed),
            ]),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.saveAndValidate()) {
                final values = _formKey.currentState!.value;
                final LoraBand band = values["band"];
                final String appKey = values["appKey"];
                final String joinEui = values["joinEui"];
                Loggers.ui.i("$values");
                final config = LoraTransmissionConfig(
                    band: band.toFrequencyInteger(),
                    appKey: Uint8List.fromList(hex.decode(appKey)),
                    joinEui: Uint8List.fromList(hex.decode(joinEui)));
                widget.onSave(config);
              }
            },
            style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all<Color>(AppColors.primaryColor),
              padding: MaterialStateProperty.all<EdgeInsets>(
                  const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0)),
            ),
            child: Text(
              localizations.networkSaveButton,
              style: WH.buttonStyle(18),
            ),
          ),
        ]
            .map((child) =>
                Padding(padding: const EdgeInsets.all(8), child: child))
            .toList(),
      ),
    );
  }
}

extension FormHelpers on LoraBand {
  String toLabel() {
    if (this == LoraBand.F868Mhz) {
      return "868Mhz";
    }
    return "915Mhz";
  }

  int toFrequencyInteger() {
    if (this == LoraBand.F868Mhz) {
      return 868;
    }
    return 915;
  }

  static LoraBand fromFrequencyInteger(int? freq) {
    if (freq != null && freq == 868) {
      return LoraBand.F868Mhz;
    }
    return LoraBand.F915Mhz;
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
