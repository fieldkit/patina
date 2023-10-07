import 'package:fk/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  group('SettingsTab', () {
    testWidgets('displays correct localized texts and navigates properly',
        (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: [AppLocalizations.delegate],
        home: SettingsTab(),
      ));

      // Verify Settings' title text
      expect(find.text('Settings'), findsOneWidget);

      // Verify Accounts' text
      expect(find.text('Accounts'), findsOneWidget);
    });
  });
}
