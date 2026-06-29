// Integration tests for key user flows.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memoryos/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots and shows Home page', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Home page title should be visible
    expect(find.textContaining('Memory'), findsAtLeastNWidgets(1));
  });

  testWidgets('Navigate from Home to Search', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Tap search icon in AppBar
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pumpAndSettle();

    // Search field should be visible
    expect(find.byType(TextField), findsAtLeastNWidgets(1));
  });

  testWidgets('Navigate to AI Chat', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Find chat destination in nav
    final chatFinder = find.text('AI Chat');
    if (chatFinder.evaluate().isNotEmpty) {
      await tester.tap(chatFinder.first);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    }
  });
}
