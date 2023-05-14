import 'package:flutter/material.dart';

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
              body: Center(
                child: ElevatedButton(
                  child: const Text('Settings'),
                  onPressed: () {},
                ),
              ),
            );
          });
    });
  }
}
