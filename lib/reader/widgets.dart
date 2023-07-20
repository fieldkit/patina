import 'package:flows/flows.dart';
import 'package:flutter/material.dart' show Widget, StatelessWidget, BuildContext, Text, Column;
import 'package:markdown/markdown.dart' as md;

class MarkdownWidgetParser extends MarkdownParser<Widget> {
  MarkdownWidgetParser({super.logger});

  MarkdownRootWidget parse(String markdownContent) {
    md.Document document = md.Document(encodeHtml: false);
    List<String> lines = markdownContent.split('\n');
    for (md.Node node in document.parseLines(lines)) {
      node.accept(this);
    }
    return MarkdownRootWidget(children: parsed);
  }

  @override
  Builder<Widget> header({required int depth}) {
    return _HeaderBuilder(depth: depth);
  }

  @override
  Builder<Widget> paragraph() {
    return _ParagraphBuilder();
  }

  @override
  Builder<Widget> image({required List<int> indices, required String? sizing, required String alt}) {
    return _ImageBuilder(indices: indices, sizing: sizing, alt: alt);
  }

  @override
  Builder<Widget> link({required String href}) {
    return _LinkBuilder(href: href);
  }

  @override
  Builder<Widget> unordered() {
    return _UnorderedBuilder();
  }

  @override
  Builder<Widget> listItem() {
    return _ListItemBuilder();
  }
}

class MarkdownRootWidget extends StatelessWidget {
  final List<Widget> children;

  const MarkdownRootWidget({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class MarkdownHeaderWidget extends StatelessWidget {
  final String text;
  final int depth;
  final List<Widget> children;

  const MarkdownHeaderWidget({super.key, required this.text, required this.depth, required this.children});

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}

class MarkdownParagraphWidget extends StatelessWidget {
  final String text;
  final List<Widget> children;

  const MarkdownParagraphWidget({super.key, required this.text, required this.children});

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}

class MarkdownImageWidget extends StatelessWidget {
  final List<int> indices;
  final String? sizing;
  final String alt;

  const MarkdownImageWidget({super.key, required this.indices, this.sizing, required this.alt});

  @override
  Widget build(BuildContext context) {
    return const Text("IMAGE");
  }
}

class MarkdownLinkWidget extends StatelessWidget {
  final String text;
  final String href;

  const MarkdownLinkWidget({super.key, required this.text, required this.href});

  @override
  Widget build(BuildContext context) {
    return const Text("LINK");
  }
}

class MarkdownUnorderedWidget extends StatelessWidget {
  final List<Widget> children;

  const MarkdownUnorderedWidget({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return const Text("UNORDERED");
  }
}

class MarkdownListItemWidget extends StatelessWidget {
  final String text;

  const MarkdownListItemWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return const Text("LIST ITEM");
  }
}

class _HeaderBuilder extends Builder<MarkdownHeaderWidget> {
  final int depth;

  _HeaderBuilder({required this.depth});

  @override
  MarkdownHeaderWidget build() {
    return MarkdownHeaderWidget(text: text ?? "", depth: depth, children: children());
  }
}

class _ParagraphBuilder extends Builder<MarkdownParagraphWidget> {
  @override
  MarkdownParagraphWidget build() {
    return MarkdownParagraphWidget(text: text ?? "", children: children());
  }
}

class _ImageBuilder extends Builder<MarkdownImageWidget> {
  final List<int> indices;
  final String? sizing;
  final String alt;

  _ImageBuilder({required this.sizing, required this.alt, required this.indices});

  @override
  MarkdownImageWidget build() {
    return MarkdownImageWidget(indices: indices, sizing: sizing, alt: alt);
  }
}

class _LinkBuilder extends Builder<MarkdownLinkWidget> {
  final String href;

  _LinkBuilder({required this.href});

  @override
  MarkdownLinkWidget build() {
    return MarkdownLinkWidget(text: text ?? "", href: href);
  }
}

class _UnorderedBuilder extends Builder<MarkdownUnorderedWidget> {
  @override
  MarkdownUnorderedWidget build() {
    return MarkdownUnorderedWidget(children: children());
  }
}

class _ListItemBuilder extends Builder<MarkdownListItemWidget> {
  @override
  MarkdownListItemWidget build() {
    return MarkdownListItemWidget(text: text ?? "");
  }
}
