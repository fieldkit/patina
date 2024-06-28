import 'package:fk/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/link.dart';

import 'common_widgets.dart';

class MaybeBracketed {
  final String text;
  final bool bracketed;

  MaybeBracketed(this.text, this.bracketed);
}

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
  final bool showImage;

  const NoStationsHelpWidget({super.key, this.showImage = true});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return WH.padPage(
      Column(children: [
        if (showImage)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: SizedBox(
                width: 200.0, // Adjust this value to your desired width
                height: 200.0,
                child: Image.asset('resources/images/data_sync.png',
                    fit: BoxFit.contain),
              )),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            localizations.connectStation,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 30.0),
          child: Text(
            localizations.noStationsDescription,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18.0,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Link(
          uri: Uri.parse(
              'https://www.fieldkit.org/product-guide/what-is-a-fieldkit-station'),
          target: LinkTarget.blank,
          builder: (BuildContext ctx, FollowLink? openLink) {
            return Center(
              child: TextButton(
                onPressed: openLink,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  textStyle: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Avenir',
                  ),
                ),
                child: Text(localizations.noStationsWhatIsStation),
              ),
            );
          },
        ),
        if (false)
          // ignore: dead_code
          Padding(
            padding: const EdgeInsets.fromLTRB(50, 20, 50, 20),
            child: ElevatedTextButton(
              onPressed: () {
                // TODO: Make this functional later
              },
              text: AppLocalizations.of(context)!.connectStation,
            ),
          ),
      ]),
    );
  }
}
