import 'package:flutter/material.dart';

class DataSyncTab extends StatelessWidget {
  const DataSyncTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => const DataSyncRoute(),
      );
    });
  }
}

class DataSyncRoute extends StatelessWidget {
  const DataSyncRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sync'),
      ),
      body: const Center(),
    );
  }
}
