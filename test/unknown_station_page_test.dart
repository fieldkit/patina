import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fk/unknown_station_page.dart';

void main() {
  group('NoSuchStationPage', () {
    testWidgets('displays correct localized texts',
        (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MaterialApp(
        localizationsDelegates: [AppLocalizations.delegate],
        home: NoSuchStationPage(),
      ));

      // Verify AppBar title text
      expect(find.text('Unknown Station'), findsOneWidget);

      // Verify ElevatedButton's text
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('pops the page when back button is pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NoSuchStationPage()),
                );
              },
              child: const Text('Open NoSuchStationPage'),
            ),
          ),
        ),
      ));

      // Navigate to NoSuchStationPage
      await tester.tap(find.text('Open NoSuchStationPage'));
      await tester.pumpAndSettle();

      // Verify that NoSuchStationPage is shown
      expect(find.text('Unknown Station'), findsOneWidget);

      // Tap back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Verify that NoSuchStationPage is popped and we are back to the previous page
      expect(find.text('Open NoSuchStationPage'), findsOneWidget);
    });
  });
}
