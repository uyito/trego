import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/widgets/weekly_progress_card.dart';
import 'package:trego/shared/theme/trego_theme.dart';

WeeklyMetrics _wk({
  double km = 23.4,
  int runs = 4,
  int streak = 3,
}) =>
    WeeklyMetrics(
      isoYearWeek: '2026-W20',
      weekStart: DateTime.parse('2026-05-11T00:00:00Z'),
      weekEnd: DateTime.parse('2026-05-17T23:59:59Z'),
      totalKm: km,
      totalRuns: runs,
      totalTime: const Duration(hours: 1, minutes: 30),
      avgPacePerKm: const Duration(minutes: 5, seconds: 8),
      longestKm: 8.2,
      streakDays: streak,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: TregoTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders with deltas when previousWeek is present', (tester) async {
    await tester.pumpWidget(_wrap(WeeklyProgressCard(
      thisWeek: _wk(km: 23.4, runs: 4, streak: 3),
      previousWeek: _wk(km: 19.3, runs: 3, streak: 2),
    )));

    expect(find.textContaining('This week so far'), findsOneWidget);
    expect(find.textContaining('23.4'), findsOneWidget);
    expect(find.textContaining('+4.1'), findsOneWidget);
    expect(find.textContaining('+1'), findsOneWidget);
    expect(find.textContaining('🔥'), findsOneWidget);
  });

  testWidgets('renders absolute values with no arrows when previousWeek is null',
      (tester) async {
    await tester.pumpWidget(_wrap(WeeklyProgressCard(
      thisWeek: _wk(km: 5.0, runs: 1, streak: 1),
      previousWeek: null,
    )));

    expect(find.textContaining('5.0'), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
    expect(find.textContaining('🔥'), findsNothing);
  });

  testWidgets('renders down arrow with negative delta', (tester) async {
    await tester.pumpWidget(_wrap(WeeklyProgressCard(
      thisWeek: _wk(km: 5.0, runs: 1, streak: 1),
      previousWeek: _wk(km: 12.0, runs: 3, streak: 5),
    )));

    expect(find.textContaining('-7.0'), findsOneWidget);
    expect(find.textContaining('-2'), findsOneWidget);
  });

  testWidgets('no fire emoji when streak < 3', (tester) async {
    await tester.pumpWidget(_wrap(WeeklyProgressCard(
      thisWeek: _wk(streak: 2),
      previousWeek: _wk(streak: 1),
    )));
    expect(find.textContaining('🔥'), findsNothing);
  });
}
