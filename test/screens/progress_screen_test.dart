import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/screens/progress_screen.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('ProgressScreen shows Run History and Analytics tabs',
      (tester) async {
    // TrackerDashboardScreen and AdvancedAnalyticsDashboard both touch
    // Firebase in initState; Firebase isn't initialized in this test host.
    // We swallow the expected "No Firebase App" build errors the same way
    // test/nutrition/nutrition_hub_test.dart does, since it only affects the
    // embedded tab content, not the ProgressScreen shell or tab bar itself.
    final captured = <Object>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) => captured.add(details.exception);

    try {
      await tester.pumpWidget(testApp(const ProgressScreen()));
      await tester.pump();
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Run History'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);

      // TrackerDashboardScreen's Run History tab now builds successfully
      // (it no longer crashes in initState), which reaches RunService's
      // singleton constructor. That constructor schedules a
      // Future.delayed(500ms) health-init call; flush it so no Timer is
      // left pending when the test ends (flutter_test asserts on that).
      await tester.pump(const Duration(milliseconds: 600));
    } finally {
      FlutterError.onError = previousOnError;
    }

    for (final e in captured) {
      final msg = e.toString();
      expect(
        msg.contains('No Firebase App'),
        isTrue,
        reason: 'Unexpected exception during ProgressScreen test: $e',
      );
    }
  });
}
