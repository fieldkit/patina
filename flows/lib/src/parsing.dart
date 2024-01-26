import 'package:markdown/markdown.dart' as md;
import 'package:logger/logger.dart';

abstract class Builder<T, C> {
  final List<C> _children = List.empty(growable: true);
  String? text;

  T build();

  void addChild(C child) {
    _children.add(child);
  }

  List<C> children() {
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
  List<Builder<T, T>> builders = List.empty(growable: true);

  MarkdownParser({this.logger});

  Builder<T, T> paragraph();
  Builder<T, T> header({required int depth});
  Builder<T, T> image(
      {required List<int> indices,
      required String? sizing,
      required String alt});
  Builder<T, T> link({required String href});
  Builder<T, T> unordered();
  Builder<T, T> listItem();
  Builder<T, T> table();
  Builder<T, T> tableHead();
  Builder<T, T> tableBody();
  Builder<T, T> tableRow();
  Builder<T, T> tableHeaderCell();
  Builder<T, T> tableCell();

  List<T> parseString(String markdownContent) {
    md.Document document =
        md.Document(blockSyntaxes: [md.TableSyntax()], encodeHtml: false);
    List<String> lines = markdownContent.split('\n');
    for (md.Node node in document.parseLines(lines)) {
      node.accept(this);
    }
    return parsed;
  }

  @override
  bool visitElementBefore(md.Element element) {
    logger?.v("BEGIN ${element.tag}");

    switch (element.tag) {
      case "p":
        builders.add(paragraph());
        break;
      case "h1":
        builders.add(header(depth: 1));
        break;
      // Treat h2 and below as paragraphs
      case "h2":
      case "h3":
      case "h4":
      case "h5":
      case "h6":
      case "h7":
      case "h8":
      case "h9":
        builders.add(paragraph());
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
      case "table":
        builders.add(table());
        break;
      case "thead":
        builders.add(tableHead());
        break;
      case "tbody":
        builders.add(tableBody());
        break;
      case "tr":
        builders.add(tableRow());
        break;
      case "th":
        builders.add(tableHeaderCell());
        break;
      case "td":
        builders.add(tableCell());
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
    logger?.v("  END ${element.tag}");

    final builder = builders.isEmpty ? null : builders.removeLast();
    final widget = builder?.build();
    if (builder != null && widget != null) {
      logger?.i("created $widget");

      final children = builder.children();
      assert(children.isEmpty,
          "tag '${element.tag}' still has unused children: $children");
      if (builders.isEmpty) {
        parsed.add(widget);
      } else {
        logger?.i("appending to ${builders.last}");
        builders.last.addChild(widget);
      }
    }
  }
}

class OkBuilder extends Builder<String, String> {
  final String name;
  final bool getChildren;

  OkBuilder({required this.name, this.getChildren = false});

  @override
  String build() {
    if (getChildren) {
      children();
    }
    return name;
  }
}

class MarkdownVerifyParser extends MarkdownParser {
  MarkdownVerifyParser({super.logger});

  void parse(String markdownContent) {
    parseString(markdownContent);
  }

  @override
  Builder header({required int depth}) {
    return OkBuilder(name: "header depth=$depth", getChildren: true);
  }

  @override
  Builder paragraph() {
    return OkBuilder(name: "paragraph", getChildren: true);
  }

  @override
  Builder image(
      {required List<int> indices,
      required String? sizing,
      required String alt}) {
    return OkBuilder(name: "image indices=$indices alt=$alt sizing=$sizing");
  }

  @override
  Builder link({required String href}) {
    return OkBuilder(name: "link href=$href");
  }

  @override
  Builder listItem() {
    return OkBuilder(name: "list-item");
  }

  @override
  Builder unordered() {
    return OkBuilder(name: "unordered", getChildren: true);
  }

  @override
  Builder table() {
    return OkBuilder(name: "table", getChildren: true);
  }

  @override
  Builder tableHead() {
    return OkBuilder(name: "table head", getChildren: true);
  }

  @override
  Builder tableBody() {
    return OkBuilder(name: "table body", getChildren: true);
  }

  @override
  Builder tableRow() {
    return OkBuilder(name: "table row", getChildren: true);
  }

  @override
  Builder tableHeaderCell() {
    return OkBuilder(name: "table header cell", getChildren: true);
  }

  @override
  Builder tableCell() {
    return OkBuilder(name: "table cell", getChildren: true);
  }
}
