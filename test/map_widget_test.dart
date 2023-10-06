import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:fk/map_widget.dart';

void main() {
  group('Map widget', () {
    testWidgets('renders a FlutterMap widget', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Map()));

      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('FlutterMap contains TileLayer', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MaterialApp(home: Map()));

      // Verify if TileLayer is present.
      expect(find.byType(TileLayer), findsOneWidget);
    });

    testWidgets('has correct initial center and zoom for default',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Map()));

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.center, equals(LatLng(48.864716, 2.349014)));
      expect(map.options.zoom, equals(9.2));
    });

    testWidgets('renders a TileLayer with correct URL template',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Map()));

      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tileLayer.urlTemplate,
          equals('https://tile.openstreetmap.org/{z}/{x}/{y}.png'));
    });
  });
}
