import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trego/metrics/metrics_api_client.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/metrics_provider.dart';
import 'package:trego/providers/feed_provider.dart';
import 'package:trego/providers/plan_provider.dart';
import 'package:trego/screens/home_screen.dart';
import 'package:trego/shared/theme/trego_theme.dart';

class _FakeMetricsApi implements MetricsApiClient {
  MetricsSnapshot? next;
  int fetchCalls = 0;
  Object? throwOnFetch;

  @override
  Future<MetricsSnapshot> fetchSnapshot() async {
    fetchCalls++;
    if (throwOnFetch != null) throw throwOnFetch!;
    if (next == null) {
      throw StateError('test did not set next');
    }
    return next!;
  }

  @override
  Future<DateTime> recompute() async => DateTime.now();
}

MetricsSnapshot _snapshot({int totalRuns = 1, double weekKm = 12.0}) =>
    MetricsSnapshot(
      computedAt: DateTime.parse('2026-05-19T10:00:00Z'),
      thisWeek: WeeklyMetrics(
        isoYearWeek: '2026-W20',
        weekStart: DateTime.parse('2026-05-11T00:00:00Z'),
        weekEnd: DateTime.parse('2026-05-17T23:59:59Z'),
        totalKm: weekKm,
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
        totalKm: weekKm,
        totalRuns: totalRuns,
        totalTime: const Duration(hours: 1, minutes: 5),
      ),
      history: const [],
    );

Widget _pump(MetricsProvider mp) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider<MetricsProvider>.value(value: mp),
      ],
      child: MaterialApp(
        theme: TregoTheme.light(),
        home: const HomeScreen(),
      ),
    );

void main() {
  testWidgets('shows metrics section when snapshot has at least 1 run', (tester) async {
    final api = _FakeMetricsApi()..next = _snapshot(totalRuns: 4, weekKm: 23.4);
    final mp = MetricsProvider(client: api);
    await mp.refresh();

    await tester.pumpWidget(_pump(mp));
    await tester.pump();

    expect(find.text('23.4'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('hides metrics section when totalRuns == 0', (tester) async {
    final api = _FakeMetricsApi()..next = _snapshot(totalRuns: 0, weekKm: 0);
    final mp = MetricsProvider(client: api);
    await mp.refresh();

    await tester.pumpWidget(_pump(mp));
    await tester.pump();

    // The "This Week" SectionHead should not appear when the section hides.
    expect(find.text('This Week'), findsNothing);
  });

  testWidgets('hides metrics section when snapshot is null + no loading', (tester) async {
    final api = _FakeMetricsApi();   // never call refresh
    final mp = MetricsProvider(client: api);

    await tester.pumpWidget(_pump(mp));
    await tester.pump();

    expect(find.text('This Week'), findsNothing);
  });

  testWidgets('pull-to-refresh triggers MetricsProvider.refresh', (tester) async {
    final api = _FakeMetricsApi()..next = _snapshot(totalRuns: 1, weekKm: 5);
    final mp = MetricsProvider(client: api);
    await mp.refresh();
    expect(api.fetchCalls, 1);

    await tester.pumpWidget(_pump(mp));
    await tester.pump();

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(api.fetchCalls, greaterThanOrEqualTo(2),
        reason: 'pull-to-refresh should force a new fetch');
  });
}
