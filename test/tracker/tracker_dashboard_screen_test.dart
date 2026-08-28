import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/tracker/tracker_dashboard_screen.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('TrackerDashboardScreen builds and shows the loading state',
      (tester) async {
    // TrackerDashboardScreen reads AuthService().currentUser?.uid in
    // initState. Firebase isn't initialized in this test host, so that
    // access is expected to throw; the widget catches it internally
    // (mirroring the _safeCurrentUser guard used elsewhere) and treats it
    // as signed-out. With no user id, _loadTodayData/_loadUserTDEE/
    // _loadWorkoutStreak all no-op and _isLoading never flips to false, so
    // the screen stays on its loading spinner — a real, reachable app
    // state (no Firebase user) rather than a workaround, and a stable
    // element to assert on.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      await tester.pumpWidget(testApp(const TrackerDashboardScreen()));
      await tester.pump();

      expect(find.byType(TrackerDashboardScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

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
        reason: 'Unexpected exception during TrackerDashboardScreen test: $e',
      );
    }
  });
}
