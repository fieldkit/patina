import 'dart:async';

import 'package:fk/diagnostics.dart';
import 'package:flows/flows.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart'
    show
        BoxFit,
        BuildContext,
        Image,
        Column,
        CrossAxisAlignment,
        EdgeInsets,
        InkWell,
        Padding,
        Row,
        SizedBox,
        State,
        StatefulWidget,
        StatelessWidget,
        Text,
        TextStyle,
        Widget;
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownWidgetParser extends MarkdownParser<Widget> {
  MarkdownWidgetParser({super.logger, required super.images});

  MarkdownRootWidget parse(String markdownContent) {
    final children = parseString(markdownContent);
    // If the markdown content didn't have any images but the screen does, we
    // fabricate one that will cycle through all referenced images.
    if (!hasImages && images.isNotEmpty) {
      children.add(MarkdownImageWidget(
          images: images, indices: List.empty(), alt: "Images"));
    }
    return MarkdownRootWidget(children: children);
  }

  @override
  Builder<Widget, Widget> header({required int depth}) {
    return _HeaderBuilder(depth: depth);
  }

  @override
  Builder<Widget, Widget> paragraph() {
    return _ParagraphBuilder();
  }

  @override
  Builder<Widget, Widget> image(
      {required List<int> indices,
      required String? sizing,
      required String alt}) {
    return _ImageBuilder(
        images: images, indices: indices, sizing: sizing, alt: alt);
  }

  @override
  Builder<Widget, Widget> link({required String href}) {
    return _LinkBuilder(href: href);
  }

  @override
  Builder<Widget, Widget> unordered() {
    return _UnorderedBuilder();
  }

  @override
  Builder<Widget, Widget> listItem() {
    return _ListItemBuilder();
  }

  @override
  Builder<Widget, Widget> table() {
    return _TableBuilder();
  }

  @override
  Builder<Widget, Widget> tableHead() {
    return _TableHeadBuilder();
  }

  @override
  Builder<Widget, Widget> tableBody() {
    return _TableBodyBuilder();
  }

  @override
  Builder<Widget, Widget> tableRow() {
    return _TableRowBuilder();
  }

  @override
  Builder<Widget, Widget> tableCell() {
    return _TableCellBuilder();
  }

  @override
  Builder<Widget, Widget> tableHeaderCell() {
    return _TableHeaderCellBuilder();
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

  const MarkdownHeaderWidget(
      {super.key,
      required this.text,
      required this.depth,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontFamily: 'Avenir', fontSize: 20.0));
  }
}

class MarkdownParagraphWidget extends StatelessWidget {
  final String text;
  final List<Widget> children;

  const MarkdownParagraphWidget({
    super.key,
    required this.text,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(fontFamily: 'Avenir')),
        const SizedBox(height: 8),
        ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: child,
            )),
      ],
    );
  }
}

class MarkdownImageWidget extends StatefulWidget {
  final List<ImageRef> images;
  final List<int> indices;
  final String? sizing;
  final String alt;

  const MarkdownImageWidget({
    super.key,
    required this.images,
    required this.indices,
    required this.alt,
    this.sizing,
  });

