import 'dart:io';

import 'package:logger/logger.dart';

class NoneFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

class AddLoggerName extends LogPrinter {
  final LogPrinter real;
  final String name;

  AddLoggerName(this.real, this.name);

  @override
  List<String> log(LogEvent event) {
    final printed = real.log(event);
    return printed.map((s) => '$name $s').toList();
  }
}

final devNull = Logger(filter: NoneFilter());

Logger create(File file, String name) {
  return Logger(
    filter: null,
    printer: AddLoggerName(SimplePrinter(), name),
    output: MultiOutput([
      ConsoleOutput(),
      FileOutput(file: file),
    ]),
  );
}

class Loggers {
  static Logger _main = devNull;
  static Logger _bridge = devNull;
  static Logger _state = devNull;
  static Logger _cal = devNull;
  static Logger _ui = devNull;
  static Logger _portal = devNull;

  static void initialize(String logsPath) {
    final File file = File("$logsPath/logs.txt");
    _main = create(file, "main");
    _bridge = create(file, "bridge");
    _state = create(file, "state");
    _cal = create(file, "cal");
    _ui = create(file, "ui");
    _portal = create(file, "portal");
  }

  static Logger get main => _main;
  static Logger get bridge => _bridge;
  static Logger get sdkMessages => devNull;
  static Logger get state => _state;
  static Logger get cal => _cal;
  static Logger get ui => _ui;
  static Logger get portal => _portal;
}
