import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final bool colors;

  AddLoggerName(this.real, this.name, this.colors);

  @override
  List<String> log(LogEvent event) {
    final printed = real.log(event);
    return printed
        .map((s) {
          if (colors) {
            return s;
          } else {
            return AnsiStyles.strip(s);
          }
        })
        .map((s) => '$name $s')
        .toList();
  }
}

final devNull = Logger(filter: NoneFilter());

Logger create(File file, String name, bool colors) {
  return Logger(
    filter: null,
    printer: AddLoggerName(SimplePrinter(colors: colors), name, colors),
    output: MultiOutput([
      ConsoleOutput(),
      FileOutput(file: file),
    ]),
  );
}

String? getCommitRefName() {
  return dotenv.env['CI_COMMIT_REF_NAME'];
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
    final isAutomatedBuild = getCommitRefName() != null;
    final colors = !isAutomatedBuild;
    final path = "$logsPath/logs.txt";
    final File file = File(path);
    _main = create(file, "main", colors);
    _bridge = create(file, "bridge", colors);
    _state = create(file, "state", colors);
    _cal = create(file, "cal", colors);
    _ui = create(file, "ui", colors);
    _portal = create(file, "portal", colors);
    _markDown = create(file, "mark-down", colors);
    _path = path;
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
      const uuid = Uuid();
      final id = uuid.v4();

      final sending = File(Loggers.path);
      final body = await sending.readAsBytes();
      Loggers.main.i("uploading: $sending");

      final url = Uri.https("code.conservify.org", "diagnostics/$id/logs.txt");
      Loggers.main.i("uploading: $url");
      final response = await http.post(url, body: body);
      Loggers.main.i("upload: $response");
      final meta = response.body;
      Loggers.main.i("upload: $meta");

      return id.toString();
    } catch (e) {
      Loggers.ui.e("send logs failed: $e");
      return null;
    }
  }
}
