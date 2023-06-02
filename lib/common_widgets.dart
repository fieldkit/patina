import 'package:flutter/material.dart';

class BorderedListItem extends StatelessWidget {
  final GenericListItemHeader header;
  final List<Widget> children;

  const BorderedListItem({super.key, required this.header, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromRGBO(212, 212, 212, 1),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: Column(children: [header, ...children]));
  }
}

class GenericListItemHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const GenericListItemHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final top = WH.align(WH.padPage(Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
    )));

    if (subtitle == null) {
      return top;
    }

    final bottom = WH.align(WH.padPage(Text(subtitle!)));

    return Column(children: [top, bottom]);
  }
}

class WH {
  static const pagePadding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  static align(child) => Align(alignment: Alignment.topLeft, child: child);

  static padPage(child) => Container(padding: pagePadding, child: child);

  static padChildrenPage(children) => Container(padding: pagePadding, child: Column(children: children));
}
