import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/link.dart';

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
          Link(
            uri: Uri.parse('https://www.fieldkit.org/terms-and-conditions'),
            target: LinkTarget.blank,
            builder: (BuildContext ctx, FollowLink? openLink) {
              return ListTile(
                onTap: openLink,
                title: Text(AppLocalizations.of(context)!.termsOfService),
              );
            },
          ),
          const Divider(),
          Link(
            uri: Uri.parse('https://www.fieldkit.org/privacy-policy'),
            target: LinkTarget.blank,
            builder: (BuildContext ctx, FollowLink? openLink) {
              return ListTile(
                onTap: openLink,
                title: Text(AppLocalizations.of(context)!.privacyPolicy),
              );
            },
          ),
          const Divider(),
          Link(
            uri: Uri.parse('https://www.fieldkit.org/licenses'),
            target: LinkTarget.blank,
            builder: (BuildContext ctx, FollowLink? openLink) {
              return ListTile(
                onTap: openLink,
                title: Text(AppLocalizations.of(context)!.licenses),
              );
            },
          ),
        ],
      ),
    );
  }
}