  @override
  State<StatefulWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<MarkdownImageWidget> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _currentIndex = 0;
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        setState(() {
          if (widget.images.isEmpty) {
            _currentIndex = 0;
          } else {
            // If index list is empty, we cycle through all the referenced images.
            if (widget.indices.isEmpty) {
              _currentIndex = (_currentIndex + 1) % widget.images.length;
            } else {
              _currentIndex = (_currentIndex + 1) % widget.indices.length;
            }
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ImageRef get visibleImage {
    // If index list is empty, we cycle through all the referenced images.
    if (widget.indices.isEmpty) {
      return widget.images[_currentIndex];
    } else {
      return widget.images[widget.indices[_currentIndex]];
    }
  }

  String get visiblePath {
    final String image = visibleImage.url;
    if (p.isAbsolute(image)) {
      return p.join("resources/flows", image.substring(1));
    } else {
      return p.join("resources/flows", image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String path = visiblePath;
    Loggers.ui.i("image[$_currentIndex]: $path");
    if (p.extension(path) == ".svg") {
      return SvgPicture.asset(path, fit: BoxFit.contain);
    } else {
      return Image.asset(path, fit: BoxFit.contain);
    }
  }
}

class MarkdownLinkWidget extends StatelessWidget {
  final String text;
  final String href;

  const MarkdownLinkWidget({super.key, required this.text, required this.href});

  @override
  Widget build(BuildContext context) {
    final Uri uri = Uri.parse(href);
    return InkWell(child: Text(text), onTap: () => launchUrl(uri));
  }
}

class MarkdownUnorderedWidget extends StatelessWidget {
  final List<Widget> children;

  const MarkdownUnorderedWidget({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class MarkdownListItemWidget extends StatelessWidget {
  final String text;

  const MarkdownListItemWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontFamily: 'Avenir'));
  }
}

class MarkdownTableWidget extends StatelessWidget {
  final List<Widget> children;

  const MarkdownTableWidget({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class MarkdownTableHeadWidget extends StatelessWidget {
  final List<Widget> children;

  const MarkdownTableHeadWidget({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class MarkdownTableBodyWidget extends StatelessWidget {
  final List<Widget> children;

  const MarkdownTableBodyWidget({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class MarkdownTableRowWidget extends StatelessWidget {
  final List<Widget> children;

  const MarkdownTableRowWidget({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(children: children);
  }
}

class MarkdownTableHeaderCellWidget extends StatelessWidget {
  final String text;

  const MarkdownTableHeaderCellWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontFamily: 'Avenir'));
  }
}

class MarkdownTableCellWidget extends StatelessWidget {
  final String text;

  const MarkdownTableCellWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontFamily: 'Avenir'));
  }
}

class _HeaderBuilder extends Builder<MarkdownHeaderWidget, Widget> {
  final int depth;

  _HeaderBuilder({required this.depth});

  @override
  MarkdownHeaderWidget build() {
    return MarkdownHeaderWidget(
        text: text ?? "", depth: depth, children: children());
  }
}

class _ParagraphBuilder extends Builder<MarkdownParagraphWidget, Widget> {
  @override
  MarkdownParagraphWidget build() {
    return MarkdownParagraphWidget(text: text ?? "", children: children());
  }
}

class _ImageBuilder extends Builder<MarkdownImageWidget, Widget> {
  final List<ImageRef> images;
  final List<int> indices;
  final String? sizing;
  final String alt;

  _ImageBuilder(
      {required this.images,
      required this.sizing,
      required this.alt,
      required this.indices});

  @override
  MarkdownImageWidget build() {
    return MarkdownImageWidget(
        images: images, indices: indices, sizing: sizing, alt: alt);
  }
}

class _LinkBuilder extends Builder<MarkdownLinkWidget, Widget> {
  final String href;

  _LinkBuilder({required this.href});

  @override
  MarkdownLinkWidget build() {
    return MarkdownLinkWidget(text: text ?? "", href: href);
  }
}

class _UnorderedBuilder extends Builder<MarkdownUnorderedWidget, Widget> {
  @override
  MarkdownUnorderedWidget build() {
    return MarkdownUnorderedWidget(children: children());
  }
}

class _ListItemBuilder extends Builder<MarkdownListItemWidget, Widget> {
  @override
  MarkdownListItemWidget build() {
    return MarkdownListItemWidget(text: text ?? "");
  }
}

class _TableBuilder extends Builder<MarkdownTableWidget, Widget> {
  @override
  MarkdownTableWidget build() {
    return MarkdownTableWidget(children: children());
  }
}

class _TableHeadBuilder extends Builder<MarkdownTableHeadWidget, Widget> {
  @override
  MarkdownTableHeadWidget build() {
    return MarkdownTableHeadWidget(children: children());
  }
}

class _TableBodyBuilder extends Builder<MarkdownTableBodyWidget, Widget> {
  @override
  MarkdownTableBodyWidget build() {
    return MarkdownTableBodyWidget(children: children());
  }
}

class _TableRowBuilder extends Builder<MarkdownTableRowWidget, Widget> {
  @override
  MarkdownTableRowWidget build() {
    return MarkdownTableRowWidget(children: children());
  }
}

class _TableHeaderCellBuilder
    extends Builder<MarkdownTableHeaderCellWidget, Widget> {
  @override
  MarkdownTableHeaderCellWidget build() {
    return MarkdownTableHeaderCellWidget(text: text ?? "");
  }
}

class _TableCellBuilder extends Builder<MarkdownTableCellWidget, Widget> {
  @override
  MarkdownTableCellWidget build() {
    return MarkdownTableCellWidget(text: text ?? "");
  }
}
