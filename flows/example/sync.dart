import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flows/flows.dart';
import 'package:logger/logger.dart';

Future<void> download(Logger logger, String resources) async {
  final baseUrl = "https://strapi.conservify.org";
  final file = File("$resources/flows_en.json");
  final query = {
    "query": '''{
          flows {
              id
              name
              show_progress
          }
          screens {
              id
              name
              locale
              forward
              skip
              guide_title
              guide_url
              header { title subtitle }
              simple {
                  body
                  images { url alternativeText }
                  logo { url alternativeText }
              }
          }
      }'''
  };

  try {
    logger.i("downloading json");

    final response = await http.post(Uri.parse("$baseUrl/graphql"),
        body: json.encode(query), headers: {"Content-Type": "application/json"});
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      final data = await file.readAsString();
      final flows = ContentFlows.get(data);

      for (final screen in flows.allScreens.values) {
        for (final simple in screen.simple) {
          for (final image in simple.images) {
            try {
              logger.i("downloading ${image.url}");

              final response = await http.get(Uri.parse(baseUrl + image.url));
              if (response.statusCode == 200) {
                final writing = File(resources + image.url);
                await writing.writeAsBytes(response.bodyBytes);
              } else {
                logger.e("Failed to download ${image.url}: ${response.statusCode}");
              }
            } catch (e) {
              logger.e("Error occurred while downloading ${image.url}: $e");
            }
          }
        }
      }
    } else {
      logger.e("Failed to download JSON: ${response.statusCode}");
    }
  } catch (e) {
    logger.e("Error occurred during download: $e");
  }
}

Future<void> test(Logger logger, String resources) async {
  try {
    final file = File("$resources/flows_en.json");
    final data = await file.readAsString();
    final flows = ContentFlows.get(data);
    for (final screen in flows.allScreens.values) {
      for (final simple in screen.simple) {
        try {
          final parser = MarkdownVerifyParser(logger: logger, images: List.empty());
          parser.parse(simple.body);
        } catch (e) {
          logger.e("Error occurred while parsing body: $e");
        }
      }
    }
  } catch (e) {
    logger.e("Error occurred during test: $e");
  }
}

void main(List<String> args) async {
  final logger = Logger(printer: SimplePrinter());

  final flags = args.where((a) => a.startsWith("--"));
  final paths = args.where((a) => !a.startsWith("--"));
  final resourcesPath = paths.firstOrNull;
  if (resourcesPath == null) {
    logger.e("missing resources path");
    return;
  }

  try {
    for (final arg in flags) {
      if (arg == "--sync") {
        await download(logger, resourcesPath);
      }
      if (arg == "--test") {
        await test(logger, resourcesPath);
      }
    }
  } catch (e) {
    logger.e("Error occurred in main: $e");
  }
}
