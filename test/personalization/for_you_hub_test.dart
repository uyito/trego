import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/personalization/for_you_hub.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('ForYouHub builds and shows its three tabs', (tester) async {
    // ForYouHub embeds EnhancedRecommendationsScreen (reads
    // FirebaseAuth.instance.currentUser directly in build) and
    // AchievementsScreen (constructs AuthService() in initState) as its
    // first two tabs. Neither is injectable — ForYouHub takes no
    // constructor params and this migration preserves that public API —
    // so both touch FirebaseAuth.instance with no Firebase app configured
    // in this test host. We swallow the expected "No Firebase App" build
    // error the same way test/achievements/achievements_screen_test.dart
    // and test/recipes/recipe_screen_test.dart do, since it only affects
    // which data loads, not whether the hub and its tabs render.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      // The Recommendations tab (EnhancedRecommendationsScreen) kicks off
      // real ApiClient/Dio network calls from initState with no way to
      // inject a fake service (its public API — no constructor params — is
      // preserved by this migration). Run under runAsync so those real
      // Futures (which fail fast with no server listening) actually
      // resolve instead of leaving a connection-timeout Timer pending when
      // the test ends.
      await tester.runAsync(() async {
        await tester.pumpWidget(testApp(const ForYouHub()));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Recommendations'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    } finally {
      FlutterError.onError = previousOnError;
    }

    for (final e in captured) {
      final msg = e.toString();
      // Firebase isn't initialized in this test host ("No Firebase App"),
      // and EnhancedApiClient's connectivity_plus monitoring has no plugin
      // implementation registered here ("MissingPluginException" on the
      // connectivity_status channel) — both pre-existing, expected gaps of
      // running network/Firebase-backed services outside a real app host,
      // unrelated to this token migration.
      final expected = msg.contains('No Firebase App') ||
          msg.contains('MissingPluginException');
      expect(
        expected,
        isTrue,
        reason: 'Unexpected exception during ForYouHub test: $e',
      );
    }
  });
}
