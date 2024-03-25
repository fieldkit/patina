import 'package:collection/collection.dart';
import 'package:fk/app_state.dart';
import 'package:fk/gen/bridge_definitions.dart';
import 'package:fk/view_station/module_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StationModulesPage extends StatelessWidget {
  final StationModel station;

  StationConfig get config => station.config!;

  const StationModulesPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final modules = config.modules
        .sorted(defaultModuleSorter)
        .map((module) => StationModuleWidget(module: module))
        .toList();

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.modulesTitle),
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
          children: modules,
        ));
  }
}

class StationModuleWidget extends StatelessWidget {
  final ModuleConfig module;

  const StationModuleWidget({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return ModuleInfo(
      module: module,
      showSensors: false,
      alwaysShowCalibrate: true,
    );
  }
}
