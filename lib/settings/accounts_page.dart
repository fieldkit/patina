import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_rust_bridge_template/common_widgets.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../splash_screen.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<PortalAccounts>();

    debugPrint("accounts-page:build");

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.accountsTitle),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditAccountPage(original: PortalAccount(email: "", name: "", tokens: null, active: false)),
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context)!.accountsAddButton, style: const TextStyle(color: Colors.white)))
          ],
        ),
        body: ListView(children: [
          AccountsList(
              accounts: accounts,
              onActivate: (account) async {
                await accounts.activate(account);
              },
              onDelete: (account) async {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(AppLocalizations.of(context)!.confirmDeleteTitle),
                        content: Text(AppLocalizations.of(context)!.confirmDelete),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(AppLocalizations.of(context)!.confirmCancel)),
                          TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await accounts.delete(account);
                              },
                              child: Text(AppLocalizations.of(context)!.confirmYes))
                        ],
                      );
                    });
              }),
        ]));
  }
}

class AccountsList extends StatelessWidget {
  final PortalAccounts accounts;
  final void Function(PortalAccount) onActivate;
  final void Function(PortalAccount) onDelete;

  const AccountsList({super.key, required this.accounts, required this.onActivate, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final items = accounts.accounts
        .map(
          (account) => AccountItem(account: account, onActivate: () => onActivate(account), onDelete: () => onDelete(account)),
        )
        .toList();
    return Column(children: items);
  }
}

class AccountStatus extends StatelessWidget {
  final Validity validity;
  final bool active;

  const AccountStatus({super.key, required this.validity, required this.active});

  @override
  Widget build(BuildContext context) {
    text(value) => Container(width: double.infinity, margin: const EdgeInsets.all(5), child: Text(value));

    switch (validity) {
      case Validity.unknown:
        return ColoredBox(color: const Color.fromRGBO(250, 197, 89, 1), child: text("Odd, not sure about this account. Bug?"));
      case Validity.invalid:
        return ColoredBox(color: const Color.fromRGBO(240, 144, 141, 1), child: text("Something is wrong with this account."));
      case Validity.valid:
        if (active) {
          return text("This is your default account.");
        } else {
          return const SizedBox.shrink();
        }
    }
  }
}

class AccountItem extends StatelessWidget {
  final PortalAccount account;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const AccountItem({super.key, required this.account, required this.onActivate, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BorderedListItem(header: GenericListItemHeader(title: account.email, subtitle: account.name), children: [
      WH.align(AccountStatus(validity: account.valid, active: account.active)),
      WH.align(WH.padChildrenPage([
        ElevatedButton(
            onPressed: () {
              onDelete();
            },
            child: Text(localizations.accountDeleteButton))
      ]))
    ]);
  }
}

class EditAccountPage extends StatelessWidget {
  final PortalAccount original;

  const EditAccountPage({super.key, required this.original});

  @override
  Widget build(BuildContext context) {
    return AccountForm(original: original, onSave: (account) {});
  }
}

class AccountForm extends StatefulWidget {
  final PortalAccount original;
  final void Function(PortalAccount) onSave;

  const AccountForm({super.key, required this.original, required this.onSave});

  @override
  // ignore: library_private_types_in_public_api
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<AccountForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final accounts = context.read<PortalAccounts>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountEditTitle),
      ),
      body: FormBuilder(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FormBuilderTextField(
              name: 'email',
              decoration: InputDecoration(labelText: localizations.accountEmail),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.email(),
              ]),
            ),
            FormBuilderTextField(
              name: 'password',
              decoration: InputDecoration(labelText: localizations.accountPassword),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(10),
              ]),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.saveAndValidate()) {
                  final overlay = context.loaderOverlay;
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final email = _formKey.currentState!.value['email'];
                  final password = _formKey.currentState!.value['password'];
                  overlay.show();
                  try {
                    final saved = await accounts.addOrUpdate(email, password);
                    if (saved != null) {
                      navigator.pop();
                      widget.onSave(saved);
                    } else {
                      messenger.showSnackBar(SnackBar(
                        content: Text(localizations.accountFormFail),
                      ));
                    }
                  } catch (error) {
                    debugPrint("$error");
                  } finally {
                    overlay.hide();
                  }
                }
              },
              child: Text(localizations.accountSaveButton),
            ),
          ].map((child) => Padding(padding: const EdgeInsets.all(8), child: child)).toList(),
        ),
      ),
    );
  }
}

class ProvideAccountsWidget extends StatelessWidget {
  final Widget child;

  const ProvideAccountsWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final accounts = context.read<AppState>().portalAccounts;
    return FutureBuilder<PortalAccounts>(
        future: Future.wait([accounts.load().then((a) => a.validate()), Future.delayed(const Duration(seconds: 1))])
            .then((responses) => responses[0]),
        builder: (context, AsyncSnapshot<PortalAccounts> snapshot) {
          if (snapshot.hasData) {
            return ChangeNotifierProvider(
              create: (context) => snapshot.data!,
              child: child,
            );
          } else {
            return const FullScreenLogo();
          }
        });
  }
}
