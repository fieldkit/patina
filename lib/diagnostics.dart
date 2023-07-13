import 'package:logger/logger.dart';

final logger = Logger(
  filter: null,
  printer: SimplePrinter(),
  output: null,
);

final devNull = Logger(filter: NoneFilter());

class NoneFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

class Loggers {
  static Logger get main => logger;
  static Logger get native => logger;
  static Logger get sdkMessages => devNull;
  static Logger get state => logger;
  static Logger get cal => logger;
  static Logger get ui => logger;
  static Logger get portal => logger;
}
