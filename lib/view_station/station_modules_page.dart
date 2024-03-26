import 'package:collection/collection.dart';
import 'package:fk/app_state.dart';
import 'package:fk/gen/api.dart';
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
          centerTitle: true,
          title: Column(
            children: [
              Text(AppLocalizations.of(context)!.modulesTitle),
              Text(
                config.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
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
