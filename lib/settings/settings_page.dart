import 'package:flutter/material.dart';

import '../reader/widgets.dart';
import 'accounts_page.dart';

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
                          builder: (context) => const AccountsPage(),
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
