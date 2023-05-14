import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'station_details_page.dart';
import 'map_widget.dart';

class StationsTab extends StatelessWidget {
  const StationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("stations-tab:build");

    return Navigator(onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => Consumer<KnownStationsModel>(
          builder: (context, knownStations, child) {
            return ListStationsRoute(known: knownStations);
          },
        ),
      );
    });
  }
}

class ListStationsRoute extends StatelessWidget {
  final KnownStationsModel known;

  const ListStationsRoute({super.key, required this.known});

  @override
  Widget build(BuildContext context) {
    debugPrint("list-stations-route:build");

    final List<Widget> map = [const SizedBox(height: 200, child: Map())];

    final cards = known.stations.map((station) {
      return StationCard(station: station);
    }).toList();

    return Scaffold(
        appBar: AppBar(
          title: const Text('My Stations'),
        ),
        body: ListView(children: map + cards));
  }
}

class DiscoveringStationCard extends StatelessWidget {
  final Station station;

  const DiscoveringStationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(station.name ?? "..."),
      onTap: () {
        pushViewStationRoute(context, station);
      },
    );
  }
}

class StationCard extends StatelessWidget {
  final Station station;

  const StationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(station.name ?? "..."),
      onTap: () {
        pushViewStationRoute(context, station);
      },
    );
  }
}

void pushViewStationRoute(BuildContext context, Station station) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ViewStationRoute(station: station),
    ),
  );
}
