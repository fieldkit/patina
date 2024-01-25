import 'package:fk/app_state.dart';
import 'package:fk/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../common_widgets.dart';

class WifiNetworkForm extends StatefulWidget {
  final void Function(WifiNetwork) onSave;
  final WifiNetwork original;

  const WifiNetworkForm(
      {super.key, required this.onSave, required this.original});

  @override
  State<WifiNetworkForm> createState() => _WifiNetworkFormState();
}

class _WifiNetworkFormState extends State<WifiNetworkForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.networkEditTitle),
      ),
      body: FormBuilder(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FormBuilderTextField(
              name: 'ssid',
              initialValue: widget.original.ssid,
              decoration: InputDecoration(labelText: localizations.wifiSsid),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            FormBuilderTextField(
              name: 'password',
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                labelText: localizations.wifiPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_passwordVisible,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.saveAndValidate()) {
                  final ssid = _formKey.currentState!.value['ssid'];
                  final password = _formKey.currentState!.value['password'];
                  widget.onSave(WifiNetwork(
                      ssid: ssid, password: password, preferred: false));
                }
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(AppColors.primaryColor),
                padding: MaterialStateProperty.all<EdgeInsets>(
                    const EdgeInsets.symmetric(
                        vertical: 24.0, horizontal: 32.0)),
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
      ),
    );
  }
}
