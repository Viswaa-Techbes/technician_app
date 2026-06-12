import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/features/auth/widgets/auth_form_field.dart';

void main() {
  testWidgets('AuthFormField renders and accepts input text', (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthFormField(
            controller: controller,
            labelText: 'Email Address',
            hintText: 'john@example.com',
            prefixIcon: Icons.email,
          ),
        ),
      ),
    );

    // Verify label text is rendered
    expect(find.text('Email Address'), findsOneWidget);

    // Verify input works
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    expect(controller.text, 'test@example.com');
  });
}
