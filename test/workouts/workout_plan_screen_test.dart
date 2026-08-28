import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/workout_plan_screen.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('WorkoutPlanScreen builds and shows the loading state',
      (tester) async {
    // WorkoutPlanScreen reads AuthService().currentUser?.uid in initState.
    // Firebase isn't initialized in this test host, so that access is
    // expected to throw; the widget catches it internally (mirroring the
    // guard used elsewhere, e.g. TrackerDashboardScreen) and treats it as
    // signed-out. With no user id, _loadCurrentWeekWorkouts and
    // _loadWorkoutStreak both no-op and _isLoading never flips to false,
    // so the screen stays on its loading spinner — a real, reachable app
    // state (no Firebase user) rather than a workaround, and a stable
    // element to assert on.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      await tester.pumpWidget(testApp(const WorkoutPlanScreen()));
      await tester.pump();

      expect(find.byType(WorkoutPlanScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    } finally {
      FlutterError.onError = previousOnError;
    }

    for (final e in captured) {
      final msg = e.toString();
      expect(
        msg.contains('No Firebase App'),
        isTrue,
        reason: 'Unexpected exception during WorkoutPlanScreen test: $e',
      );
    }
  });
}
