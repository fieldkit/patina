import 'package:markdown/markdown.dart' as md;
import 'dart:convert';

class UnorderedListNode {}

class ListItemNode {}

class ParagraphNode {}

class ImageNode {}

class H1Node {}

class H2Node {}

class MarkdownParser implements md.NodeVisitor {
  void parse(String markdownContent) {
    md.Document document = md.Document(encodeHtml: false);
    List<String> lines = markdownContent.split('\n');
    for (md.Node node in document.parseLines(lines)) {
      node.accept(this);
    }
  }

  @override
  bool visitElementBefore(md.Element element) {
    print('veb: ${element.tag} ${element.attributes} ${element.children}');
    return true;
  }

  @override
  void visitText(md.Text text) {
    print('vet: ${text.textContent}');
  }

  @override
  void visitElementAfter(md.Element element) {
    print('vea: ${element.tag}');
  }
}

class Flow {
  final String id;
  final String name;
  final bool showProgress;

  Flow({required this.id, required this.name, required this.showProgress});

  factory Flow.fromJson(Map<String, dynamic> data) {
    final id = data['id'] as String;
    final name = data['name'] as String;
    final showProgress = data["showProgress"] as bool?;

    return Flow(id: id, name: name, showProgress: showProgress ?? false);
  }
}

class Image {
  final String url;

  Image({required this.url});

  factory Image.fromJson(Map<String, dynamic> data) {
    final url = data['url'] as String;

    return Image(url: url);
  }
}

class Simple {
  final String body;
  final List<Image> images;
  final Image? logo;

  Simple({required this.body, required this.images, required this.logo});

  factory Simple.fromJson(Map<String, dynamic> data) {
    final body = data['body'] as String;
    final logoData = data['logo'] as Map<String, dynamic>?;
    final logo = logoData != null ? Image.fromJson(logoData) : null;
    final imagesData = data['images'] as List<dynamic>?;
    final images = imagesData != null ? imagesData.map((imageData) => Image.fromJson(imageData)).toList() : <Image>[];

    return Simple(body: body, images: images, logo: logo);
  }
}

class Header {
  final String title;
  final String? subtitle;

  Header({required this.title, this.subtitle});

  factory Header.fromJson(Map<String, dynamic> data) {
    final title = data['title'] as String;
    final subtitle = data['subtitle'] as String?;

    return Header(title: title, subtitle: subtitle);
  }
}

class Screen {
  final String id;
  final String name;
  final String locale;
  final String forward;
  final String? skip;
  final String? guideTitle;
  final String? guideUrl;
  final Header? header;
  final List<Simple> simple;

  Screen(
      {required this.id,
      required this.name,
      required this.locale,
      required this.forward,
      this.skip,
      this.guideTitle,
      this.guideUrl,
      this.header,
      required this.simple});

  factory Screen.fromJson(Map<String, dynamic> data) {
    final id = data["id"] as String;
    final name = data["name"] as String;
    final locale = data["locale"] as String;
    final forward = data["forward"] as String;
    final skip = data["skip"] as String?;
    final guideTitle = data["guideTItle"] as String?;
    final guideUrl = data["guideUrl"] as String?;
    final headerData = data["header"] as Map<String, dynamic>?;
    final header = headerData != null ? Header.fromJson(headerData) : null;
    final simpleData = data["simple"] as List<dynamic>?;
    final simple = simpleData != null ? simpleData.map((row) => Simple.fromJson(row)).toList() : List<Simple>.empty();

    return Screen(
        id: id,
        name: name,
        locale: locale,
        forward: forward,
        skip: skip,
        guideTitle: guideTitle,
        guideUrl: guideUrl,
        header: header,
        simple: simple);
  }
}

class ContentFlows {
  final List<Flow> flows;
  final List<Screen> screens;

  const ContentFlows({required this.flows, required this.screens});

  static ContentFlows get(String text) {
    final parsed = jsonDecode(text);
    final flowsData = parsed["data"]["flows"] as List<dynamic>;
    final screensData = parsed["data"]["screens"] as List<dynamic>;

    final flows = flowsData.map((flowData) => Flow.fromJson(flowData)).toList();
    final screens = screensData.map((screenData) => Screen.fromJson(screenData)).toList();

    return ContentFlows(flows: flows, screens: screens);
  }
}
