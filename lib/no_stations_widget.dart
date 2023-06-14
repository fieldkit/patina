import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'common_widgets.dart';

class MaybeBracketed {
  final String text;
  final bool bracketed;

  MaybeBracketed(this.text, this.bracketed);
}

// I'd love a better way to do this.
List<MaybeBracketed> extractBracketedText(String text) {
  final List<MaybeBracketed> parsed = List.empty(growable: true);
  int i = 0;
  while (i < text.length) {
    int start = text.indexOf("[", i);
    if (start == -1) {
      parsed.add(MaybeBracketed(text.substring(i, text.length), false));
      break;
    } else {
      int end = text.indexOf("]", start);
      if (end == -1) {
        parsed.add(MaybeBracketed("Malformed bracketed text", false));
        break;
      } else {
        parsed.add(MaybeBracketed(text.substring(i, start), false));
        parsed.add(MaybeBracketed(text.substring(start + 1, end), true));
        i = end + 1;
      }
    }
  }
  return parsed;
}

class NoStationsHelpWidget extends StatelessWidget {
  const NoStationsHelpWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    const paragraphStyle = TextStyle(fontSize: 16, color: Colors.black);
    const linkStyle = TextStyle(fontSize: 16, color: Colors.grey);

    final parsed = extractBracketedText(localizations.noStationsSeeGuide);
    final spans = parsed.map((e) {
      if (e.bracketed) {
        return TextSpan(
            style: linkStyle,
            text: e.text,
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                await launchUrlString(localizations.productGuideUrl);
              });
      } else {
        return TextSpan(style: paragraphStyle, text: e.text);
      }
    }).toList();

    return WH.padPage(ColoredBox(
        color: const Color.fromRGBO(232, 232, 232, 1),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(localizations.noStationsTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 60), child: RichText(text: TextSpan(children: spans)))
        ])));
  }
}
