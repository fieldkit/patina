import 'package:caldor/calibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:fk/gen/ffi.dart';
import 'package:fk/meta.dart';
import 'package:fk/view_station/sensor_widgets.dart';

import '../app_state.dart';
import '../common_widgets.dart';
import '../diagnostics.dart';
import 'calibration_model.dart';
import 'countdown.dart';
import 'number_form.dart';

enum CanContinue { form, timer, staleValue, yes }

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
                duration: const Duration(seconds: 120),
                child: Consumer<CountdownTimer>(
                    builder: (context, countdown, child) {
                  return CalibrationPanel(
                      config: config,
                      current: current ??
                          CurrentCalibration(curveType: config.curveType));
                }))));
  }
}

class CalibrationPanel extends StatelessWidget {
  final CurrentCalibration current;
  final CalibrationPointConfig config;

  const CalibrationPanel(
      {super.key, required this.current, required this.config});

  Future<void> calibrateAndContinue(BuildContext context, SensorConfig sensor,
      CurrentCalibration current, ActiveCalibration active) async {
    final moduleConfigurations = context.read<ModuleConfigurations>();
    final navigator = Navigator.of(context);

    final configured = config.standard;
    final standard = configured.acceptable ? configured : active.userStandard();

    final reading = SensorReading(
        uncalibrated: sensor.value!.uncalibrated, value: sensor.value!.value);
    current.addPoint(CalibrationPoint(standard: standard, reading: reading));

    Loggers.cal.i("(calibrate) calibration: $current");
    Loggers.cal.i("(calibrate) active: $active");

    final nextConfig = config.popStandard();
    if (nextConfig.done) {
      final cal = current.toDataProtocol();
      final serialized = current.toBytes();

      Loggers.cal.i("(calibrate) $cal");

      try {
        await moduleConfigurations.calibrate(config.moduleIdentity, serialized);
      } catch (e) {
        Loggers.cal.e("Exception calibration: $e");
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

  CanContinue canContinue(SensorConfig sensor, Standard standard,
      ActiveCalibration active, CountdownTimer countdown) {
    if (!standard.acceptable && active.invalid) {
      return CanContinue.form;
    }
    if (countdown.done) {
      final sensorTime = sensor.value?.time;
      final untilOrAfter = (sensorTime != null)
          ? countdown.finished.difference(sensorTime)
          : null;
      Loggers.cal.i(
          "elapsed=${countdown.elapsed} skipped=${countdown.skipped} untilOrAfter=$untilOrAfter sensor-time=$sensorTime sensor-cal=${sensor.value?.value} sensor-uncal=${sensor.value?.uncalibrated}");
      final time = sensor.value?.time;
      if (time == null) {
        return CanContinue.staleValue;
      } else {
        if (countdown.isValueFresh(time)) {
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
      onCalibrateAndContinue: () =>
          calibrateAndContinue(context, sensor, current, active),
      onSkipTimer: () => countdown.skip(),
    );
  }
}

class CalibrationWait extends StatelessWidget {
  final CalibrationPointConfig config;
  final SensorConfig sensor;
  final VoidCallback onCalibrateAndContinue;
  final VoidCallback onSkipTimer;
  final CanContinue canContinue;

  const CalibrationWait(
      {super.key,
      required this.config,
      required this.sensor,
      required this.onCalibrateAndContinue,
      required this.canContinue,
      required this.onSkipTimer});

  Widget continueWidget(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    switch (canContinue) {
      case CanContinue.yes:
        return ElevatedButton(
            onPressed: () => onCalibrateAndContinue(),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 150, vertical: 20),
            ),
            child: Text(localizations.calibrateButton));
      case CanContinue.form:
        return ElevatedButton(
            onPressed: null, child: Text(localizations.waitingOnForm));
      case CanContinue.timer:
        return GestureDetector(
            onLongPress: onSkipTimer,
            child: ElevatedButton(
                onPressed: null, child: Text(localizations.waitingOnTimer)));
      case CanContinue.staleValue:
        return ElevatedButton(
            onPressed: null, child: Text(localizations.waitingOnReading));
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

  const FixedStandardWidget(
      {super.key, required this.standard, required this.sensor});

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
            borderRadius: const BorderRadius.all(Radius.circular(25))),
        padding: const EdgeInsetsDirectional.fromSTEB(60, 20, 60, 20),
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: <TextSpan>[
              TextSpan(
                text: standard.value.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                ),
              ),
              TextSpan(
                text: localizations.standardValue2(sensor.calibratedUom),
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StandardWidget extends StatelessWidget {
  final SensorConfig sensor;
  final Standard standard;

  const StandardWidget(
      {super.key, required this.standard, required this.sensor});

  @override
  Widget build(BuildContext context) {
    if (standard is FixedStandard) {
      return FixedStandardWidget(
          standard: standard as FixedStandard, sensor: sensor);
    }
    return UnknownStandardWidget(
        standard: standard as UnknownStandard, sensor: sensor);
  }
}

class CurrentReadingAndStandard extends StatelessWidget {
  final SensorConfig sensor;
  final Standard standard;

  const CurrentReadingAndStandard(
      {super.key, required this.sensor, required this.standard});

  @override
  Widget build(BuildContext context) {
    final localized = LocalizedSensor.get(sensor);
    final sensorValue = DisplaySensorValue(
        sensor: sensor, localized: localized, mainAxisSize: MainAxisSize.min);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          AppLocalizations.of(context)!.countdownInstructions,
          textAlign: TextAlign.center,
        ),
      ),
      sensorValue,
      StandardWidget(standard: standard, sensor: sensor),
    ]);
  }
}

class UnknownStandardWidget extends StatelessWidget {
  final SensorConfig sensor;
  final UnknownStandard standard;

  const UnknownStandardWidget(
      {super.key, required this.standard, required this.sensor});

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

    Loggers.cal.i("active = $activeCalibration");

    final form = NumberForm(
      original: activeCalibration.standard,
      label: "Standard", // TODO: l10n
      onValid: (value) => activeCalibration.haveStandard(value),
      onInvalid: () => activeCalibration.haveStandard(null),
    );
    return FractionallySizedBox(widthFactor: 0.5, child: form);
  }
}

extension CalibrationSensors on ModuleConfig {
  SensorConfig? get calibrationSensor {
    if (key.startsWith("modules.water")) {
      return sensors[0];
    }
    return null;
  }
}
