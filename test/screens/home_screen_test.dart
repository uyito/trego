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
import 'package:trego/shared/theme/trego_theme.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('renders empty hero and empty friends state', (tester) async {
    await tester.pumpWidget(_wrap(const HomeScreen()));
    expect(find.text('No plan yet'), findsOneWidget);
    expect(find.text('Invite friends to see their runs'), findsOneWidget);
  });

  testWidgets('shows stat tiles section header when metrics have data',
      (tester) async {
    final api = _FakeMetricsApi()..next = _snapshotWithRuns(totalRuns: 3);
    final mp = MetricsProvider(client: api);
    await mp.refresh();

    await tester.pumpWidget(_wrap(const HomeScreen(), metrics: mp));
    await tester.pump();
    expect(find.text('THIS WEEK'), findsOneWidget);
  });
}
