import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../gen/ffi.dart';

class DataSyncTab extends StatelessWidget {
  const DataSyncTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => Consumer<KnownStationsModel>(
          builder: (context, knownStations, child) {
            return DataSyncPage(known: knownStations);
          },
        ),
      );
    });
  }
}

class DataSyncPage extends StatelessWidget {
  final KnownStationsModel known;

  const DataSyncPage({super.key, required this.known});

  @override
  Widget build(BuildContext context) {
    final stations =
        known.stations.where((station) => station.config != null).map((station) => StationSyncStatus(station: station)).toList();

    return Scaffold(
        appBar: AppBar(
          title: const Text('Data Sync'),
        ),
        body: ListView(children: stations));
  }
}

class StationSyncStatus extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const StationSyncStatus({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          ListTile(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(5),
            ),
            title: Container(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(config.name)),
            subtitle: const Text("Ready to sync"),
            dense: false,
            onTap: () {},
          ),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(onPressed: () {}, child: const Text("Download"))),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(onPressed: () {}, child: const Text("Upload")))
        ]));
  }
}
