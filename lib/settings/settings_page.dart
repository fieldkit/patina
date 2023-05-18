import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../gen/ffi.dart';
import '../reader/widgets.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) {
            return Scaffold(
                appBar: AppBar(
                  title: const Text('Settings'),
                ),
                body: ListView(children: [
                  ListTile(
                    title: const Text("Accounts"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProvideAccountsWidget(child: AccountsPage()),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text("Open Flow"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProvideContentFlowsWidget(child: QuickFlow(start: StartFlow(name: "onboarding"))),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ]));
          });
    });
  }
}

class ProvideAccountsWidget extends StatelessWidget {
  final Widget child;

  const ProvideAccountsWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PortalAccounts>(
        future: PortalAccounts.get(api), // Global Native/API access
        builder: (context, AsyncSnapshot<PortalAccounts> snapshot) {
          if (snapshot.hasData) {
            return ChangeNotifierProvider(
              create: (context) => snapshot.data!,
              child: child,
            );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<PortalAccounts>();

    return Scaffold(
        appBar: AppBar(
          title: const Text('Accounts'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditAccountPage(original: PortalAccount(email: "", token: "", refreshToken: "", active: false)),
                    ),
                  );
                },
                child: const Text("Add", style: TextStyle(color: Colors.white)))
          ],
        ),
        body: ListView(children: [
          AccountsList(
              accounts: accounts,
              onActivate: (account) {
                accounts.activate(account);
              }),
        ]));
  }
}

class AccountsList extends StatelessWidget {
  final PortalAccounts accounts;
  final void Function(PortalAccount) onActivate;

  const AccountsList({super.key, required this.accounts, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    final items = accounts.accounts
        .map(
          (account) => AccountItem(account: account, onActivate: () => onActivate(account)),
        )
        .toList();
    return Column(children: items);
  }
}

class AccountItem extends StatelessWidget {
  final PortalAccount account;
  final VoidCallback onActivate;

  const AccountItem({super.key, required this.account, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: account.active
          ? const Icon(Icons.check)
          : const Icon(
              Icons.check,
              color: Color.fromRGBO(255, 255, 255, 0), // Transparent.
            ),
      title: Text(account.email),
      onTap: () {
        onActivate();
      },
    );
  }
}

class EditAccountPage extends StatefulWidget {
  final PortalAccount original;

  const EditAccountPage({super.key, required this.original});

  @override
  // ignore: library_private_types_in_public_api
  _EditAccountState createState() => _EditAccountState();
}

class _EditAccountState extends State<EditAccountPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Account'),
        ),
        body: ListView(children: const []));
  }
}
