import 'package:fk/gen/bridge_definitions.dart';
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

  const CalibrationSection(
      {super.key, required this.point, required this.calibration});

  double _determineFontSize(double screenWidth) {
    if (screenWidth < 320) {
      return 16;
    } else if (screenWidth < 480) {
      return 20;
    } else {
      return 26;
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
    double containerPadding = _determineContainerPadding(screenWidth);
    double arrowSize = screenWidth < 360 ? 30 : 40;
    var valueStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      fontFamily: "Avenir",
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
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: "Avenir"),
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
                      value(point.uncalibrated[0]),
                      Text(
                        AppLocalizations.of(context)!.uncalibrated,
                        style: const TextStyle(
                          fontFamily: "Avenir",
                          fontSize: 12,
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
                            value(calibration_calc.calibrateValue(
                                calibration.type,
                                point.uncalibrated[0],
                                calibration.points)),
                            Text(
                              AppLocalizations.of(context)!.calibrated,
                              style: const TextStyle(
                                fontFamily: "Avenir",
                                fontSize: 14,
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

  const CalibrationWidget({super.key, required this.calibration});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...calibration.points
            .map((p) => CalibrationSection(point: p, calibration: calibration))
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
    final DateFormat formatter = DateFormat('hh:mm a yyyy-MM-dd');
    final formatted = formatter.format(time);
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromRGBO(212, 212, 212, 1),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(5))),
      padding: const EdgeInsets.all(8),
      child:
          Text(formatted, style: const TextStyle(fontWeight: FontWeight.w300)),
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
          title: Text(
              "${AppLocalizations.of(context)!.calibrationTitle} - ${localized.name}"),
        ),
        body: LayoutBuilder(// Use LayoutBuilder to get available width
            builder: (context, constraints) {
          return ListView(
              children: <Widget>[
            Row(children: [
              Image(image: localized.icon, width: 50, height: 50),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        localized.name,
                        style: const TextStyle(fontSize: 18),
                      )),
                  Text(bay),
                ],
              ),
            ]),
            Wrap(
              direction: Axis.horizontal,
              spacing: 8.0,
              runSpacing: 4.0,
              children: calibrations
                  .map((c) => SizedBox(
                      width: (constraints.maxWidth / calibrations.length) - 100,
                      child: TimeWidget(calibration: c)))
                  .toList(),
            ),
            ...calibrations.map((c) => CalibrationWidget(calibration: c)),
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
                                                CalibrationPage(config: config),
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
              ].map(WH.padPage).toList(),
            )
          ].map(WH.padPage).toList());
        }));
  }
}
