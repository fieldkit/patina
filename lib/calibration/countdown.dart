import 'dart:async';
import 'dart:math';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../diagnostics.dart';

class CountdownTimer extends ChangeNotifier {
  static const Duration period = Duration(seconds: 1);
  static const Duration trailing = Duration(seconds: 5);

  final Duration expected;

  DateTime _now = DateTime.now().toUtc();
  DateTime? _started;
  bool skipped = false;

  CountdownTimer({required this.expected, this.skipped = false});

  bool get started => _started != null;

  Duration? get elapsed {
    final DateTime? started = _started;
    if (started == null) {
      return null;
    }
    return _now.difference(started);
  }

  DateTime? get finished {
    final DateTime? started = _started;
    if (started == null) {
      return null;
    }
    return started.add(expected);
  }

  bool get done {
    final elapsed = this.elapsed;
    if (elapsed == null) {
      return false;
    }
    return elapsed >= expected || skipped;
  }

  bool get wasDone {
    final started = _started;
    if (started == null) {
      return false;
    }
    final finallyDone = started.add(expected).add(trailing);
    return _now.isAfter(finallyDone);
  }

  String toStringRemaining() {
    final Duration? elapsed = this.elapsed;
    if (elapsed == null) {
      return "--:--";
    }
    return toMinutesSecondsString(
        [(expected - elapsed).inSeconds, 0].reduce(max));
  }

  String toMinutesSecondsString(int total) {
    final int minutes = (total / 60).floor();
    final int seconds = total - (minutes * 60);
    return "${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }

  void start(DateTime now) {
    if (_started == null) {
      Loggers.cal.i("timer: started");
      _started = _now;
      notifyListeners();
    }
  }

  void skip() {
    if (!skipped) {
      Loggers.cal.i("timer: skipped");
      skipped = true;
      notifyListeners();
    }
  }

  CountdownTimer tick(DateTime now) {
    _now = now;
    notifyListeners();
    return this;
  }

  bool finishedBefore(DateTime time) {
    final DateTime? after = finished;
    if (after == null) {
      return false;
    }
    return time.isAfter(after) || skipped;
  }
}

class FrozenCountdown extends StatelessWidget {
  const FrozenCountdown({super.key});

  @override
  Widget build(BuildContext context) {
    final countdown = context.read<CountdownTimer>();
    final screenSize = MediaQuery.of(context).size;

    return CircularCountDownTimer(
      width: screenSize.width * 0.3,
      height: screenSize.width * 0.3,
      duration: countdown.expected.inSeconds,
      initialDuration: 0,
      fillColor: const Color.fromRGBO(61, 126, 195, 1),
      ringColor: Colors.grey,
      strokeWidth: 10,
      textFormat: CountdownTextFormat.MM_SS,
      isReverse: true,
      strokeCap: StrokeCap.butt,
      textStyle: const TextStyle(fontSize: 30.0),
      autoStart: false,
    );
  }
}

class LiveCountdown extends StatelessWidget {
  const LiveCountdown({super.key});

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

class DisplayCountdown extends StatelessWidget {
  const DisplayCountdown({super.key});

  @override
  Widget build(BuildContext context) {
    final countdown = context.watch<CountdownTimer>();

    if (countdown.started) {
      return const LiveCountdown();
    } else {
      return const FrozenCountdown();
    }
  }
}

class ProvideCountdown extends StatefulWidget {
  final Duration duration;
  final Widget child;

  const ProvideCountdown(
      {super.key, required this.duration, required this.child});

  @override
  State<StatefulWidget> createState() => _CountdownState();
}

class _CountdownState extends State<ProvideCountdown> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CountdownTimer>(
        create: (context) {
          final countdown = CountdownTimer(expected: widget.duration);
          _timer = Timer.periodic(CountdownTimer.period, (timer) {
            countdown.tick(DateTime.now());
          });
          return countdown;
        },
        child: widget.child);
  }
}
