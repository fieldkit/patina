import 'package:fk/diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../reader/screens.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  _HelpPageState createState() => _HelpPageState();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.helpTitle),
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
            title: Text(AppLocalizations.of(context)!.tutorialGuide),
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
            title: Text(AppLocalizations.of(context)!.helpUploadLogs),
            onTap: () {
              ShareDiagnostics().upload();
            },
          ),
          const Divider(),
          ListTile(
            title: Text(AppLocalizations.of(context)!.appVersion),
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
                          text: AppLocalizations.of(context)!.appVersion,
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
}
