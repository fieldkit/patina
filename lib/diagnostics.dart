import 'dart:io';

import 'package:ansi_styles/ansi_styles.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

String? getCommitRefName() {
  return dotenv.env['CI_COMMIT_REF_NAME'];
}

String? getCommitSha() {
  return dotenv.env['CI_COMMIT_SHA'];
}

bool isAutomatedBuild() {
  return getCommitRefName() != null;
}

class NoneFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

class StandardFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => event.level.index >= Level.debug.index;
}

class AutomatedBuildFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => event.level.index >= Level.trace.index;
}

class AddLoggerName extends LogPrinter {
  final LogPrinter real;
  final String name;

  AddLoggerName(this.real, this.name);

  @override
  List<String> log(LogEvent event) {
    return real.log(event).map((s) => '$name $s').toList();
  }
}

class AnsiStrippingFileOutput extends FileOutput {
  AnsiStrippingFileOutput({required super.file});

  @override
  void output(OutputEvent event) {
    super.output(OutputEvent(
        event.origin,
        event.lines.map((l) {
          // No idea why this doesn't catch them all.
          return AnsiStyles.strip(l).replaceAll(";5;12m", "");
        }).toList()));
  }
}

final devNull = Logger(filter: NoneFilter());

Logger create(FileOutput file, String name, bool colors) {
  final LogFilter filter =
      isAutomatedBuild() ? AutomatedBuildFilter() : StandardFilter();
  return Logger(
    filter: filter,
    printer: AddLoggerName(
      SimplePrinter(colors: colors),
      name,
    ),
    output: MultiOutput([
      ConsoleOutput(),
      file,
    ]),
  );
}

bool rollover(File file) {
  if (!file.existsSync() || file.lengthSync() < 1024 * 1024 * 5) {
    return false;
  }

  final rolloverPath = "${file.path}.1";
  final rolloverFile = File(rolloverPath);
  if (rolloverFile.existsSync()) {
    rolloverFile.delete();
  }
  file.renameSync(rolloverPath);

  return true;
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
    final colors = !isAutomatedBuild();
    final path = "$logsPath/logs.txt";
    final logFile = File(path);
    final rolled = rollover(logFile);
    final FileOutput fileOutput = AnsiStrippingFileOutput(file: logFile);
    _main = create(fileOutput, "main", colors);
    _bridge = create(fileOutput, "bridge", colors);
    _state = create(fileOutput, "state", colors);
    _cal = create(fileOutput, "cal", colors);
    _ui = create(fileOutput, "ui", colors);
    _portal = create(fileOutput, "portal", colors);
    _markDown = create(fileOutput, "mark-down", colors);
    _path = path;

    _main.i("logging to $path (rolled = $rolled)");
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
      Loggers.main.i("uploading: $sending (${body.length} bytes)");
      final url = Uri.https("code.conservify.org", "diagnostics/$id/logs.txt");
      Loggers.main.i("uploading: $url");
      final response = await http.post(url, body: body);
      Loggers.main.i("upload: $response");
      final meta = response.body;
      Loggers.main.i("upload: $meta");

      return id.toString();
    } catch (e) {
      Loggers.main.e("send logs failed: $e");
      return null;
    }
  }
}

class Backup {
  Future<Directory> getDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  Future<String?> create() async {
    try {
      final DateFormat formatter = DateFormat('yyyyMMdd_HHmmss');
      final stamp = formatter.format(DateTime.now());
      final destination = await getDirectory();
      final zipPath = "${destination.path}/fk-$stamp.zip";

      final support = await getApplicationSupportDirectory();
      Loggers.main.i("backup: ${support.path}");

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      await encoder.addFile(File("${support.path}/db.sqlite3"));
      await encoder.addFile(File("${support.path}/logs.txt"));
      final data = Directory("${support.path}/fk-data");
      if (data.existsSync()) {
        await encoder.addDirectory(data);
      } else {
        Loggers.main.i("backup: no fk-data");
      }
      await encoder.close();

      Loggers.main.i("backup: $zipPath");
      return zipPath;
    } catch (e) {
      Loggers.main.e("backup:failed: $e");
      return null;
    }
  }
}
