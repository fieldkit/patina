import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

import 'language_page.dart';
import 'accounts_page.dart';
import 'help_page.dart';
import 'legal_page.dart';

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
            leading: const Icon(Icons.account_circle),
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
            leading: SvgPicture.asset(
                      "resources/images/icon_help.svg",
                      semanticsLabel: 'Help Settings Icon',
                    ),
            title: Text(AppLocalizations.of(context)!.helpTitle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shield_sharp),
            title: Text(AppLocalizations.of(context)!.settingsLanguage),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguagePage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shield_sharp),
            title: Text(AppLocalizations.of(context)!.legalTitle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LegalPage()),
              );
            },
          ),
        ]));
  }
}
