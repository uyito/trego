import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/tracker/weekly_summary_screen.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('WeeklySummaryScreen builds and shows the loading state',
      (tester) async {
    // WeeklySummaryScreen reads AuthService().currentUser?.uid in initState.
    // Firebase isn't initialized in this test host, so that access is
    // expected to throw; the widget catches it internally (mirroring the
    // guard used elsewhere, e.g. WorkoutPlanScreen) and treats it as
    // signed-out. With no user id, _loadWeeklyData no-ops and _isLoading
    // never flips to false, so the screen stays on its loading spinner —
    // a real, reachable app state (no Firebase user) rather than a
    // workaround, and a stable element to assert on.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      await tester.pumpWidget(testApp(const WeeklySummaryScreen()));
      await tester.pump();

      expect(find.byType(WeeklySummaryScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Weekly Summary'), findsOneWidget);
    } finally {
      FlutterError.onError = previousOnError;
    }

    for (final e in captured) {
      final msg = e.toString();
      expect(
        msg.contains('No Firebase App'),
        isTrue,
        reason: 'Unexpected exception during WeeklySummaryScreen test: $e',
      );
    }
  });
}
