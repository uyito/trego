import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/tracker/weekly_recap_widget.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('WeeklyRecapWidget builds and shows the empty state',
      (tester) async {
    // RunService.getWeeklyStats() catches internally when Firebase isn't
    // initialized in this test host (AuthService() throws, caught inside
    // getWeeklyStats) and resolves with a zeroed RunStats. That drives
    // WeeklyRecapWidget to its "no runs this week" empty state — a real,
    // reachable app state rather than a workaround, and a stable element
    // to assert on.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      await tester.pumpWidget(testApp(const WeeklyRecapWidget()));
      await tester.pump();
      await tester.pump();

      expect(find.byType(WeeklyRecapWidget), findsOneWidget);
      expect(find.text('Weekly Recap'), findsOneWidget);
      expect(
        find.text('No runs this week yet. Start your first run!'),
        findsOneWidget,
      );

      // RunService's singleton constructor schedules a Future.delayed(500ms)
      // health-init call. Flush it so no Timer is left pending when the
      // test ends (flutter_test asserts on that).
      await tester.pump(const Duration(milliseconds: 600));
    } finally {
      FlutterError.onError = previousOnError;
    }

    for (final e in captured) {
      final msg = e.toString();
      expect(
        msg.contains('No Firebase App'),
        isTrue,
        reason: 'Unexpected exception during WeeklyRecapWidget test: $e',
      );
    }
  });
}
