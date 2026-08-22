import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trego/metrics/metrics_api_client.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/metrics_provider.dart';
import 'package:trego/navigation/app_shell.dart';
import 'package:trego/notifications/notifications_provider.dart';
import 'package:trego/social/social_service.dart';
import 'package:trego/providers/app_state_provider.dart';
import 'package:trego/providers/feed_provider.dart';
import 'package:trego/providers/plan_provider.dart';
import 'package:trego/tracker/pending_saves_flusher.dart';
import 'package:trego/tracker/record_preferences.dart';
import 'package:trego/tracker/run_model.dart';

import '../helpers/stub_social_service.dart';
import '../helpers/test_app.dart';

class _NoOpRunSaver implements RunSaver {
  @override
  Future<void> save(Run run) async {}
}

class _FakeMetricsApi implements MetricsApiClient {
  MetricsSnapshot? next;

  @override
  Future<MetricsSnapshot> fetchSnapshot() async {
    if (next == null) throw StateError('test did not set next');
    return next!;
  }

  @override
  Future<DateTime> recompute() async => DateTime.now();

  @override
  Future<WeeklyGoal> fetchGoal() async => const WeeklyGoal();

  @override
  Future<WeeklyGoal> updateGoal({double? targetKm, int? targetRuns}) async =>
      const WeeklyGoal();
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

Widget _wrap(Widget child, {MetricsProvider? metrics}) =>
    ChangeNotifierProvider<AppStateProvider>.value(
      value: FakeAppStateProvider(),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PlanProvider()),
          ChangeNotifierProvider(create: (_) => FeedProvider()),
          ChangeNotifierProvider(create: (_) => RecordPreferences()),
          ChangeNotifierProvider<MetricsProvider>.value(
            value: metrics ?? MetricsProvider(client: _FakeMetricsApi()),
          ),
          ChangeNotifierProvider<NotificationsProvider>(
            create: (_) => NotificationsProvider(service: StubSocialService()),
          ),
          Provider<SocialService>(create: (_) => StubSocialService()),
          Provider<PendingSavesFlusher>(
            create: (_) => PendingSavesFlusher(saver: _NoOpRunSaver()),
          ),
        ],
        child: testApp(child),
      ),
    );

/// AppShell's IndexedStack keeps every tab mounted (that's the point of
/// IndexedStack — state survives tab switches), which means NutritionHub's
/// Recipes tab (RecipeScreen -> RecipeService -> FirebaseFirestore.instance)
/// builds eagerly on every AppShell pump, even while Home is selected.
/// Firebase isn't initialized in this test host, so that build throws the
/// same expected "No Firebase App" error test/widget_test.dart already
/// documents and swallows. We do the same here, scoped to each `body`.
Future<void> _runIgnoringFirebaseErrors(
  Future<void> Function() body,
) async {
  final captured = <Object>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) => captured.add(details.exception);

  try {
    await body();
  } finally {
    FlutterError.onError = previousOnError;
  }

  for (final e in captured) {
    final msg = e.toString();
    expect(
      msg.contains('No Firebase App'),
      isTrue,
      reason: 'Unexpected exception during app_shell test: $e',
    );
  }
}

void main() {
  initTestEnv();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shell starts on Home tab', (tester) async {
    await _runIgnoringFirebaseErrors(() async {
      final api = _FakeMetricsApi()..next = _snapshotWithRuns(totalRuns: 3);
      final mp = MetricsProvider(client: api);
      await mp.refresh();

      await tester.pumpWidget(_wrap(const AppShell(), metrics: mp));
      await tester.pump();
      expect(find.text('THIS WEEK'), findsOneWidget);
    });
  });

  testWidgets('bottom nav shows Home, Nutrition, Feed, You (no Plan)', (tester) async {
    await _runIgnoringFirebaseErrors(() async {
      await tester.pumpWidget(_wrap(const AppShell()));
      await tester.pump();
      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('Plan'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.byKey(const Key('shell-record-button')), findsOneWidget);
    });
  });

  testWidgets('tapping Nutrition tab shows the Nutrition hub tabs', (tester) async {
    await _runIgnoringFirebaseErrors(() async {
      await tester.pumpWidget(_wrap(const AppShell()));
      await tester.tap(find.text('Nutrition'));
      await tester.pumpAndSettle();
      expect(find.text('Recipes'), findsWidgets);
      expect(find.text('Pantry'), findsWidgets);
      expect(find.text('TDEE'), findsWidgets);
    });
  });

  testWidgets('tapping You tab shows Tools row', (tester) async {
    await _runIgnoringFirebaseErrors(() async {
      await tester.pumpWidget(_wrap(const AppShell()));
      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();
      expect(find.text('TOOLS'), findsOneWidget);
    });
  });

  testWidgets('tapping center Record button opens modal', (tester) async {
    await _runIgnoringFirebaseErrors(() async {
      await tester.pumpWidget(_wrap(const AppShell()));
      await tester.tap(find.byKey(const Key('shell-record-button')));
      await tester.pumpAndSettle();
      expect(find.text('Ready'), findsOneWidget);
    });
  });
}
