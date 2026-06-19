import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/widgets/goal_progress_card.dart';
import 'package:trego/shared/theme/trego_theme.dart';

WeeklyMetrics _wk({double km = 10.0, int runs = 2}) => WeeklyMetrics(
      isoYearWeek: '2026-W20',
      weekStart: DateTime.parse('2026-05-11T00:00:00Z'),
      weekEnd: DateTime.parse('2026-05-17T23:59:59Z'),
      totalKm: km,
      totalRuns: runs,
      totalTime: const Duration(hours: 1),
      avgPacePerKm: const Duration(minutes: 6),
      longestKm: 5.0,
      streakDays: 1,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: TregoTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('shows Set goal prompt when no goal', (tester) async {
    await tester.pumpWidget(_wrap(GoalProgressCard(
      thisWeek: _wk(),
      goal: null,
    )));

    expect(find.text('Set goal'), findsOneWidget);
    expect(find.textContaining('Set a target'), findsOneWidget);
  });

  testWidgets('shows empty prompt for an all-null goal', (tester) async {
    await tester.pumpWidget(_wrap(GoalProgressCard(
      thisWeek: _wk(),
      goal: const WeeklyGoal(),
    )));
    expect(find.text('Set goal'), findsOneWidget);
  });

  testWidgets('renders partial progress with X of Y line', (tester) async {
    await tester.pumpWidget(_wrap(GoalProgressCard(
      thisWeek: _wk(km: 10),
      goal: const WeeklyGoal(targetKm: 25),
    )));

    expect(find.text('Distance'), findsOneWidget);
    expect(find.textContaining('10.0 of 25 km'), findsOneWidget);
    // Not met → no overall checkmark.
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('shows checkmark when all targets met', (tester) async {
    await tester.pumpWidget(_wrap(GoalProgressCard(
      thisWeek: _wk(km: 30, runs: 5),
      goal: const WeeklyGoal(targetKm: 25, targetRuns: 4),
    )));

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Runs'), findsOneWidget);
  });

  testWidgets('renders only the runs bar when only runs target set', (tester) async {
    await tester.pumpWidget(_wrap(GoalProgressCard(
      thisWeek: _wk(runs: 2),
      goal: const WeeklyGoal(targetRuns: 4),
    )));

    expect(find.text('Runs'), findsOneWidget);
    expect(find.text('Distance'), findsNothing);
    expect(find.textContaining('2 of 4 runs'), findsOneWidget);
  });
}
