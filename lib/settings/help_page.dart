import 'package:fk/diagnostics.dart';
import 'package:fk/reader/screens.dart';
import 'package:flows/flows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/link.dart';

class HelpTab extends StatelessWidget {
  const HelpTab({super.key});

  Future<String> _getAppVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    return info.version;
  }

  final _textStyle = const TextStyle(
      fontSize: 14.0,
      fontFamily: 'Avenir',
      fontWeight: FontWeight.normal,
      color: Colors.black,
      decoration: TextDecoration.none);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.helpTitle)),
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
                        start: const StartFlow(prefix: "onboarding"),
                        onForwardEnd: () => onDone(context))),
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
            title: Text(localizations.helpCreateBackup),
            onTap: () async {
              final localizations = AppLocalizations.of(context)!;
              final messenger = ScaffoldMessenger.of(context);
              final overlay = context.loaderOverlay;
              try {
                overlay.show();
                final file = await Backup().create();
                if (file != null) {
                  final res =
                      await Share.shareXFiles([XFile(file)], text: 'Backup');

                  Loggers.ui.i("backup: $res");

                  messenger.showSnackBar(SnackBar(
                    content: Text(localizations.helpBackupCreated),
                  ));
                } else {
                  messenger.showSnackBar(SnackBar(
                    content: Text(localizations.helpBackupFailed),
                  ));
                }
              } finally {
                overlay.hide();
              }
            },
          ),
          const Divider(),
          ListTile(
            title: Text(localizations.appVersion),
          ),
          FutureBuilder<String>(
            future: _getAppVersion(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text(
                  localizations.errorLoadingVersion,
                  style: _textStyle,
                );
              } else {
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text: localizations.appVersion,
                              style: _textStyle,
                            ),
                            TextSpan(
                              text: ': ',
                              style: _textStyle,
                            ),
                            TextSpan(
                              text: snapshot.data ?? '',
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
                              text: getCommitSha() ??
                                  localizations.developerBuild,
                              style: _textStyle,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void onDone(BuildContext context) {
    Navigator.pop(
        context); // Return to the help tab after the tutorial guide is completed
  }
}
