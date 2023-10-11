import 'package:fk/settings/accounts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fk/app_state.dart';
import 'package:fk/gen/bridge_definitions.dart';
import 'package:mockito/mockito.dart';

class MockNative extends Mock implements Native {}

void main() {
  // Creating a mock API object
  final Native mockApi = MockNative();

  // Utility function to create testable widget with or without accounts
  Widget makeTestableWidget(
      {required Widget child, List<PortalAccount>? accounts}) {
    return MaterialApp(
      home: ChangeNotifierProvider<PortalAccounts>(
        create: (_) => PortalAccounts(api: mockApi, accounts: accounts ?? []),
        child: child,
      ),
    );
  }

  final Finder myAssetFinder = find.byWidgetPredicate(
    (Widget widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName ==
            'resources/flows/uploads/Fieldkit_couple2.png',
    description: 'Image with specific asset',
  );

  // TODO: Add test for the case when there are no accounts

  // TODO: Add test for the cas where there ARE accounts
}
