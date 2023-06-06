import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  static Align align(child) => Align(alignment: Alignment.topLeft, child: child);

  static Container padPage(child) => Container(padding: pagePadding, child: child);

  static Container padChildrenPage(children) => Container(padding: pagePadding, child: Column(children: children));

  static Padding padLabel(Widget child) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: child);

  static Padding padColumn(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: child);

  static Padding padBelowProgress(Widget child) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: child);

  static LinearProgressIndicator progressBar(double value) => LinearProgressIndicator(value: value);
}

class OopsBug extends StatelessWidget {
  const OopsBug({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(AppLocalizations.of(context)!.oopsBugTitle);
  }
}
