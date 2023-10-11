import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fk/splash_screen.dart';

void main() {
  testWidgets('FullScreenLogo builds without errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FullScreenLogo()));
    expect(find.byType(FullScreenLogo), findsOneWidget);
  });

  testWidgets('FullScreenLogo contains the expected logo image',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FullScreenLogo()));

    // Check if the logo image is present
    final logoImage = find.byType(Image);
    expect(logoImage, findsOneWidget);

    // Check if it's the expected asset image
    final Image imageWidget = tester.widget(logoImage) as Image;
    final AssetImage assetImage = imageWidget.image as AssetImage;
    expect(assetImage.assetName, "resources/images/logo_fk_blue.png");
  });

  testWidgets('FullScreenLogo contains CircularProgressIndicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FullScreenLogo()));

    // Check if CircularProgressIndicator is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
