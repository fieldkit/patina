import 'dart:convert';

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

class ImageRef {
  final String url;
  final String? alt;

  ImageRef({required this.url, required this.alt});

  factory ImageRef.fromJson(Map<String, dynamic> data) {
    final url = data['url'] as String;
    final alt = data['alternativeText'] as String?;

    return ImageRef(url: url, alt: alt);
  }
}

class Simple {
  final String body;
  final List<ImageRef> images;
  final ImageRef? logo;

  Simple({required this.body, required this.images, required this.logo});

  factory Simple.fromJson(Map<String, dynamic> data) {
    final body = data['body'] as String;
    final logoData = data['logo'] as Map<String, dynamic>?;
    final logo = logoData != null ? ImageRef.fromJson(logoData) : null;
    final imagesData = data['images'] as List<dynamic>?;
    final images = imagesData != null
        ? imagesData.map((imageData) => ImageRef.fromJson(imageData)).toList()
        : <ImageRef>[];

    return Simple(body: body, images: images, logo: logo);
  }
}

class Header {
  final String title;
  final String? subtitle;

  Header({required this.title, this.subtitle});

  factory Header.fromJson(Map<String, dynamic> data) {
    final title = data['title'] as String;
    final subtitle = coerceEmptyStringsToNull(data['subtitle'] as String?);

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
    final skip = coerceEmptyStringsToNull(data["skip"] as String?);
    final guideTitle = coerceEmptyStringsToNull(data["guide_title"] as String?);
    final guideUrl = coerceEmptyStringsToNull(data["guide_url"] as String?);
    final headerData = data["header"] as Map<String, dynamic>?;
    final header = headerData != null ? Header.fromJson(headerData) : null;
    final simpleData = data["simple"] as List<dynamic>?;
    final simple = simpleData != null
        ? simpleData.map((row) => Simple.fromJson(row)).toList()
        : List<Simple>.empty();

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

  @override
  String toString() {
    return "Screen<$id, $name>";
  }
}

class ContentFlows {
  final Map<String, Flow> allFlows;
  final Map<String, Screen> allScreens;

  const ContentFlows({required this.allFlows, required this.allScreens});

  static ContentFlows get(String text) {
    final parsed = jsonDecode(text);
    final flowsData = parsed["data"]["flows"] as List<dynamic>;
    final screensData = parsed["data"]["screens"] as List<dynamic>;

    final Map<String, Flow> flows = Map.fromIterable(
        flowsData.map((flowData) => Flow.fromJson(flowData)),
        key: (v) => v.name);

    final Map<String, Screen> screens = Map.fromIterable(
        screensData.map((screenData) => Screen.fromJson(screenData)),
        key: (v) => v.name);

    return ContentFlows(allFlows: flows, allScreens: screens);
  }

  List<Screen> getScreensWithPrefix(String prefix) {
    return allScreens.values
        .where((screen) => screen.name.startsWith(prefix))
        .toList()
        .sortedWith((a, b) => a.name.compareTo(b.name));
  }

  List<String> getScreenNamesWithPrefix(String prefix) {
    return getScreensWithPrefix(prefix).map((s) => s.name).toList();
  }

  List<Screen> getScreens(StartFlow start) {
    if (start.prefix != null) {
      return getScreensWithPrefix(start.prefix!);
    }

    if (start.names != null) {
      return start.names!
          .map((name) => allScreens[name])
          .whereType<Screen>()
          .toList();
    }

    return List.empty();
  }

  Screen getScreen(String name) {
    return allScreens[name]!;
  }
}

class StartFlow {
  final String? prefix;
  final List<String>? names;

  const StartFlow({this.prefix, this.names});
}

String? coerceEmptyStringsToNull(String? source) {
  if (source != null && source.isEmpty) {
    return null;
  }
  return source;
}

extension ListSorted<T> on List<T> {
  List<T> sortedWith(int Function(T a, T b) compare) =>
      [...this]..sort(compare);
}
