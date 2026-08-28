import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/achievements/achievement_model.dart';
import 'package:trego/achievements/achievement_service.dart';
import 'package:trego/achievements/achievements_screen.dart';

import '../helpers/test_app.dart';

/// Fake AchievementService so the render test never touches Firestore.
class _FakeAchievementService implements AchievementService {
  final List<Achievement> achievements;

  _FakeAchievementService({this.achievements = const []});

  @override
  Future<List<Achievement>> getUserAchievements(String userId) async => achievements;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  initTestEnv();

  testWidgets('AchievementsScreen builds and shows the header title', (tester) async {
    // AchievementsScreen reads AuthService().currentUser in initState, which
    // touches FirebaseAuth.instance — Firebase isn't initialized in this
    // test host. That's caught internally so the screen still builds; we
    // additionally swallow the expected "No Firebase App" build error the
    // same way test/recipes/recipe_screen_test.dart does, since it only
    // affects which user's achievements load, not whether the screen renders.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      await tester.pumpWidget(
        testApp(AchievementsScreen(service: _FakeAchievementService())),
      );
      await tester.pump();

      // With no Firebase user available in this test host, _userId stays
      // null and the screen never leaves its loading state (pre-existing
      // behavior, unrelated to this token migration) — so the AppBar title
      // is the stable element to assert on.
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    } finally {
      FlutterError.onError = previousOnError;
    }

    for (final e in captured) {
      final msg = e.toString();
      expect(
        msg.contains('No Firebase App'),
        isTrue,
        reason: 'Unexpected exception during AchievementsScreen test: $e',
      );
    }
  });
}
