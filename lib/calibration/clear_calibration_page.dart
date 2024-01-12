import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:fk_data_protocol/fk-data.pb.dart' as proto;

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
import 'calibration_model.dart';
import 'calibration_page.dart';

class CalibrationTable extends StatelessWidget {
  final proto.Calibration calibration;
  final List<Widget> Function() header;
  final List<Widget> Function(proto.CalibrationPoint) row;

  const CalibrationTable(
      {super.key,
      required this.calibration,
      required this.header,
      required this.row});

  @override
  Widget build(BuildContext context) {
    TableRow makeRow(List<Widget> children) => TableRow(
        children: children
            .map((c) => Padding(padding: const EdgeInsets.all(5), child: c))
            .toList());

    final points = calibration.points.map((p) => makeRow(row(p))).toList();

    return Table(
        border: TableBorder.all(),
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: <TableRow>[makeRow(header()), ...points]);
  }
}

class CalibrationWidget extends StatelessWidget {
  final proto.Calibration calibration;

  const CalibrationWidget({super.key, required this.calibration});

  @override
  Widget build(BuildContext context) {
    var headerStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    var valueStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
    );
    /*
    var unitsStyle = const TextStyle(
      fontSize: 18,
      color: Color.fromRGBO(64, 64, 64, 1),
      fontWeight: FontWeight.normal,
    );
    */

    Text header(String label) => Text(label, style: headerStyle);
    Text value(String value) => Text(value, style: valueStyle);

    final time = DateTime.fromMillisecondsSinceEpoch(calibration.time * 1000);
    final formatted = time.toIso8601String();

    final properties = Column(
      children: [
        Text(formatted),
        Text("Kind = ${calibration.kind}"),
        Text("${calibration.type}")
      ]
          .map((c) =>
              WH.align(Padding(padding: const EdgeInsets.all(5), child: c)))
          .toList(),
    );

    final table = CalibrationTable(
        calibration: calibration,
        header: () {
          return [
            header("Standard"),
            header("Factory"),
            header("Uncalibrated"),
          ];
        },
        row: (p) {
          return [
            value(p.references[0].toStringAsFixed(2)),
            value(p.factory[0].toStringAsFixed(2)),
            value(p.uncalibrated[0].toStringAsFixed(2)),
          ];
        });

    return Column(children: [properties, table]);
  }
}

class ClearCalibrationPage extends StatelessWidget {
  final CalibrationPointConfig config;

  const ClearCalibrationPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final moduleConfigurations = context.watch<ModuleConfigurations>();
    final moduleConfiguration =
        moduleConfigurations.find(config.moduleIdentity);
    final calibrations = moduleConfiguration.calibrations;
    final outerNavigator = Navigator.of(context);

    Loggers.cal.i("$calibrations");

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.calibrationTitle),
        ),
        body: ListView(
            children: <Widget>[
          ...calibrations.map((c) => CalibrationWidget(calibration: c)),
          Row(
            children: [
              ElevatedButton(
                  child: const Text("Clear"),
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
                                  child: Text(
                                      AppLocalizations.of(context)!.confirmYes))
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
        ].map(WH.padPage).toList()));
  }
}
