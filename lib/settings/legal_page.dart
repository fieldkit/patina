import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalPage extends StatefulWidget {
  const LegalPage({super.key});

  @override
  _LegalPageState createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  bool isArrowUp = false;
  String appVersion = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.legalTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          ListTile(
            title: Text(AppLocalizations.of(context)!.termsOfService),
            onTap: () async {
              const url = 'https://www.fieldkit.org/terms-and-conditions/';
              if (await canLaunchUrl(url as Uri)) {
                await launchUrl(url as Uri);
              } else {
                throw 'Could not launch $url';
              }
            },
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.privacyPolicy),
            onTap: () async {
              const url = 'https://www.fieldkit.org/privacy-policy/';
              if (await canLaunchUrl(url as Uri)) {
                await launchUrl(url as Uri);
              } else {
                throw 'Could not launch $url';
              }
            },
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.licenses),
            onTap: () async {
              const url = 'https://www.fieldkit.org/licenses/';
              if (await canLaunchUrl(url as Uri)) {
                await launchUrl(url as Uri);
              } else {
                throw 'Could not launch $url';
              }
            },
          ),
        ],
      ),
    );
  }
}
