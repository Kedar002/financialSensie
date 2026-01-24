// Basic widget test for FinanceSensei app.

import 'package:flutter_test/flutter_test.dart';
import 'package:financesensei/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FinanceSenseiApp());

    // Verify app loads
    await tester.pumpAndSettle();
  });
}
