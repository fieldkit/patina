import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../reader/screens.dart';
import 'accounts_page.dart';
import 'help_page.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settingsTitle),
        ),
        body: ListView(children: [
          ListTile(
            leading: const Icon(Icons.account_circle), // Icon for Accounts
            title: Text(AppLocalizations.of(context)!.settingsAccounts),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountsPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.book), // Icon for Onboarding
            title: Text(AppLocalizations.of(context)!.onboardingTitle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProvideContentFlowsWidget(
                      child: QuickFlow(start: StartFlow(name: "onboarding"))),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.question_mark), // Icon for Help
            title: Text(AppLocalizations.of(context)!.helpTitle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpPage()),
              );
            },
          ),
        ]));
  }
}
