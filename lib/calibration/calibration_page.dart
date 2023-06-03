import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_rust_bridge_template/gen/ffi.dart';
import 'package:flutter_rust_bridge_template/meta.dart';
import 'package:flutter_rust_bridge_template/view_station/sensor_widgets.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../gen/fk-data.pb.dart' as proto;
import 'countdown.dart';

enum CanContinue { form, timer, staleValue, yes }

class ClearCalibrationPage extends StatelessWidget {
  final CalibrationPointConfig config;

  const ClearCalibrationPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final moduleConfigurations = context.read<AppState>().moduleConfigurations;

    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.calibrationTitle),
        ),
        body: Column(
          children: <Widget>[
            ElevatedButton(
                child: const Text("Clear"),
                onPressed: () async {
                  debugPrint("clearing calibration");
                  final navigator = Navigator.of(context);
                  try {
                    await moduleConfigurations.clear(config.moduleIdentity);
                    debugPrint("Cleared!");
                  } catch (e) {
                    debugPrint("Exception clearing: $e");
                  }
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => CalibrationPage(config: config),
                    ),
                  );
                }),
            ElevatedButton(
                child: const Text("Keep"),
                onPressed: () {
                  debugPrint("keeping calibration");
                  final navigator = Navigator.of(context);
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => CalibrationPage(config: config),
                    ),
                  );
                }),
          ].map(WH.padPage).toList(),
        ));
  }
}

class CalibrationPage extends StatelessWidget {
  final ActiveCalibration active = ActiveCalibration();
  final CurrentCalibration? current;
  final CalibrationPointConfig config;

  CalibrationPage({super.key, this.current, required this.config});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.calibrationTitle),
        ),
        body: ChangeNotifierProvider(
            create: (context) => active,
            child: ProvideCountdown(
                duration: const Duration(seconds: 1),
                child: Consumer<CountdownTimer>(builder: (context, countdown, child) {
                  return CalibrationPanel(config: config, current: current ?? CurrentCalibration(curveType: config.curveType));
                }))));
  }
}

class CalibrationPanel extends StatelessWidget {
  final CurrentCalibration current;
  final CalibrationPointConfig config;

  const CalibrationPanel({super.key, required this.current, required this.config});

  Future<void> calibrateAndContinue(BuildContext context, SensorConfig sensor, CurrentCalibration current, ActiveCalibration active) async {
    final moduleConfigurations = context.read<AppState>().moduleConfigurations;
    final navigator = Navigator.of(context);

    final configured = config.standard;
    final standard = configured.acceptable ? configured : active.userStandard();

    current.addPoint(CalibrationPoint(standard: standard, reading: sensor.value!));

    debugPrint("(calibrate) calibration: $current");
    debugPrint("(calibrate) active: $active");

    final nextConfig = config.popStandard();
    if (nextConfig.done) {
      final cal = current.toDataProtocol();
      final serialized = current.toBytes();

      debugPrint("(calibrate) $cal");

      try {
        await moduleConfigurations.calibrate(config.moduleIdentity, serialized);
      } catch (e) {
        debugPrint("Exception calibration: $e");
      }

      navigator.popUntil((route) => route.isFirst);
    } else {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => CalibrationPage(
            config: nextConfig,
            current: current,
          ),
        ),
      );
    }
  }

  CanContinue canContinue(SensorConfig sensor, Standard standard, ActiveCalibration active, CountdownTimer countdown) {
    if (!standard.acceptable && active.invalid) {
      return CanContinue.form;
    }
    if (countdown.done) {
      final time = sensor.value?.time;
      if (time == null) {
        return CanContinue.staleValue;
      } else {
        if (time.isAfter(countdown.finished)) {
          return CanContinue.yes;
        }
        return CanContinue.staleValue;
      }
    }
    return CanContinue.timer;
  }

  @override
  Widget build(BuildContext context) {
    final knownStations = context.watch<KnownStationsModel>();
    final active = context.watch<ActiveCalibration>();
    final countdown = context.watch<CountdownTimer>();
    final mas = knownStations.findModule(config.moduleIdentity);
    final sensor = mas?.module.calibrationSensor;
    if (sensor == null) {
      return const OopsBug();
    }

    return CalibrationWait(
        config: config,
        sensor: sensor,
        canContinue: canContinue(sensor, config.standard, active, countdown),
        onCalibrateAndContinue: () => calibrateAndContinue(context, sensor, current, active));
  }
}

class CalibrationWait extends StatelessWidget {
  final CalibrationPointConfig config;
  final SensorConfig sensor;
  final VoidCallback onCalibrateAndContinue;
  final CanContinue canContinue;

  const CalibrationWait(
      {super.key, required this.config, required this.sensor, required this.onCalibrateAndContinue, required this.canContinue});

