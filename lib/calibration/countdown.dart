import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CountdownTimer {
  static const Duration period = Duration(seconds: 1);
  static const int expectedTicks = 120;

  final int elapsed;

  bool get done => elapsed >= expectedTicks;

  CountdownTimer({required this.elapsed});

  String toStringRemaining() {
    return toMinutesSecondsString(expectedTicks - elapsed);
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
            const Text("min sec", style: TextStyle(fontSize: 14))
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
    return StreamProvider(
        initialData: CountdownTimer(elapsed: 0),
        create: (BuildContext context) {
          return Stream<CountdownTimer>.periodic(CountdownTimer.period, (c) => CountdownTimer(elapsed: c + 1))
              .take(CountdownTimer.expectedTicks);
        },
        child: child);
  }
}
