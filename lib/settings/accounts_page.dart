import 'package:fk/common_widgets.dart';
import 'package:fk/settings/accounts_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

import 'edit_account_page.dart';

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
                ElevatedTextButton(
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
                  text: AppLocalizations.of(context)!.accountsAddButton,
                ),
              ],
            )
          ]),
        ),
      );
    }

    final localizations = AppLocalizations.of(context)!;

    // If there are accounts, display the regular content
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.accountsTitle),
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
              child: Text(localizations.accountsAddButton,
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
                    await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title:
                                Text(localizations.confirmDeleteAccountTitle),
                            content: Text(localizations.confirmDelete),
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(localizations.confirmCancel)),
                              TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await accounts.delete(account);
                                  },
                                  child: Text(localizations.confirmYes))
                            ],
                          );
                        });
                  }),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedTextButton(
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
              text: localizations.accountsAddButton,
            ),
          ),
        ],
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
    return ChangeNotifierProvider(
      create: (context) => accounts,
      child: child,
    );
  }
}
