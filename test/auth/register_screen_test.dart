import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/auth/register_screen.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('RegisterScreen builds and shows key fields', (tester) async {
    // RegisterScreen constructs AuthService(), which touches
    // FirebaseAuth.instance — Firebase isn't initialized in this test host.
    // Swallow the expected "No Firebase App" build error the same way
    // test/recipes/recipe_screen_test.dart does.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      await tester.pumpWidget(testApp(const RegisterScreen()));
      await tester.pump();

      expect(find.text('Create Account'), findsAtLeastNWidgets(1));
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Confirm Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    } finally {
      FlutterError.onError = previousOnError;
    }

    for (final e in captured) {
      final msg = e.toString();
      expect(
        msg.contains('No Firebase App'),
        isTrue,
        reason: 'Unexpected exception during RegisterScreen test: $e',
      );
    }
  });
}
