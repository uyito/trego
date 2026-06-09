import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/widgets/weekly_stat_strip.dart';
import 'package:trego/shared/theme/trego_theme.dart';

WeeklyMetrics _wk({
  double km = 23.4,
  int runs = 4,
  Duration time = const Duration(hours: 1, minutes: 30, seconds: 18),
  Duration pace = const Duration(minutes: 5, seconds: 8),
}) =>
    WeeklyMetrics(
      isoYearWeek: '2026-W18',
      weekStart: DateTime.parse('2026-04-27T00:00:00Z'),
      weekEnd: DateTime.parse('2026-05-03T23:59:59Z'),
      totalKm: km,
      totalRuns: runs,
      totalTime: time,
      avgPacePerKm: pace,
      longestKm: 8.2,
      streakDays: 3,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: TregoTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders 4 tiles with km, runs, time, avg pace', (tester) async {
    await tester.pumpWidget(_wrap(WeeklyStatStrip(metrics: _wk())));

    expect(find.text('23.4'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('1:30:18'), findsOneWidget);
    expect(find.text('5:08'), findsOneWidget);
    expect(find.text('KM'), findsOneWidget);
    expect(find.text('RUNS'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('/KM'), findsOneWidget);
  });

  testWidgets('renders sub-hour time as M:SS', (tester) async {
    final m = _wk(time: const Duration(minutes: 42, seconds: 7));
    await tester.pumpWidget(_wrap(WeeklyStatStrip(metrics: m)));
    expect(find.text('42:07'), findsOneWidget);
  });

  testWidgets('renders dashes when zero', (tester) async {
    final m = _wk(km: 0, runs: 0, time: Duration.zero, pace: Duration.zero);
    await tester.pumpWidget(_wrap(WeeklyStatStrip(metrics: m)));
    expect(find.text('—'), findsNWidgets(4));
  });
}
