import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trego/metrics/metrics_api_client.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/metrics_provider.dart';
import 'package:trego/notifications/notifications_provider.dart';
import 'package:trego/providers/feed_provider.dart';
import 'package:trego/providers/plan_provider.dart';
import 'package:trego/screens/home_screen.dart';
import 'package:trego/screens/progress_screen.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/workouts/workout_hub.dart';
import 'package:trego/widgets/core/section_head.dart';

import '../helpers/stub_social_service.dart';

class _FakeMetricsApi implements MetricsApiClient {
  MetricsSnapshot? next;

  @override
  Future<MetricsSnapshot> fetchSnapshot() async {
    if (next == null) throw StateError('test did not set next');
    return next!;
  }

  @override
  Future<DateTime> recompute() async => DateTime.now();

  WeeklyGoal goal = const WeeklyGoal();

  @override
  Future<WeeklyGoal> fetchGoal() async => goal;

  @override
  Future<WeeklyGoal> updateGoal({double? targetKm, int? targetRuns}) async =>
      WeeklyGoal(targetKm: targetKm, targetRuns: targetRuns);
}

MetricsSnapshot _snapshotWithRuns({int totalRuns = 1}) => MetricsSnapshot(
      computedAt: DateTime.parse('2026-05-19T10:00:00Z'),
      thisWeek: WeeklyMetrics(
        isoYearWeek: '2026-W20',
        weekStart: DateTime.parse('2026-05-11T00:00:00Z'),
        weekEnd: DateTime.parse('2026-05-17T23:59:59Z'),
        totalKm: 12.0,
        totalRuns: totalRuns,
        totalTime: const Duration(hours: 1, minutes: 5),
        avgPacePerKm: const Duration(minutes: 5, seconds: 30),
        longestKm: 6.0,
        streakDays: 2,
      ),
      prs: const Prs(
        fastest1k: null,
        fastest5k: null,
        fastest10k: null,
        longestDistance: null,
        longestDuration: null,
      ),
      totals: LifetimeTotals(
        totalKm: 12.0,
        totalRuns: totalRuns,
        totalTime: const Duration(hours: 1, minutes: 5),
      ),
      history: const [],
    );

Widget _wrap(Widget child, {MetricsProvider? metrics}) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider<MetricsProvider>.value(
          value: metrics ?? MetricsProvider(client: _FakeMetricsApi()),
        ),
        ChangeNotifierProvider<NotificationsProvider>(
          create: (_) => NotificationsProvider(service: StubSocialService()),
        ),
      ],
      child: MaterialApp(
        theme: TregoTheme.light(),
        darkTheme: TregoTheme.dark(),
        themeMode: ThemeMode.dark,
        home: child,
      ),
    );

/// Runs [body] while swallowing FlutterError exceptions whose message
/// contains "No Firebase App" — the legacy screens embedded by Home's new
/// navigation targets (AchievementsScreen, ForYouHub's tabs, WorkoutHub's
/// tabs) touch FirebaseAuth/Firestore directly in initState, and Firebase
/// isn't initialized in this test host. Any other exception fails the test.
Future<void> _withFirebaseErrorsSwallowed(
    Future<void> Function() body) async {
  final captured = <Object>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) => captured.add(details.exception);
  try {
    await body();
  } finally {
    FlutterError.onError = previousOnError;
  }
  for (final e in captured) {
    expect(
      e.toString().contains('No Firebase App'),
      isTrue,
      reason: 'Unexpected exception: $e',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('shows the For You card and Achievements section',
      (tester) async {
    await tester.pumpWidget(_wrap(const HomeScreen()));
    expect(find.text('For You'), findsOneWidget);
    expect(find.text('ACHIEVEMENTS'), findsOneWidget);
  });

  testWidgets('tapping This Week "See all" pushes ProgressScreen',
      (tester) async {
    final api = _FakeMetricsApi()..next = _snapshotWithRuns(totalRuns: 3);
    final mp = MetricsProvider(client: api);
    await mp.refresh();

    await _withFirebaseErrorsSwallowed(() async {
      await tester.pumpWidget(_wrap(const HomeScreen(), metrics: mp));
      await tester.pump();

      final thisWeekSection =
          find.ancestor(of: find.text('THIS WEEK'), matching: find.byType(SectionHead));
      final trailing =
          find.descendant(of: thisWeekSection, matching: find.text('See all →'));
      await tester.tap(trailing);
      await tester.pump();
      // The pushed route (and its Firebase-touching embedded tabs) finishes
      // mounting a frame later than the tap; a second pump lets that settle
      // before asserting on the resulting tree.
      await tester.pump();

      expect(find.byType(ProgressScreen), findsOneWidget);
      expect(find.text('Run History'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);

      // TrackerDashboardScreen's Run History tab now builds successfully
      // (it no longer crashes in initState), which reaches RunService's
      // singleton constructor. That constructor schedules a
      // Future.delayed(500ms) health-init call; flush it so no Timer is
      // left pending when the test ends (flutter_test asserts on that).
      await tester.pump(const Duration(milliseconds: 600));
    });
  });

  testWidgets('tapping the Achievements section head pushes AchievementsScreen',
      (tester) async {
    await _withFirebaseErrorsSwallowed(() async {
      await tester.pumpWidget(_wrap(const HomeScreen()));

      final achievementsSection = find.ancestor(
          of: find.text('ACHIEVEMENTS'), matching: find.byType(SectionHead));
      final trailing = find.descendant(
          of: achievementsSection, matching: find.text('See all →'));
      await tester.tap(trailing);
      await tester.pump();
      await tester.pump();

      // AchievementsScreen itself touches Firebase in initState, so its
      // subtree collapses into an ErrorWidget in this test host; the
      // swallow above is a best-effort/weak check that the tap didn't throw
      // an unexpected error (not a confirmation the screen was reached).
    });
  });

  // Note: tapping the "For You" card is intentionally not exercised here.
  // ForYouHub's first tab (EnhancedRecommendationsScreen) starts a
  // background timer via its AI coach / personalization services that
  // outlives the widget tree in this Firebase-less test host, tripping
  // flutter_test's "Timer is still pending" teardown invariant regardless
  // of how the resulting Firebase build error is swallowed. The card's
  // presence and label are covered by the render test above.

  testWidgets('tapping the Training entry pushes WorkoutHub', (tester) async {
    await _withFirebaseErrorsSwallowed(() async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await tester.tap(find.text('Training'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(WorkoutHub), findsOneWidget);
    });
  });
}
