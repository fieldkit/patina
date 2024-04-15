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
                  images { url }
                  logo { url }
              }
          }
      }'''
  };

  logger.i("downloading json");

  final response = await http.post(Uri.parse("$baseUrl/graphql"),
      body: json.encode(query), headers: {"Content-Type": "application/json"});
  await file.writeAsBytes(response.bodyBytes);
  final data = await file.readAsString();
  final flows = ContentFlows.get(data);

  for (final screen in flows.allScreens.values) {
    for (final simple in screen.simple) {
      for (final image in simple.images) {
        logger.i("downloading ${image.url}");

        final response = await http.get(Uri.parse(baseUrl + image.url));
        final writing = File(resources + image.url);
        await writing.writeAsBytes(response.bodyBytes);
      }
    }
  }
}

Future<void> test(Logger logger, String resources) async {
  final file = File("$resources/flows_en.json");
  final data = await file.readAsString();
  final flows = ContentFlows.get(data);
  for (final screen in flows.allScreens.values) {
    for (final simple in screen.simple) {
      final parser = MarkdownVerifyParser(logger: logger, images: List.empty());
      parser.parse(simple.body);
    }
  }
}

void main(List<String> args) async {
  final logger = Logger(printer: SimplePrinter());
  final resourcesPath = "../resources/flows";

  for (final arg in args) {
    if (arg == "--sync") {
      await download(logger, resourcesPath);
    }
    if (arg == "--test") {
      await test(logger, resourcesPath);
    }
  }
}
