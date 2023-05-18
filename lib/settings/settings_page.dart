import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class PortalAccount extends ChangeNotifier {
  final String email;
  final bool active;

  PortalAccount({required this.email, required this.active});
}

class PortalAccounts extends ChangeNotifier {
  final Native api;
  final List<PortalAccount> _accounts = List.empty(growable: true);

  UnmodifiableListView<PortalAccount> get accounts => UnmodifiableListView(_accounts);

  PortalAccounts({required this.api}) {
    _accounts.add(PortalAccount(email: "jacob@conservify.org", active: true));
    _accounts.add(PortalAccount(email: "carla@conservify.org", active: false));
  }

  void activate(PortalAccount account) async {
    debugPrint("activating $account");
    var updated = _accounts.map((iter) {
      return PortalAccount(email: iter.email, active: account == iter);
    }).toList();
    _accounts.clear();
    _accounts.addAll(updated);
    notifyListeners();
  }
}

class ProvideAccountsWidget extends StatelessWidget {
  final Widget child;

  const ProvideAccountsWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PortalAccounts(api: api), // Global Native/API access
      child: child,
    );
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
