import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:fk/common_widgets.dart';
import '../constants.dart';

import '../app_state.dart';
import '../diagnostics.dart';
import '../splash_screen.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<PortalAccounts>();

    // If there are no accounts, display a custom message and an image
    if (accounts.accounts.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.accountsTitle),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.accountsNoneCreatedTitle,
                  style: const TextStyle(
                      fontSize: 20.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0), // Spacer
                Image.asset('resources/flows/uploads/Fieldkit_couple2.png'),
                const SizedBox(height: 20.0), // Spacer
                Text(
                  AppLocalizations.of(context)!.accountsNoneCreatedMessage,
                  style: const TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40.0), // Spacer
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditAccountPage(
                            original: PortalAccount(
                                email: "",
                                name: "",
                                tokens: null,
                                active: false)),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        AppColors.primaryColor),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.symmetric(
                            vertical: 24.0, horizontal: 32.0)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.accountsAddButton,
                    style: const TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          ]),
        ),
      );
    }

    // If there are accounts, display the regular content

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountsTitle),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAccountPage(
                        original: PortalAccount(
                            email: "", name: "", tokens: null, active: false)),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context)!.accountsAddButton,
                  style: const TextStyle(color: Colors.white)))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(children: [
              AccountsList(
                  accounts: accounts,
                  onActivate: (account) async {
                    await accounts.activate(account);
                  },
                  onLogin: (account) async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditAccountPage(
                            original: PortalAccount(
                                email: account.email,
                                name: account.name,
                                tokens: null,
                                active: false)),
                      ),
                    );
                  },
                  onDelete: (account) async {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(AppLocalizations.of(context)!
                                .confirmDeleteAccountTitle),
                            content: Text(
                                AppLocalizations.of(context)!.confirmDelete),
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(AppLocalizations.of(context)!
                                      .confirmCancel)),
                              TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await accounts.delete(account);
                                  },
                                  child: Text(
                                      AppLocalizations.of(context)!.confirmYes))
                            ],
                          );
                        });
                  }),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAccountPage(
                        original: PortalAccount(
                            email: "", name: "", tokens: null, active: false)),
                  ),
                );
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(AppColors.primaryColor),
                padding: MaterialStateProperty.all<EdgeInsets>(
                    const EdgeInsets.symmetric(
                        vertical: 24.0, horizontal: 32.0)),
              ),
              child: Text(
                AppLocalizations.of(context)!.accountsAddButton,
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountsList extends StatelessWidget {
  final PortalAccounts accounts;
  final void Function(PortalAccount) onActivate;
  final void Function(PortalAccount) onDelete;
  final void Function(PortalAccount) onLogin;

  const AccountsList(
      {super.key,
      required this.accounts,
      required this.onActivate,
      required this.onDelete,
      required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final items = accounts.accounts
        .map(
          (account) => AccountItem(
              account: account,
              onActivate: () => onActivate(account),
              onLogin: () => onLogin(account),
              onDelete: () => onDelete(account)),
        )
        .toList();
    return Column(children: items);
  }
}

class AccountStatus extends StatelessWidget {
  final Validity validity;
  final bool active;

  const AccountStatus(
      {super.key, required this.validity, required this.active});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    text(value) => Container(
        width: double.infinity, margin: WH.pagePadding, child: Text(value));

    switch (validity) {
      case Validity.connectivity:
        return ColoredBox(
            color: const Color.fromRGBO(250, 197, 89, 1),
            child: text(localizations.accountConnectivity));
      case Validity.unknown:
        return ColoredBox(
            color: const Color.fromRGBO(250, 197, 89, 1),
            child: text(localizations.accountUnknown));
      case Validity.invalid:
        return ColoredBox(
            color: const Color.fromRGBO(240, 144, 141, 1),
            child: text(localizations.accountInvalid));
      case Validity.valid:
        if (active) {
          return text(localizations.accountDefault);
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
  final VoidCallback onLogin;

  const AccountItem(
      {super.key,
      required this.account,
      required this.onActivate,
      required this.onDelete,
      required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BorderedListItem(
        header:
            GenericListItemHeader(title: account.email, subtitle: account.name),
        children: [
          WH.align(AccountStatus(
              validity: account.validity, active: account.active)),
          WH.align(WH.padChildrenPage([
            Row(
              children: WH.padButtonsRow([
                ElevatedButton(
                    onPressed: onDelete,
                    child: Text(localizations.accountDeleteButton)),
                if (account.validity != Validity.valid)
                  ElevatedButton(
                      onPressed: onLogin,
                      child: Text(localizations.accountRepairButton)),
              ]),
            )
          ]))
        ]);
  }
}

class EditAccountPage extends StatelessWidget {
  final PortalAccount original;

  const EditAccountPage({super.key, required this.original});

  @override
  Widget build(BuildContext context) {
    return AccountForm(original: original);
  }
}

class AccountForm extends StatefulWidget {
  final PortalAccount original;

  const AccountForm({super.key, required this.original});

  @override
  // ignore: library_private_types_in_public_api
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<AccountForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _passwordVisible = false;

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
                    } else {
                      messenger.showSnackBar(SnackBar(
                        content: Text(localizations.accountFormFail),
                      ));
                    }
                  } catch (error) {
                    Loggers.portal.e("$error");
                  } finally {
                    overlay.hide();
                  }
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
                localizations.accountSaveButton,
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
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

class ProvideAccountsWidget extends StatelessWidget {
  final Widget child;

  const ProvideAccountsWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final accounts = context.read<AppState>().portalAccounts;
    return FutureBuilder<PortalAccounts>(
        future: Future.wait([
          accounts.load().then((a) => a.validate()),
          Future.delayed(const Duration(seconds: 0))
        ]).then((responses) => responses[0]),
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
