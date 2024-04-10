import 'package:fk/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../diagnostics.dart';

class AccountForm extends StatefulWidget {
  final PortalAccount original;

  const AccountForm({super.key, required this.original});

  @override
  State<AccountForm> createState() => _AccountState();
}

class _AccountState extends State<AccountForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _passwordVisible = false;
  bool _registering = false;

  Future<void> _save(BuildContext context, PortalAccounts accounts,
      AppLocalizations localizations) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final overlay = context.loaderOverlay;
    final email = _formKey.currentState!.value['email'];
    final password = _formKey.currentState!.value['password'];
    overlay.show();
    try {
      if (_registering) {
        try {
          final name = _formKey.currentState!.value['name'];
          bool tncAccept = true;
          await accounts.registerAccount(email, password, name, tncAccept);
          navigator.pop();
          messenger.showSnackBar(SnackBar(
            content: Text(localizations.accountCreated),
          ));
        } catch (error) {
          Loggers.portal.e("$error");
          messenger.showSnackBar(SnackBar(
            content: Text(localizations.accountRegistrationFailed),
          ));
        }
      } else {
        final saved = await accounts.addOrUpdate(email, password);
        if (saved != null) {
          navigator.pop();
        } else {
          messenger.showSnackBar(SnackBar(
            content: Text(localizations.accountFormFail),
          ));
        }
      }
    } catch (error) {
      Loggers.portal.e("$error");
    } finally {
      overlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.read<PortalAccounts>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountAddTitle),
      ),
      body: FormBuilder(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Visibility(
                visible: _registering,
                child: FormBuilderTextField(
                  name: 'name',
                  keyboardType: TextInputType.name,
                  decoration:
                      InputDecoration(labelText: localizations.accountName),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                )),
            FormBuilderTextField(
              name: 'email',
              initialValue: widget.original.email,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  InputDecoration(labelText: localizations.accountEmail),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.email(),
              ]),
            ),
            FormBuilderTextField(
              name: 'password',
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                labelText: localizations.accountPassword,
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
                FormBuilderValidators.minLength(10),
              ]),
            ),
            Visibility(
                visible: _registering,
                child: FormBuilderTextField(
                  name: 'confirmPassword',
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: localizations.accountConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
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
                    FormBuilderValidators.minLength(10),
                    (val) {
                      if (_formKey.currentState?.fields["password"]?.value ==
                          val) {
                        return null;
                      }
                      return localizations.accountConfirmPasswordMatch;
                    }
                  ]),
                )),
            CheckboxListTile(
              title: Text(localizations.accountRegisterLabel),
              tristate: true,
              value: _registering,
              onChanged: (bool? value) {
                setState(() {
                  _registering = value ?? false;
                });
              },
            ),
            ElevatedTextButton(
              onPressed: () async {
                if (_formKey.currentState!.saveAndValidate()) {
                  await _save(context, accounts, localizations);
                }
              },
              text: _registering
                  ? localizations.accountRegisterButton
                  : localizations.accountSaveButton,
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
