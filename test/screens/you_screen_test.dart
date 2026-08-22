import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trego/metrics/metrics_api_client.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/metrics_provider.dart';
import 'package:trego/providers/app_state_provider.dart';
import 'package:trego/screens/you_screen.dart';

import '../helpers/test_app.dart';

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

MetricsSnapshot _snapshotWithRuns({int totalRuns = 3}) => MetricsSnapshot(
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
        streakDays: 4,
      ),
      prs: const Prs(
        fastest1k: null,
        fastest5k: null,
        fastest10k: null,
        longestDistance: null,
        longestDuration: null,
      ),
      totals: LifetimeTotals(
        totalKm: 42.0,
        totalRuns: totalRuns,
        totalTime: const Duration(hours: 3, minutes: 5),
      ),
      history: const [],
    );

Widget _wrap(Widget child, {MetricsProvider? metrics, Map<String, dynamic>? user}) =>
    ChangeNotifierProvider<AppStateProvider>.value(
      value: FakeAppStateProvider(
        user: user ?? {'displayName': 'Jamie Runner', 'username': 'jamie'},
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MetricsProvider>.value(
            value: metrics ?? MetricsProvider(client: _FakeMetricsApi()),
          ),
        ],
        child: testApp(child),
      ),
    );

void main() {
  initTestEnv();

  testWidgets('renders profile header with name, username, and stats', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _FakeMetricsApi()..next = _snapshotWithRuns(totalRuns: 3);
    final mp = MetricsProvider(client: api);
    await mp.refresh();

    await tester.pumpWidget(_wrap(const YouScreen(), metrics: mp));
    await tester.pump();

    expect(find.text('Jamie Runner'), findsOneWidget);
    expect(find.text('@jamie'), findsOneWidget);
  });

  testWidgets('shows Appearance, Recording, Notifications, Sign out; hides moved tools',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const YouScreen()));
    await tester.pump();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Recording'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);

    expect(find.text('Recipes'), findsNothing);
    expect(find.text('TDEE Calculator'), findsNothing);
    expect(find.text('For You'), findsNothing);
    expect(find.text('Run History'), findsNothing);
  });
}
