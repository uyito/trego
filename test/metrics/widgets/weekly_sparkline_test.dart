import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/widgets/weekly_sparkline.dart';
import 'package:trego/shared/theme/trego_theme.dart';

WeeklyMetrics _wk(double km, {String iso = '2026-W01'}) => WeeklyMetrics(
      isoYearWeek: iso,
      weekStart: DateTime.parse('2026-01-01T00:00:00Z'),
      weekEnd: DateTime.parse('2026-01-07T23:59:59Z'),
      totalKm: km,
      totalRuns: km > 0 ? 1 : 0,
      totalTime: Duration(minutes: (km * 6).round()),
      avgPacePerKm: const Duration(minutes: 6),
      longestKm: km,
      streakDays: 0,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: TregoTheme.light(),
      home: Scaffold(body: SizedBox(height: 100, child: child)),
    );

void main() {
  testWidgets('renders one bar per history entry', (tester) async {
    final history = List<WeeklyMetrics>.generate(12, (i) => _wk(i + 1.0));
    await tester.pumpWidget(_wrap(WeeklySparkline(history: history)));
    expect(find.byKey(const ValueKey('sparkline-bar-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('sparkline-bar-11')), findsOneWidget);
  });

  testWidgets('tallest bar normalised to full height', (tester) async {
    final history = [_wk(1), _wk(2), _wk(10)];
    await tester.pumpWidget(_wrap(WeeklySparkline(history: history)));

    final tallest = tester.widget<SparkBar>(find.byKey(const ValueKey('sparkline-bar-2')));
    expect(tallest.heightRatio, 1.0);
    final shortest = tester.widget<SparkBar>(find.byKey(const ValueKey('sparkline-bar-0')));
    expect(shortest.heightRatio, closeTo(0.1, 1e-9));
  });

  testWidgets('zero-km week renders as presence stripe (isPresenceOnly = true)',
      (tester) async {
    final history = [_wk(5), _wk(0), _wk(5)];
    await tester.pumpWidget(_wrap(WeeklySparkline(history: history)));
    final zero = tester.widget<SparkBar>(find.byKey(const ValueKey('sparkline-bar-1')));
    expect(zero.isPresenceOnly, isTrue);
  });

  testWidgets('empty history renders no bars', (tester) async {
    await tester.pumpWidget(_wrap(const WeeklySparkline(history: [])));
    expect(find.byType(SparkBar), findsNothing);
  });
}
