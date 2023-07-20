import 'package:markdown/markdown.dart' as md;
import 'package:logger/logger.dart';

abstract class Builder<T> {
  final List<T> _children = List.empty(growable: true);
  String? text;

  T build();

  void addChild(T child) {
    _children.add(child);
  }

  List<T> children() {
    final popped = [..._children];
    _children.clear();
    return popped;
  }

  void append(String tail) {
    text = (text ?? "") + tail;
  }
}

abstract class MarkdownParser<T> implements md.NodeVisitor {
  final Logger? logger;
  final List<T> parsed = List.empty(growable: true);
  List<Builder<T>> builders = List.empty(growable: true);

  MarkdownParser({this.logger});

  Builder<T> paragraph();
  Builder<T> header({required int depth});
  Builder<T> image({required List<int> indices, required String? sizing, required String alt});
  Builder<T> link({required String href});
  Builder<T> unordered();
  Builder<T> listItem();

  @override
  bool visitElementBefore(md.Element element) {
    logger?.d("BEGIN ${element.tag}");

    switch (element.tag) {
      case "p":
        builders.add(paragraph());
        break;
      case "h1":
        builders.add(header(depth: 1));
        break;
      case "h2":
        builders.add(header(depth: 2));
        break;
      case "h3":
        builders.add(header(depth: 3));
        break;
      case "h4":
        builders.add(header(depth: 4));
        break;
      case "h5":
        builders.add(header(depth: 5));
        break;
      case "img":
        final String source = element.attributes["src"]!;
        final parts = source.split(":");
        final indices = parts[0].split(",").map(int.parse).toList();
        final String? sizing = parts.length == 2 ? parts[1] : null;
        final String alt = element.attributes["alt"]!;
        builders.add(image(indices: indices, sizing: sizing, alt: alt));
        break;
      case "a":
        final String href = element.attributes["href"]!;
        builders.add(link(href: href));
        break;
      case "ul":
        builders.add(unordered());
        break;
      case "li":
        builders.add(listItem());
        break;
      default:
        assert(false, "unexpected tag: ${element.tag}");
    }
    return true;
  }

  @override
  void visitText(md.Text text) {
    final last = builders.isEmpty ? null : builders.last;
    last?.append(text.textContent);
  }

  @override
  void visitElementAfter(md.Element element) {
    logger?.d("  END ${element.tag}");

    final builder = builders.isEmpty ? null : builders.removeLast();
    final widget = builder?.build();
    if (builder != null && widget != null) {
      final children = builder.children();
      assert(children.isEmpty, "tag '${element.tag}' still has unused children: $children");

      if (builders.isEmpty) {
        parsed.add(widget);
      } else {
        builders.last.addChild(widget);
      }
    }
  }
}

class OkBuilder extends Builder<bool> {
  final bool getChildren;

  OkBuilder({this.getChildren = false});

  @override
  bool build() {
    if (getChildren) {
      children();
    }
    return true;
  }
}

class MarkdownVerifyParser extends MarkdownParser {
  MarkdownVerifyParser({super.logger});

  void parse(String markdownContent) {
    md.Document document = md.Document(encodeHtml: false);
    List<String> lines = markdownContent.split('\n');
    for (md.Node node in document.parseLines(lines)) {
      node.accept(this);
    }
  }

  @override
  Builder header({required int depth}) {
    return OkBuilder(getChildren: true);
  }

  @override
  Builder paragraph() {
    return OkBuilder(getChildren: true);
  }

  @override
  Builder image({required List<int> indices, required String? sizing, required String alt}) {
    return OkBuilder();
  }

  @override
  Builder link({required String href}) {
    return OkBuilder();
  }

  @override
  Builder listItem() {
    return OkBuilder();
  }

  @override
  Builder unordered() {
    return OkBuilder(getChildren: true);
  }
}
