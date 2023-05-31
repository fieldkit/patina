import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'gen/ffi.dart';

import 'app_state.dart';
import 'map_widget.dart';
import 'view_station/view_station_page.dart';

class StationsTab extends StatelessWidget {
  const StationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(onGenerateRoute: (RouteSettings settings) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => Consumer<KnownStationsModel>(
          builder: (context, knownStations, child) {
            return ListStationsPage(known: knownStations);
          },
        ),
      );
    });
  }
}

class ListStationsPage extends StatelessWidget {
  final KnownStationsModel known;

  const ListStationsPage({super.key, required this.known});

  @override
  Widget build(BuildContext context) {
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
          title: Text(AppLocalizations.of(context)!.myStationsTitle),
        ),
        body: ListView(children: map + cards));
  }
}

class StationCard extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const StationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    var icon = Icon(Icons.aod_rounded, color: station.connected ? Colors.blue : Colors.grey);
    var subtitle = station.busy ? Text(AppLocalizations.of(context)!.busyTransferring) : Text(AppLocalizations.of(context)!.readyToDeploy);

    return Container(
        padding: const EdgeInsets.all(10),
        child: ListTile(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(5),
          ),
          title: Container(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(config.name)),
          subtitle: subtitle,
          trailing: icon,
          dense: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewStationRoute(deviceId: station.deviceId),
              ),
            );
          },
        ));
  }
}

class DiscoveringStationCard extends StatelessWidget {
  final StationModel station;

  const DiscoveringStationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.contacting),
    );
  }
}
