import 'package:fk/reader/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:caldor/calibration.dart';

import 'package:fk/gen/api.dart';
import 'package:fk/providers.dart';
import 'package:fk/meta.dart';
import 'package:fk/app_state.dart';
import 'package:fk/diagnostics.dart';
import 'package:fk/common_widgets.dart';

import 'calibration_review_page.dart';
import 'calibration_model.dart';
import 'countdown.dart';
import 'standard_form.dart';

enum CanContinue { ready, form, countdown, staleValue, yes }

class CalibrationPage extends StatelessWidget {
  final ActiveCalibration active = ActiveCalibration();
  final CurrentCalibration? current;
  final CalibrationConfig config;

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

  Widget body() {
    final current =
        this.current ?? CurrentCalibration(curveType: config.curveType);
    return ChangeNotifierProvider(
        create: (context) => active,
        child: ProvideContentFlowsWidget(
            child: StepsWidget(config: config, current: current)));
  }

  @override
  Widget build(BuildContext context) {
    final module = context
        .read<KnownStationsModel>()
        .findModule(config.moduleIdentity)!
        .module;
    final localizations = AppLocalizations.of(context)!;
    final bay = localizations.bayNumber(module.position);

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
                  Text(localizations.calibrationTitle),
                  Text(
                    bay,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                ])),
            body: body())));
  }
}

class StepsWidget extends StatefulWidget {
  final CalibrationConfig config;
  final CurrentCalibration current;

  const StepsWidget({super.key, required this.config, required this.current});

  @override
  State<StatefulWidget> createState() => _StepsState();
}

class _StepsState extends State<StepsWidget> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    if (index >= 0 && index < widget.config.steps.length) {
      final navigator = Navigator.of(context);

      final step = widget.config.steps[index];

      final key = UniqueKey();

      Loggers.ui.i("Calibration[$index] $key");

      if (step is HelpStep) {
        return FlowNamedScreenWidget(
          name: step.screen,
          onForward: () {
            setState(() {
              index += 1;
            });
          },
        );
      }

      if (step is StandardStep) {
        return ProvideCountdown(
            duration: const Duration(seconds: 120),
            child:
                Consumer<CountdownTimer>(builder: (context, countdown, child) {
              if (widget.config.done) {
                return Container();
              }

              return CalibrationPanel(
                  key: key,
                  config: widget.config,
                  current: widget.current,
                  onDone: () {
                    setState(() {
                      if (widget.config.done) {
                        final module = context
                            .read<KnownStationsModel>()
                            .findModule(widget.config.moduleIdentity)!
                            .module;

                        navigator.pushReplacement(MaterialPageRoute(
                            builder: (context) =>
                                CalibrationReviewPage(module: module)));
                        Loggers.ui.i("done!");
                      } else {
                        index += 1;
                      }
                    });
                  });
            }));
      }
    }

    return const OopsBug();
  }
}

class CalibrationPanel extends StatelessWidget {
  final CurrentCalibration current;
  final CalibrationConfig config;
  final VoidCallback onDone;

  const CalibrationPanel(
      {super.key,
      required this.current,
      required this.config,
      required this.onDone});

  Future<void> calibrateAndContinue(BuildContext context, SensorConfig sensor,
      CurrentCalibration current, ActiveCalibration active) async {
    final moduleConfigurations = context.read<ModuleConfigurations>();
    final standard = active.userStandard();
    final reading = SensorReading(
      uncalibrated: sensor.value!.uncalibrated,
      value: sensor.value!.value,
    );
    current.addPoint(CalibrationPoint(standard: standard, reading: reading));
    active.haveStandard(null);

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
        await moduleConfigurations.calibrateModule(
            config.moduleIdentity, serialized);
      } catch (e) {
        Loggers.cal.e("Exception calibration: $e");
      } finally {
        overlay.hide();
      }
    }
    onDone();
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
        if (countdown
            .finishedBefore(DateTime.fromMillisecondsSinceEpoch(time.field0))) {
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
  final CalibrationConfig config;
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
      Expanded(
          child: CurrentReadingAndStandard(
        sensor: sensor,
        standard: config.standard,
      )),
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
      Container(
          margin: const EdgeInsets.all(30.0), child: continueWidget(context)),
    ];

    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children);
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
