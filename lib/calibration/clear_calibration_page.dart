import 'package:fk/gen/bridge_definitions.dart';
import 'package:fk/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fk_data_protocol/fk-data.pb.dart' as proto;

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
import '../meta.dart';
import 'calibration_model.dart';
import 'calibration_page.dart';

class CalibrationSection extends StatelessWidget {
  final proto.CalibrationPoint point;

  const CalibrationSection({super.key, required this.point});

  @override
  Widget build(BuildContext context) {
    var valueStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
    );

    Text value(double val) => Text(val.toStringAsFixed(2), style: valueStyle);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromRGBO(212, 212, 212, 1),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Standard: ${point.references[0].toStringAsFixed(2)}", // TODO l10n
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.factory),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromRGBO(212, 212, 212, 1),
                        ),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5))),
                    padding: const EdgeInsets.all(8),
                    child: value(point.factory[0]),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward, size: 40, color: Colors.black54),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.uncalibrated), //TODO: l10n
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromRGBO(212, 212, 212, 1),
                        ),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5))),
                    padding: const EdgeInsets.all(8),
                    child: value(point.uncalibrated[0]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CalibrationWidget extends StatelessWidget {
  final proto.Calibration calibration;

  const CalibrationWidget({super.key, required this.calibration});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(calibration.time * 1000);
    final DateFormat formatter = DateFormat('HH:mm yyyy-MM-dd');
    final formatted = formatter.format(time);

    final properties = Container(
      decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromRGBO(212, 212, 212, 1),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(5))),
      padding: const EdgeInsets.all(8),
      child:
          Text(formatted, style: const TextStyle(fontWeight: FontWeight.w300)),
    );

    return Column(
      children: [
        properties,
        ...calibration.points.map((p) => CalibrationSection(point: p)).toList(),
      ],
    );
  }
}

class ClearCalibrationPage extends StatelessWidget {
  final CalibrationPointConfig config;
  final ModuleConfig module;

  const ClearCalibrationPage(
      {super.key, required this.config, required this.module});

  @override
  Widget build(BuildContext context) {
    final moduleConfigurations = context.watch<ModuleConfigurations>();
    final moduleConfiguration =
        moduleConfigurations.find(config.moduleIdentity);
    final calibrations = moduleConfiguration.calibrations;
    final outerNavigator = Navigator.of(context);
    final localized = LocalizedModule.get(module);
    final bay = AppLocalizations.of(context)!.bayNumber(module.position);

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.calibrationTitle),
        ),
        body: ListView(
            children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            Image(image: localized.icon, width: 50, height: 50),
            Text(localized.name),
            Text(bay),
          ]),
          ...calibrations.map((c) => CalibrationWidget(calibration: c)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(AppLocalizations.of(context)!.calibrationBack),
                  ),
                  onPressed: () {
                    Loggers.cal.i("keeping calibration");
                    final navigator = Navigator.of(context);
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) => CalibrationPage(config: config),
                      ),
                    );
                  }),
              ElevatedButton(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child:
                        Text(AppLocalizations.of(context)!.calibrationDelete),
                  ),
                  onPressed: () async {
                    showDialog(
                        context: context,
                        builder: (context) {
                          final localizations = AppLocalizations.of(context)!;
                          final navigator = Navigator.of(context);

                          return AlertDialog(
                            title: Text(
                                localizations.confirmClearCalibrationTitle),
                            content: Text(localizations.confirmDelete),
                            actions: <Widget>[
                              TextButton(
                                  onPressed: () {
                                    navigator.pop();
                                  },
                                  child: Text(localizations.confirmCancel)),
                              TextButton(
                                  onPressed: () async {
                                    navigator.pop();
                                    try {
                                      Loggers.cal.i("clearing calibration");
                                      await moduleConfigurations
                                          .clear(config.moduleIdentity);
                                      Loggers.cal.i("cleared!");
                                      outerNavigator.push(
                                        MaterialPageRoute(
                                          builder: (context) => ModuleProviders(
                                              moduleIdentity:
                                                  config.moduleIdentity,
                                              child: CalibrationPage(
                                                  config: config)),
                                        ),
                                      );
                                    } catch (e) {
                                      Loggers.cal.e("Exception clearing: $e");
                                    }
                                  },
                                  child: Text(
                                      AppLocalizations.of(context)!.confirmYes))
                            ],
                          );
                        });
                  }),
            ].map(WH.padPage).toList(),
          )
        ].map(WH.padPage).toList()));
  }
}
