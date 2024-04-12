import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:caldor/calibration.dart';

import 'package:fk/gen/api.dart';
import 'package:fk/meta.dart';
import 'package:fk/diagnostics.dart';
import 'package:fk/view_station/sensor_widgets.dart';

import 'calibration_model.dart';
import 'countdown.dart';
import 'number_form.dart';

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
