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

class ExpandableBorderedListItem extends StatefulWidget {
  final GenericListItemHeader header;
  final List<Widget> children;
  final bool expanded;

  const ExpandableBorderedListItem({super.key, required this.header, required this.children, required this.expanded});

  @override
  State<StatefulWidget> createState() => _ExpandableBorderedListItemState();
}

class _ExpandableBorderedListItemState extends State<ExpandableBorderedListItem> {
  bool? _expanded;

  bool get expanded => _expanded ?? widget.expanded;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          setState(() {
            _expanded = !expanded;
          });
        },
        child: BorderedListItem(header: widget.header, children: [if (expanded) ...widget.children]));
  }
}

class GenericListItemHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Icon? trailing;
  final VoidCallback? onTap;

  const GenericListItemHeader(
      {super.key, required this.title, this.subtitle, this.titleStyle, this.subtitleStyle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final maybeTrailing = trailing;
    final top = WH.align(WH.padPage(Row(children: [
      Text(title, style: titleStyle ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.normal)),
      if (maybeTrailing != null) maybeTrailing
    ])));

    if (subtitle == null) {
      return top;
    }

    final bottom = WH.align(WH.padPage(Text(subtitle!, style: subtitleStyle)));

    return Column(children: [top, bottom]);
  }
}

class WH {
  static const pagePadding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  static Align align(Widget child) => Align(alignment: Alignment.topLeft, child: child);

  static Padding around(Widget child) => Padding(padding: pagePadding, child: child);

  static Padding vertical(Widget child) => Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: child);

  static Container padPage(Widget child) => Container(padding: pagePadding, child: child);

  static List<Widget> padButtonsRow(List<Widget> children) =>
      children.map((c) => Padding(padding: const EdgeInsets.only(right: 10), child: c)).toList();

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
