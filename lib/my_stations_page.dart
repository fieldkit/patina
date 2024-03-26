import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'common_widgets.dart';
import 'gen/api.dart';

import 'app_state.dart';
import 'location_widgets.dart';
import 'map_widget.dart';
import 'no_stations_widget.dart';
import 'view_station/view_station_page.dart';

class StationsTab extends StatelessWidget {
  const StationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<KnownStationsModel>(
      builder: (context, knownStations, child) {
        return ProvideLocation(child: ListStationsPage(known: knownStations));
      },
    );
  }
}

class ListStationsPage extends StatelessWidget {
  final KnownStationsModel known;

  const ListStationsPage({super.key, required this.known});

  @override
  Widget build(BuildContext context) {
    final List<Widget> map = [const SizedBox(height: 200, child: MapWidget())];

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
        body: ListView(children: [
          ...map,
          const SizedBox(
              height:
                  50.0), // Adding space under map, might have to change once cards are there. Looks good with the no stations
          ...cards,
          if (cards.isEmpty) ...[
            const NoStationsHelpWidget(showImage: false),
          ]
          // TODO: Add back in once we implement scanning for stations
          // Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 10.0),
          //   child: Text(
          //     AppLocalizations.of(context)!.stationScan,
          //     textAlign: TextAlign.center,
          //     style: const TextStyle(
          //       fontFamily: 'Avenir',
          //       fontSize: 14.0,
          //       color: Colors.grey,
          //     ),
          //   ),
          // ),
        ]));
  }
}

class TinyOperation extends StatelessWidget {
  final Operation operation;

  const TinyOperation({super.key, required this.operation});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final op = operation;
    if (op is UploadOperation) {
      return WH.align(WH.padPage(Text(localizations.busyUploading)));
    }
    if (op is DownloadOperation) {
      return WH.align(WH.padPage(Text(localizations.busyDownloading)));
    }
    if (op is UpgradeOperation) {
      return WH.align(WH.padPage(Text(localizations.busyUpgrading)));
    }
    return WH.align(WH.padPage(Text(localizations.busyWorking)));
  }
}

class StationCard extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const StationCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final operations =
        context.watch<StationOperations>().getBusy<Operation>(config.deviceId);
    final localizations = AppLocalizations.of(context)!;
    final icon = SizedBox(
        width: 54.0,
        height: 54.0,
        child: Image(
          image: AssetImage(station.connected
              ? "resources/images/Icon_Station_Connected.png"
              : "resources/images/Icon_Station_Not_Connected.png"),
        ));
    final tinyOperations =
        operations.map((op) => TinyOperation(operation: op)).toList();
    final subtitle = operations.isEmpty
        ? Text(localizations.readyToDeploy)
        : Text(localizations.busyWorking);

    return Container(
        padding: const EdgeInsets.all(10),
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromRGBO(212, 212, 212, 1),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(5))),
            child: Column(children: [
              ListTile(
                title: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(config.name)),
                subtitle: Container(
                    padding: const EdgeInsets.only(bottom: 8), child: subtitle),
                trailing: icon,
                dense: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ViewStationRoute(deviceId: station.deviceId),
                    ),
                  );
                },
              ),
              if (tinyOperations.isNotEmpty)
                Container(
                    padding: const EdgeInsets.all(6),
                    child: Column(children: tinyOperations))
            ])));
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
