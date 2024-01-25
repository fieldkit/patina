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
import 'calibration_calculations.dart' as calibration_calc;

class CalibrationSection extends StatelessWidget {
  final proto.Calibration calibration;
  final proto.CalibrationPoint point;
  final String? uom;

  const CalibrationSection(
      {super.key,
      required this.point,
      required this.calibration,
      required this.uom});

  double _determineFontSize(double screenWidth) {
    if (screenWidth < 320) {
      return 12;
    } else if (screenWidth < 480) {
      return 16;
    } else {
      return 24;
    }
  }

  double _determineLabelSize(double screenWidth) {
    if (screenWidth < 320) {
      return 10;
    } else if (screenWidth < 480) {
      return 12;
    } else {
      return 18;
    }
  }

  double _determineContainerPadding(double screenWidth) {
    if (screenWidth < 320) {
      return 6;
    } else if (screenWidth < 480) {
      return 8;
    } else {
      return 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = _determineFontSize(screenWidth);
    double labelSize = _determineLabelSize(screenWidth);
    double containerPadding = _determineContainerPadding(screenWidth);
    double arrowSize = screenWidth < 360 ? 25 : 40;

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
            OverflowBar(
              alignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "${AppLocalizations.of(context)!.standardTitle}: ${point.references[0].toStringAsFixed(1)} $uom",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: "Avenir"),
                ),
                Text(
                    "${AppLocalizations.of(context)!.voltage}: ${point.uncalibrated[0].toStringAsFixed(1)} V",
                    style: const TextStyle(
                      fontFamily: "Avenir",
                      fontSize: 12,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  color: Colors.grey[100],
                  padding: EdgeInsets.all(containerPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${point.factory[0].toStringAsFixed(1)} $uom",
                          style: TextStyle(
                            fontSize: fontSize,
                            fontFamily: "Avenir",
                          )),
                      Text(
                        AppLocalizations.of(context)!.factory,
                        style: TextStyle(
                          fontSize: labelSize,
                          fontFamily: "Avenir",
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward,
                    size: arrowSize, color: Colors.black54),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                        color: Colors.grey[100],
                        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "${calibration_calc.calibrateValue(calibration.type, point.uncalibrated[0], calibration.points).toStringAsFixed(1)} $uom",
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: "Avenir",
                                )),
                            Text(
                              AppLocalizations.of(context)!.calibrated,
                              style: TextStyle(
                                fontSize: labelSize,
                                fontFamily: "Avenir",
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ],
            ),
          ],
        ));
  }
}

class CalibrationWidget extends StatelessWidget {
  final proto.Calibration calibration;
  final String? uom;

  const CalibrationWidget({super.key, required this.calibration, this.uom});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...calibration.points
            .map((p) => CalibrationSection(
                point: p, calibration: calibration, uom: uom))
            .toList(),
      ],
    );
  }
}

class TimeWidget extends StatelessWidget {
  final proto.Calibration calibration;

  const TimeWidget({super.key, required this.calibration});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(calibration.time * 1000);
    final DateFormat formatter1 = DateFormat('yyyy-MM-dd');
    final DateFormat formatter2 = DateFormat('hh:mm a ');
    final formatted = formatter1.format(time);
    return Container(
        decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(
              color: const Color.fromRGBO(212, 212, 212, 1),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        padding: const EdgeInsets.all(8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Text(formatted,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: "Avenir")),
              const Text(" "),
              Text(formatter2.format(time),
                  style: const TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 12,
                      fontFamily: "Avenir")),
            ],
          ),
          const Text(("Last Calibrated"),
              style: TextStyle(fontSize: 12, fontFamily: "Avenir")),
        ]));
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
    final uom = module.calibrationSensor?.calibratedUom;
    final bay = AppLocalizations.of(context)!.bayNumber(module.position);

    return Scaffold(
        appBar: AppBar(
          title: Text(
              "${AppLocalizations.of(context)!.calibrationTitle} - ${localized.name}"),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return ListView(
              children: <Widget>[
            Row(children: [
              Image(image: localized.icon, width: 50, height: 50),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: constraints.maxWidth - 70,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            localized.name,
                            style: const TextStyle(fontSize: 18),
                          )),
                    ),
                  ),
                  Text(bay, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ]),
            Wrap(
              direction: Axis.horizontal,
              spacing: 8.0,
              runSpacing: 4.0,
              children: calibrations
                  .map((c) => SizedBox(
                      width: constraints.maxWidth,
                      child: TimeWidget(calibration: c)))
                  .toList(),
            ),
            ...calibrations
                .map((c) => CalibrationWidget(calibration: c, uom: uom)),
            ButtonBar(
              alignment: MainAxisAlignment.spaceAround,
              buttonMinWidth: 100,
              buttonPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              children: [
                ElevatedButton(
                    child: Text(AppLocalizations.of(context)!.calibrationBack),
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
                    child:
                        Text(AppLocalizations.of(context)!.calibrationDelete),
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
                                            builder: (context) =>
                                                ModuleProviders(
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
                                    child: Text(AppLocalizations.of(context)!
                                        .confirmYes))
                              ],
                            );
                          });
                    }),
                ElevatedButton(
                    child: const Text("Keep"), // TODO l10n
                    onPressed: () {
                      Loggers.cal.i("keeping calibration");
                      final navigator = Navigator.of(context);
                      navigator.push(
                        MaterialPageRoute(
                          builder: (context) => CalibrationPage(config: config),
                        ),
                      );
                    }),
              ].map(WH.padPage).toList(),
            )
          ].map(WH.padPage).toList());
        }));
  }
}