  Widget continueWidget(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    switch (canContinue) {
      case CanContinue.yes:
        return ElevatedButton(onPressed: () => onCalibrateAndContinue(), child: Text(localizations.calibrateButton));
      case CanContinue.form:
        return ElevatedButton(onPressed: null, child: Text(localizations.waitingOnForm));
      case CanContinue.timer:
        return ElevatedButton(onPressed: null, child: Text(localizations.waitingOnTimer));
      case CanContinue.staleValue:
        return ElevatedButton(onPressed: null, child: Text(localizations.waitingOnReading));
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = [
      CurrentReadingAndStandard(
        sensor: sensor,
        standard: config.standard,
      ),
      const DisplayCountdown(),
      continueWidget(context),
    ];

    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: e,
                    ))
                .toList()));
  }
}

class FixedStandardWidget extends StatelessWidget {
  final SensorConfig sensor;
  final FixedStandard standard;

  const FixedStandardWidget({super.key, required this.standard, required this.sensor});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromRGBO(212, 212, 212, 1),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(5))),
            padding: const EdgeInsets.all(8),
            child: Text(localizations.standardValue(sensor.calibratedUom, standard.value))));
  }
}

class StandardWidget extends StatelessWidget {
  final SensorConfig sensor;
  final Standard standard;

  const StandardWidget({super.key, required this.standard, required this.sensor});

  @override
  Widget build(BuildContext context) {
    if (standard is FixedStandard) {
      return FixedStandardWidget(standard: standard as FixedStandard, sensor: sensor);
    }
    return UnknownStandardWidget(standard: standard as UnknownStandard, sensor: sensor);
  }
}

class CurrentReadingAndStandard extends StatelessWidget {
  final SensorConfig sensor;
  final Standard standard;

  const CurrentReadingAndStandard({super.key, required this.sensor, required this.standard});

  @override
  Widget build(BuildContext context) {
    final localized = LocalizedSensor.get(sensor);
    final sensorValue = DisplaySensorValue(sensor: sensor, localized: localized, mainAxisSize: MainAxisSize.min);
    return Column(children: [
      sensorValue,
      StandardWidget(standard: standard, sensor: sensor),
    ]);
  }
}

class CalibrationPoint {
  final Standard standard;
  final SensorValue reading;

  CalibrationPoint({required this.standard, required this.reading});

  @override
  String toString() {
    return "CP($standard, ${reading.toDisplayString()})";
  }
}

class ActiveCalibration extends ChangeNotifier {
  double? _standard;

  double? get standard => _standard;

  bool get invalid => _standard == null;

  void haveStandard(double? standard) {
    _standard = standard;
    notifyListeners();
  }

  @override
  String toString() => "Active(standard = $_standard)";

  UserStandard userStandard() {
    return UserStandard(_standard!);
  }
}

List<double> exponentialCurve(List<CalibrationPoint> points) {
  /*
  final x = points.map((p) => p.reading.uncalibrated).toList();
  final y = points.map((p) => p.standard.value!).toList();

  function calibrationFunction([a, b, c]: [number, number, number]): (v: number) => number {
    return (t) => a + b * Math.exp(t * c);
  }

  // Pete 4/6/2022
  const options = {
      damping: 1.5,
      initialValues: _.clone([1000, 1500000, -7]),
      gradientDifference: 10e-2,
      maxIterations: 100,
      errorTolerance: 10e-3,
  };

  final fittedParams = levenbergMarquardt(data, calibrationFunction, options);
  const [a, b, c] = fittedParams.parameterValues;
  const coefficients = { a, b, c };
  */

  return [];
}

List<double> linearCurve(List<CalibrationPoint> points) {
  final n = points.length;
  final x = points.map((p) => p.reading.uncalibrated).toList();
  final y = points.map((p) => p.standard.value!).toList();

  final indices = List<int>.generate(n, (i) => i);
  final xMean = x.average;
  final yMean = y.average;
  final numerParts = indices.map((i) => (x[i] - xMean) * (y[i] - yMean));
  final denomParts = indices.map((i) => pow((x[i] - xMean), 2));
  final numer = numerParts.sum;
  final denom = denomParts.sum;

  final m = numer / denom;
  final b = yMean - m * xMean;

  return [b, m];
}

class CurrentCalibration {
  final proto.CurveType curveType;
  final List<CalibrationPoint> _points = List.empty(growable: true);

  CurrentCalibration({required this.curveType});

  @override
  String toString() => _points.toString();

  void addPoint(CalibrationPoint point) {
    _points.add(point);
  }

  proto.Calibration toDataProtocol() {
    final time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cps = _points
        .map((p) =>
            proto.CalibrationPoint(references: [p.standard.value!], uncalibrated: [p.reading.uncalibrated], factory: [p.reading.value]))
        .toList();
    final coefficients = calculateCoefficients();
    return proto.Calibration(time: time, type: curveType, points: cps, coefficients: proto.CalibrationCoefficients(values: coefficients));
  }

