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
      if (station.config == null) {
        return DiscoveringStationCard(station: station);
      } else {
        return StationCard(station: station);
      }
    }).toList();

    return Scaffold(
        appBar: AppBar(
          title: const Text('My Stations'),
        ),
        body: ListView(children: map + cards));
  }
}

class DiscoveringStationCard extends StatelessWidget {
  final StationModel station;

  const DiscoveringStationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      title: Text("..."),
    );
  }
}

class StationCard extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const StationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(config.name),
      onTap: () {
        pushViewStationRoute(context, station);
      },
    );
  }
}

void pushViewStationRoute(BuildContext context, StationModel station) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ViewStationRoute(station: station),
    ),
  );
}
