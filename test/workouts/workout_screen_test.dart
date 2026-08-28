import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/workout_screen.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('WorkoutScreen builds and shows the signed-out message',
      (tester) async {
    // WorkoutScreen reads AuthService().currentUser?.uid in initState.
    // Firebase isn't initialized in this test host, so that access is
    // expected to throw; the widget catches it internally (mirroring the
    // guard used elsewhere, e.g. TrackerDashboardScreen) and treats it as
    // signed-out. With no user id, the screen renders the "please sign in"
    // message instead of the Firestore StreamBuilder — a real, reachable
    // app state (no Firebase user) and a stable element to assert on.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      await tester.pumpWidget(testApp(const WorkoutScreen()));
      await tester.pump();

      expect(find.byType(WorkoutScreen), findsOneWidget);
      expect(find.text('Please sign in to view workout history'), findsOneWidget);
    } finally {
      FlutterError.onError = previousOnError;
    }

    for (final e in captured) {
      final msg = e.toString();
      expect(
        msg.contains('No Firebase App'),
        isTrue,
        reason: 'Unexpected exception during WorkoutScreen test: $e',
      );
    }
  });
}
