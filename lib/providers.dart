import 'package:fk/app_state.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class StationProviders extends StatelessWidget {
  final String deviceId;
  final Widget child;

  const StationProviders(
      {super.key, required this.deviceId, required this.child});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.read<AppState>();
    return MultiProvider(providers: [
      ChangeNotifierProvider.value(value: state.configurationFor(deviceId)),
    ], child: child);
  }
}

class ModuleProviders extends StatelessWidget {
  final ModuleIdentity moduleIdentity;
  final Widget child;

  const ModuleProviders(
      {super.key, required this.moduleIdentity, required this.child});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.read<AppState>();
    final ModuleAndStation stationAndModule =
        state.knownStations.findModule(moduleIdentity)!;
    return MultiProvider(providers: [
      ChangeNotifierProvider.value(
          value: state.configurationFor(stationAndModule.station.deviceId)),
    ], child: child);
  }
}
