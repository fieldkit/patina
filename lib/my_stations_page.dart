import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'station_details_page.dart';
import 'map_widget.dart';

class StationsTab extends StatelessWidget {
  const StationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("stations:build");

    return Navigator(onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => Consumer<KnownStationsModel>(
          builder: (context, knownStations, child) {
            return ListStationsRoute(stations: knownStations.stations);
          },
        ),
      );
    });
  }
}

class ListStationsRoute extends StatelessWidget {
  const ListStationsRoute({super.key, required this.stations});

  final List<Station> stations;

  @override
  Widget build(BuildContext context) {
    debugPrint("list-stations:build");

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stations'),
      ),
      body: ListView.builder(
        itemCount: stations.length + 1,
        itemBuilder: (context, index) {
          // This is a huge hack, but was the fastest way to get this working
          // and shouldn't leak outside of this class.
          if (index == 0) {
            return const SizedBox(height: 300, child: Map());
          }

          return ListTile(
            title: Text(stations[index - 1].name ?? "..."),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ViewStationRoute(station: stations[index - 1]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
