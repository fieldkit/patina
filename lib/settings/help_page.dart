import 'package:fk/diagnostics.dart';
import 'package:flows/flows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/link.dart';

import '../reader/screens.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
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

  final _textStyle = const TextStyle(fontSize: 20.0);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.helpTitle),
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
            title: Text(localizations.tutorialGuide),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => QuickFlow(
                        start: const StartFlow(prefix: "onboarding"), onForwardEnd: () => onDone())),
              );
            },
          ),
          const Divider(),
          Link(
            uri: Uri.parse(
                'https://www.fieldkit.org/product-guide/set-up-station/#ready-to-deploy'),
            target: LinkTarget.blank,
            builder: (BuildContext ctx, FollowLink? openLink) {
              return ListTile(
                onTap: openLink,
                title: Text(localizations.helpCheckList),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(localizations.helpUploadLogs),
            onTap: () async {
              final localizations = AppLocalizations.of(context)!;
              final messenger = ScaffoldMessenger.of(context);
              final overlay = context.loaderOverlay;
              try {
                overlay.show();
                await ShareDiagnostics().upload();
                messenger.showSnackBar(SnackBar(
                  content: Text(localizations.logsUploaded),
                ));
              } finally {
                overlay.hide();
              }
            },
          ),
          const Divider(),
          ListTile(
            title: Text(localizations.appVersion),
            trailing: Icon(
              isArrowUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 30.0,
            ),
            onTap: () {
              setState(() {
                isArrowUp = !isArrowUp;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Column(
              children: [
                if (isArrowUp)
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: localizations.appVersion,
                          style: _textStyle,
                        ),
                        TextSpan(
                          text: ': ', // Add a colon and space
                          style: _textStyle,
                        ),
                        TextSpan(
                          text: appVersion,
                          style: _textStyle,
                        ),
                        TextSpan(
                          text: '\n',
                          style: _textStyle,
                        ),
                        TextSpan(
                          text: getCommitRefName() ??
                              localizations.developerBuild,
                          style: _textStyle,
                        ),
                        TextSpan(
                          text: '\n',
                          style: _textStyle,
                        ),
                        TextSpan(
                          text: getCommitSha() ?? localizations.developerBuild,
                          style: _textStyle,
                        ),
                      ],
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
  
  onDone() {
    Navigator.of(context).pop(); // Return to the page after the tutorial
  }
}
