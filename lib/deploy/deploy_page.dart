import 'package:fk/app_state.dart';
import 'package:fk/gen/bridge_definitions.dart';
import 'package:fk/map_widget.dart';
import 'package:fk/providers.dart';
import 'package:fk/unknown_station_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DeployStationPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const DeployStationPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final Widget map = const SizedBox(height: 200, child: MapWidget());
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.deployTitle),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: Size.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 0),
                Text(config.name),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        body: ListView(
          children: [map],
        ));
  }
}

class DeployStationRoute extends StatelessWidget {
  final String deviceId;

  const DeployStationRoute({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Consumer<KnownStationsModel>(
      builder: (context, knownStations, child) {
        var station = knownStations.find(deviceId);
        if (station == null) {
          return const NoSuchStationPage();
        } else {
          return StationProviders(
              deviceId: deviceId, child: DeployStationPage(station: station));
        }
      },
    );
  }
}
