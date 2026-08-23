import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/recipes/recipe_screen.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('RecipeScreen builds and shows the recipe list view',
      (tester) async {
    // RecipeScreen constructs AuthService(), which touches
    // FirebaseAuth.instance — Firebase isn't initialized in this test host.
    // We swallow the expected "No Firebase App" build error the same way
    // test/nutrition/nutrition_hub_test.dart does, since it only affects
    // the greeting name, not the rest of the screen.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      await tester.pumpWidget(testApp(const RecipeScreen()));
      await tester.pump();

      expect(find.text("What's On Your Plate Today?"), findsOneWidget);
      expect(find.text('Easy AI Recipes'), findsOneWidget);
      expect(find.text('Daily Meal Plan'), findsOneWidget);
    } finally {
      FlutterError.onError = previousOnError;
    }

    for (final e in captured) {
      final msg = e.toString();
      expect(
        msg.contains('No Firebase App'),
        isTrue,
        reason: 'Unexpected exception during RecipeScreen test: $e',
      );
    }
  });
}