  List<double> calculateCoefficients() {
    return linearCurve(_points);
  }

  Uint8List toBytes() {
    return toDataProtocol().writeToBuffer();
  }
}

class CalibrationPointConfig {
  final ModuleIdentity moduleIdentity;
  final proto.CurveType curveType;
  final List<Standard> standardsRemaining;
  final bool offline;

  Standard get standard => standardsRemaining.first;

  bool get done => standardsRemaining.isEmpty;

  CalibrationPointConfig({required this.moduleIdentity, required this.curveType, required this.standardsRemaining, this.offline = false});

  CalibrationPointConfig popStandard() {
    return CalibrationPointConfig(
        moduleIdentity: moduleIdentity, curveType: curveType, standardsRemaining: standardsRemaining.skip(1).toList());
  }

  static CalibrationPointConfig waterPh(ModuleIdentity moduleIdentity) => CalibrationPointConfig(
      moduleIdentity: moduleIdentity,
      curveType: proto.CurveType.CURVE_LINEAR,
      standardsRemaining: [FixedStandard(4), FixedStandard(7), FixedStandard(10)]);

  static CalibrationPointConfig waterDissolvedOxygen(ModuleIdentity moduleIdentity) => CalibrationPointConfig(
      moduleIdentity: moduleIdentity,
      curveType: proto.CurveType.CURVE_LINEAR,
      standardsRemaining: [UnknownStandard(), UnknownStandard(), UnknownStandard()]);

  static CalibrationPointConfig waterEc(ModuleIdentity moduleIdentity) => CalibrationPointConfig(
      moduleIdentity: moduleIdentity,
      curveType: proto.CurveType.CURVE_EXPONENTIAL,
      standardsRemaining: [UnknownStandard(), UnknownStandard(), UnknownStandard()]);

  static CalibrationPointConfig waterTemp(ModuleIdentity moduleIdentity) => CalibrationPointConfig(
      moduleIdentity: moduleIdentity,
      curveType: proto.CurveType.CURVE_EXPONENTIAL,
      standardsRemaining: [UnknownStandard(), UnknownStandard(), UnknownStandard()]);

  static CalibrationPointConfig showCase(ModuleIdentity moduleIdentity) => CalibrationPointConfig(
      moduleIdentity: moduleIdentity, curveType: proto.CurveType.CURVE_LINEAR, standardsRemaining: [UnknownStandard(), FixedStandard(10)]);
}

abstract class Standard {
  bool get acceptable;

  double? get value;
}

class FixedStandard extends Standard {
  final double _value;

  FixedStandard(this._value);

  @override
  String toString() => "FixedStandard($_value)";

  @override
  bool get acceptable => true;

  @override
  double get value => _value;
}

class UnknownStandard extends Standard {
  @override
  String toString() => "Unknown()";

  @override
  bool get acceptable => false;

  @override
  double? get value => null;
}

class UserStandard extends Standard {
  final double _value;

  UserStandard(this._value);

  @override
  String toString() => "UserStandard($_value)";

  @override
  bool get acceptable => true;

  @override
  double get value => _value;
}

class NumberForm extends StatefulWidget {
  final String label;
  final double? original;
  final void Function(double) onValid;
  final VoidCallback onInvalid;

  const NumberForm({super.key, required this.label, required this.original, required this.onValid, required this.onInvalid});

  @override
  // ignore: library_private_types_in_public_api
  _NumberFormState createState() => _NumberFormState();
}

class _NumberFormState extends State<NumberForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
        key: _formKey,
        child: Column(children: [
          Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  if (_formKey.currentState!.saveAndValidate()) {
                    final stringValue = _formKey.currentState!.value['value'];
                    final value = double.parse(stringValue);
                    widget.onValid(value);
                  } else {
                    widget.onInvalid();
                  }
                }
              },
              child: FormBuilderTextField(
                name: 'value',
                decoration: InputDecoration(labelText: widget.label),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                ]),
              ))
        ]));
  }
}

class UnknownStandardWidget extends StatelessWidget {
  final SensorConfig sensor;
  final UnknownStandard standard;

  const UnknownStandardWidget({super.key, required this.standard, required this.sensor});

  @override
  Widget build(BuildContext context) {
    return const ActiveCalibrationStandardForm();
  }
}

class ActiveCalibrationStandardForm extends StatelessWidget {
  const ActiveCalibrationStandardForm({super.key});

  @override
  Widget build(BuildContext context) {
    final activeCalibration = context.watch<ActiveCalibration>();

    debugPrint("active = $activeCalibration");

    final form = NumberForm(
      original: activeCalibration.standard,
      label: "Standard",
      onValid: (value) => activeCalibration.haveStandard(value),
      onInvalid: () => activeCalibration.haveStandard(null),
    );
    return FractionallySizedBox(widthFactor: 0.5, child: form);
  }
}
