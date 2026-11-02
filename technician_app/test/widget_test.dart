import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:technician_app/main.dart';

void main() {
  testWidgets('TechnicianApp smoke test', (WidgetTester tester) async {
    // Build our app with ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TechbesApp()));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify TechbesApp builds successfully
    expect(find.byType(TechbesApp), findsOneWidget);
  });
}
