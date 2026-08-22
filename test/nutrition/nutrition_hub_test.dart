import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/nutrition/nutrition_hub.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('NutritionHub shows Recipes, Pantry, TDEE tabs', (tester) async {
    // RecipeScreen constructs AuthService(), which touches
    // FirebaseAuth.instance — Firebase isn't initialized in this test host.
    // We swallow the expected "No Firebase App" build error the same way
    // test/widget_test.dart does, since it only affects the Recipes tab's
    // content, not the tab bar itself.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      await tester.pumpWidget(testApp(const NutritionHub()));
      await tester.pump();
      expect(find.text('Recipes'), findsWidgets);
      expect(find.text('Pantry'), findsWidgets);
      expect(find.text('TDEE'), findsWidgets);
    } finally {
      FlutterError.onError = previousOnError;
    }

    for (final e in captured) {
      final msg = e.toString();
      expect(
        msg.contains('No Firebase App'),
        isTrue,
        reason: 'Unexpected exception during NutritionHub test: $e',
      );
    }
  });
}
