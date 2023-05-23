import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CountdownTimer {
  static const Duration period = Duration(seconds: 1);
  static const Duration expected = Duration(seconds: 120);
  static const Duration trailing = Duration(seconds: 5);

  final DateTime started;
  final DateTime now = DateTime.now().toUtc();
  final Duration elapsed;

  bool get done => elapsed >= expected;

  DateTime get finished => started.add(expected);

  bool get wasDone {
    final finallyDone = started.add(expected).add(trailing);
    debugPrint("$started $now ${now.difference(started)} $finallyDone");
    return now.isAfter(finallyDone);
  }

  CountdownTimer({required this.started, required this.elapsed});

  String toStringRemaining() {
    return toMinutesSecondsString([(expected - elapsed).inSeconds, 0].reduce(max));
  }

  String toMinutesSecondsString(int total) {
    final int minutes = (total / 60).floor();
    final int seconds = total - (minutes * 60);
    return "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }
}

class DisplayCountdown extends StatelessWidget {
  const DisplayCountdown({super.key});

  @override
  Widget build(BuildContext context) {
    final countdown = context.watch<CountdownTimer>();
    return IntrinsicHeight(
        child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time, size: 60),
        const VerticalDivider(
          width: 10,
          thickness: 1,
          color: Colors.grey,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(countdown.toStringRemaining(), style: const TextStyle(fontSize: 18)),
            Text(AppLocalizations.of(context)!.minSec, style: const TextStyle(fontSize: 14))
          ],
        )
      ],
    ));
  }
}

class ProvideCountdown extends StatelessWidget {
  final Widget child;

  const ProvideCountdown({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final started = DateTime.now().toUtc();
    return StreamProvider(
        initialData: CountdownTimer(started: started, elapsed: Duration.zero),
        create: (BuildContext context) {
          return Stream<CountdownTimer>.periodic(
              CountdownTimer.period,
              (c) => CountdownTimer(
                    started: started,
                    elapsed: Duration(seconds: c + 1),
                  )).takeWhile((e) => !e.wasDone);
        },
        child: child);
  }
}
