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

  Future<bool?> _confirmBackDialog(BuildContext context) async {
    return showDialog<bool>(
        context: context,
        builder: (context) {
          final localizations = AppLocalizations.of(context)!;
          final navigator = Navigator.of(context);

          return AlertDialog(
            title: Text(localizations.backAreYouSure),
            content: Text(localizations.backWarning),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    navigator.pop(false);
                  },
                  child: Text(localizations.confirmCancel)),
              TextButton(
                  onPressed: () async {
                    navigator.pop(true);
                  },
                  child: Text(AppLocalizations.of(context)!.confirmYes))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (didPop) {
            return;
          }
          final NavigatorState navigator = Navigator.of(context);
          final bool? shouldPop = await _confirmBackDialog(context);
          if (shouldPop ?? false) {
            navigator.pop();
          }
        },
        child: dismissKeyboardOnOutsideGap(Scaffold(
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
                    }))))));
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
      navigator.pushReplacement(
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
          "elapsed=${countdown.elapsed} skipped=${countdown.skipped} finished=${countdown.finished} untilOrAfter=$untilOrAfter sensor-time=$sensorTime sensor-cal=${sensor.value?.value} sensor-uncal=${sensor.value?.uncalibrated}");
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
                borderRadius: const BorderRadius.all(Radius.circular(5))),
            padding: const EdgeInsets.all(8),
            child: Text(localizations.standardValue(
                sensor.calibratedUom, standard.value))));
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
    if (standard is DefaultStandard) {
      return CustomStandardWidget(sensor: sensor, initial: standard.value);
    }
    return CustomStandardWidget(sensor: sensor, initial: null);
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
      sensorValue,
      StandardWidget(standard: standard, sensor: sensor),
    ]);
  }
}

class CustomStandardWidget extends StatelessWidget {
  final SensorConfig sensor;
  final double? initial;

  const CustomStandardWidget({
    super.key,
    required this.sensor,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    return ActiveCalibrationStandardForm(initial: initial);
  }
}

class ActiveCalibrationStandardForm extends StatelessWidget {
  final double? initial;

  const ActiveCalibrationStandardForm({super.key, required this.initial});

  @override
  Widget build(BuildContext context) {
    final activeCalibration = context.watch<ActiveCalibration>();
    final localizations = AppLocalizations.of(context)!;

    Loggers.cal.v("active=$activeCalibration initial=$initial");

    final form = NumberForm(
      original: activeCalibration.standard ?? initial,
      label: localizations.standardFieldLabel,
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
