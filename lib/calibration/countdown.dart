import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fk/constants.dart';
import '../diagnostics.dart';

class CountdownTimer {
  static const Duration period = Duration(seconds: 1);
  static const Duration trailing = Duration(seconds: 5);

  final DateTime started;
  final DateTime now = DateTime.now().toUtc();
  final Duration expected;

  Duration elapsed;
  bool skipped = false;
  bool get done => elapsed >= expected || skipped;

  DateTime get finished => started.add(expected);

  bool get wasDone {
    final finallyDone = started.add(expected).add(trailing);
    return now.isAfter(finallyDone);
  }

  CountdownTimer(
      {required this.expected,
      required this.started,
      required this.elapsed,
      this.skipped = false});

  String toStringRemaining() {
    return toMinutesSecondsString(
        [(expected - elapsed).inSeconds, 0].reduce(max));
  }

  String toMinutesSecondsString(int total) {
    final int minutes = (total / 60).floor();
    final int seconds = total - (minutes * 60);
    return "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }

  void skip() {
    if (!skipped) {
      Loggers.cal.i("timer: skipped");
      skipped = true;
    }
  }

  CountdownTimer tick(Duration newElapsed) {
    elapsed = newElapsed;
    return this;
  }

  bool isValueFresh(DateTime time) {
    return time.isAfter(finished) || skipped;
  }
}

class DisplayCountdown extends StatelessWidget {
  const DisplayCountdown({super.key});

  @override
  Widget build(BuildContext context) {
    final countdown = context.watch<CountdownTimer>();
    final screenSize = MediaQuery.of(context).size;

    return CircularCountDownTimer(
      width: screenSize.width * 0.3,
      height: screenSize.width * 0.3,
      duration: countdown.expected.inSeconds,
      fillColor: const Color.fromRGBO(61, 126, 195, 1),
      ringColor: Colors.grey,
      strokeWidth: 10,
      textFormat: CountdownTextFormat.MM_SS,
      isReverse: true,
      strokeCap: StrokeCap.butt,
      textStyle: const TextStyle(fontSize: 30.0),
    );
  }
}

class ProvideCountdown extends StatelessWidget {
  final Duration duration;
  final Widget child;

  const ProvideCountdown(
      {super.key, required this.duration, required this.child});

  @override
  Widget build(BuildContext context) {
    final started = DateTime.now().toUtc();
    return StreamProvider(
        initialData: CountdownTimer(
            expected: duration, started: started, elapsed: Duration.zero),
        updateShouldNotify: (previous, value) => true,
        create: (BuildContext context) {
          final countdown = CountdownTimer(
            expected: duration,
            started: started,
            elapsed: const Duration(seconds: 0),
          );
          return Stream<CountdownTimer>.periodic(CountdownTimer.period,
                  (c) => countdown.tick(Duration(seconds: c + 1)))
              .takeWhile((e) => !e.wasDone);
        },
        child: child);
  }
}
