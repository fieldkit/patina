import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flows/flows.dart';

void main() async {
  final baseUrl = "https://strapi.conservify.org";
  final resourcesPath = "../resources/flows";
  final file = File("../resources/flows/flows.json");
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

  final response = await http.post(Uri.parse("$baseUrl/graphql"), body: json.encode(query), headers: {"Content-Type": "application/json"});
  await file.writeAsString(response.body);
  final data = await file.readAsString();
  final flows = ContentFlows.get(data);

  for (final screen in flows.screens) {
    for (final simple in screen.simple) {
      for (final image in simple.images) {
        print(image.url);
        final response = await http.get(Uri.parse(baseUrl + image.url));
        final writing = File(resourcesPath + image.url);
        await writing.writeAsBytes(response.bodyBytes);
      }
    }
  }
}
