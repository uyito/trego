import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/analytics/advanced_analytics_dashboard.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('AdvancedAnalyticsDashboard builds and shows the sign-in fallback',
      (tester) async {
    // AdvancedAnalyticsDashboard reads FirebaseAuth.instance.currentUser in
    // initState (via _loadAnalytics) and in build(). Firebase isn't
    // initialized in this test host, so that access is expected to throw;
    // the widget catches it internally (see _safeCurrentUser) and treats it
    // as signed-out, which is a real, reachable app state (no Firebase user)
    // rather than a workaround. That renders the "please sign in" Scaffold,
    // which is what we assert on as a stable element.
    await tester.pumpWidget(testApp(const AdvancedAnalyticsDashboard()));
    await tester.pump();

    expect(find.text('Please sign in to view analytics'), findsOneWidget);
  });
}
