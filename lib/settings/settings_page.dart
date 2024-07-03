import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'language_page.dart';
import 'accounts_page.dart';
import 'help_page.dart';
import 'legal_page.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  final colorFilter = const ColorFilter.mode( Color(0xFF2c3e50), BlendMode.srcIn);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settingsTitle),
        ),
        body: ListView(children: [
          ListTile(
            leading: 
            SvgPicture.asset(
              "resources/images/icon_account_settings.svg",
              semanticsLabel: 'Account Settings Icon'),
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
              "resources/images/icon_help_settings.svg",
              semanticsLabel: 'Help Settings Icon'),
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
            leading: SvgPicture.asset(
              "resources/images/icon_globe.svg",
              semanticsLabel: 'Language Settings Icon', colorFilter: colorFilter),
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
            leading: SvgPicture.asset(
              "resources/images/icon_legal_settings.svg",
              semanticsLabel: 'Legal Settings Icon'),
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
