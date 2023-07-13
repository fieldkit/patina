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

Logger create(String name) {
  return Logger(
    filter: null,
    printer: AddLoggerName(SimplePrinter(), name),
    output: null,
  );
}

class Loggers {
  static final Logger _main = create("main");
  static final Logger _bridge = create("bridge");
  static final Logger _state = create("state");
  static final Logger _cal = create("cal");
  static final Logger _ui = create("ui");
  static final Logger _portal = create("portal");

  static Logger get main => _main;
  static Logger get bridge => _bridge;
  static Logger get sdkMessages => devNull;
  static Logger get state => _state;
  static Logger get cal => _cal;
  static Logger get ui => _ui;
  static Logger get portal => _portal;
}
