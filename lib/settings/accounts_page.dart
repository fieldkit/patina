import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<PortalAccounts>();

    debugPrint("accounts-page:build");

    return Scaffold(
        appBar: AppBar(
          title: const Text('Accounts'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditAccountPage(original: PortalAccount(email: "", tokens: null, active: false)),
                    ),
                  );
                },
                child: const Text("Add", style: TextStyle(color: Colors.white)))
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
                        title: const Text("Delete Account"),
                        content: const Text("Are you sure?"),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await accounts.delete(account);
                              },
                              child: const Text('Yes'))
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

class AccountItem extends StatelessWidget {
  final PortalAccount account;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const AccountItem({super.key, required this.account, required this.onActivate, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ListTile(
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
      ),
      ElevatedButton(
          onPressed: () {
            onDelete();
          },
          child: const Text("Delete"))
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
      ),
      body: FormBuilder(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FormBuilderTextField(
              name: 'email',
              decoration: const InputDecoration(labelText: 'Email'),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.email(),
              ]),
            ),
            FormBuilderTextField(
              name: 'password',
              decoration: const InputDecoration(labelText: 'Password'),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(10),
              ]),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.saveAndValidate()) {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final email = _formKey.currentState!.value['email'];
                  final password = _formKey.currentState!.value['password'];
                  final saved = await accounts.addOrUpdate(email, password);
                  if (saved != null) {
                    navigator.pop();
                    widget.onSave(saved);
                  } else {
                    messenger.showSnackBar(const SnackBar(
                      content: Text("Invalid email or password."),
                    ));
                  }
                }
              },
              child: const Text('Save'),
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
        future: accounts.load().then((a) => a.validate()),
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

const Color logoBlue = Color.fromRGBO(27, 128, 201, 1);

class FullScreenLogo extends StatelessWidget {
  const FullScreenLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
          Image.asset("resources/images/logo_fk_blue.png"),
          const Padding(padding: EdgeInsets.only(top: 50), child: SizedBox(width: 100, height: 100, child: CircularProgressIndicator()))
        ]));
  }
}
