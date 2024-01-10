import 'dart:io';

import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

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
  static String? _path;
  static Logger _main = devNull;
  static Logger _bridge = devNull;
  static Logger _state = devNull;
  static Logger _cal = devNull;
  static Logger _ui = devNull;
  static Logger _portal = devNull;
  static Logger _markDown = devNull;

  static void initialize(String logsPath) {
    _path = "$logsPath/logs.txt";
    final File file = File("$logsPath/logs.txt");
    _main = create(file, "main");
    _bridge = create(file, "bridge");
    _state = create(file, "state");
    _cal = create(file, "cal");
    _ui = create(file, "ui");
    _portal = create(file, "portal");
    _markDown = create(file, "mark-down");
  }

  static Logger get main => _main;
  static Logger get bridge => _bridge;
  static Logger get sdkMessages => devNull;
  static Logger get state => _state;
  static Logger get cal => _cal;
  static Logger get ui => _ui;
  static Logger get portal => _portal;
  static Logger get markDown => _markDown;
  static String get path => _path!;
}

class ShareDiagnostics {
  Future<String?> upload() async {
    try {
      var uuid = const Uuid();
      var id = uuid.v4();

      var sending = File(Loggers.path);
      var body = await sending.readAsBytes();
      Loggers.main.i("uploading: $sending");

      var url = Uri.https("code.conservify.org", "diagnostics/$id/logs.txt");
      Loggers.main.i("uploading: $url");
      var response = await http.post(url, body: body);
      Loggers.main.i("upload: $response");
      var meta = response.body;
      Loggers.main.i("upload: $meta");

      return id.toString();
    } catch (e) {
      Loggers.ui.e("send logs failed: $e");
      return null;
    }
  }
}
