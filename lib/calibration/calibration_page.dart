import 'package:loader_overlay/loader_overlay.dart';
import 'package:caldor/calibration.dart';
import 'package:fk/calibration/calibration_review_page.dart';
import 'package:fk/providers.dart';
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

enum CanContinue { ready, form, countdown, staleValue, yes }

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
    final module = context
        .read<KnownStationsModel>()
        .findModule(config.moduleIdentity)!
        .module;
    final bay = AppLocalizations.of(context)!.bayNumber(module.position);

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (didPop) {
            return;
          }
          final NavigatorState navigator = Navigator.of(context);
          final bool? shouldPop = await _confirmBackDialog(context);
          if (shouldPop ?? false) {
            navigator.popUntil((route) => route.isFirst);
          }
        },
        child: dismissKeyboardOnOutsideGap(Scaffold(
            appBar: AppBar(
                centerTitle: true,
                title: Column(children: [
                  Text(AppLocalizations.of(context)!.calibrationTitle),
                  Text(
                    bay,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                ])),
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

    // NOTE Seems silly that this isn't already available here.
    final module = context
        .read<KnownStationsModel>()
        .findModule(config.moduleIdentity)!
        .module;

    Loggers.cal.i("(calibrate) calibration: $current");
    Loggers.cal.i("(calibrate) active: $active");

    final nextConfig = config.popStandard();
    if (nextConfig.done) {
      final overlay = context.loaderOverlay;
      final cal = current.toDataProtocol();
      final serialized = current.toBytes();

      Loggers.cal.i("(calibrate) $cal");

      overlay.show();
      try {
        await moduleConfigurations.calibrate(config.moduleIdentity, serialized);
      } catch (e) {
        Loggers.cal.e("Exception calibration: $e");
      } finally {
        overlay.hide();
      }

      navigator.pushReplacement(MaterialPageRoute(
          builder: (context) => CalibrationReviewPage(module: module)));
    } else {
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => ModuleProviders(
              moduleIdentity: config.moduleIdentity,
              child: CalibrationPage(
                config: nextConfig,
                current: current,
              )),
        ),
      );
    }
  }

  CanContinue canContinue(SensorConfig sensor, Standard standard,
      ActiveCalibration active, CountdownTimer countdown) {
    if (!countdown.started) {
      return CanContinue.ready;
    }

    if (!standard.acceptable && active.invalid) {
      return CanContinue.form;
    }

    if (countdown.done) {
      final time = sensor.value?.time;
      if (time == null) {
        return CanContinue.staleValue;
      } else {
        if (countdown.finishedBefore(time)) {
          return CanContinue.yes;
        }
        return CanContinue.staleValue;
      }
    }

    return CanContinue.countdown;
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
      onStartTimer: () => countdown.start(DateTime.now()),
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
  final VoidCallback onStartTimer;
  final VoidCallback onCalibrateAndContinue;
  final VoidCallback onSkipTimer;
  final CanContinue canContinue;

  const CalibrationWait(
      {super.key,
      required this.config,
      required this.sensor,
      required this.onStartTimer,
      required this.onCalibrateAndContinue,
      required this.canContinue,
      required this.onSkipTimer});

  Widget continueWidget(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    switch (canContinue) {
      case CanContinue.ready:
        return ElevatedTextButton(
            onPressed: onStartTimer, text: localizations.calibrationStartTimer);
      case CanContinue.yes:
        return ElevatedTextButton(
            onPressed: () => onCalibrateAndContinue(),
            text: localizations.calibrateButton);
      case CanContinue.form:
        return ElevatedTextButton(
            onPressed: null, text: localizations.waitingOnForm);
      case CanContinue.countdown:
        return GestureDetector(
            onLongPress: onSkipTimer,
            child: ElevatedTextButton(
                onPressed: null, text: localizations.waitingOnTimer));
      case CanContinue.staleValue:
        return ElevatedTextButton(
            onPressed: null, text: localizations.waitingOnReading);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = [
      CurrentReadingAndStandard(
        sensor: sensor,
        standard: config.standard,
      ),
      continueWidget(context),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          color: Colors.grey[200],
          child: Text(
            AppLocalizations.of(context)!.calibrationMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromRGBO(212, 212, 212, 1),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(25))),
        padding: const EdgeInsetsDirectional.fromSTEB(60, 6, 60, 6),
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
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
        child: Text(
          AppLocalizations.of(context)!.countdownInstructions,
          textAlign: TextAlign.center,
        ),
      ),
      const DisplayCountdown(),
      Padding(
          padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(AppLocalizations.of(context)!.sensorValue,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      )),
                  sensorValue,
                ],
              ),
            ),
          )),
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
      return sensors.sorted((a, b) => a.number.compareTo(b.number)).first;
    }
    return null;
  }
}
