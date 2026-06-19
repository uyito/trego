import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/widgets/recent_pr_card.dart';
import 'package:trego/shared/theme/trego_theme.dart';

PrEntry _pr({
  String runId = 'r1',
  double distanceKm = 5.0,
  required DateTime at,
  Duration? duration,
}) =>
    PrEntry(
      runId: runId,
      distanceKm: distanceKm,
      runStartTime: at,
      duration: duration,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: TregoTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  final now = DateTime.parse('2026-05-19T12:00:00Z');

  testWidgets('renders card when a recent PR exists', (tester) async {
    final prs = Prs(
      fastest1k: null,
      fastest5k: _pr(
        at: DateTime.parse('2026-05-16T08:00:00Z'),
        duration: const Duration(minutes: 24, seconds: 32),
      ),
      fastest10k: null,
      longestDistance: null,
      longestDuration: null,
    );
    await tester.pumpWidget(_wrap(RecentPrCard(prs: prs, now: now)));

    expect(find.textContaining('5k'), findsOneWidget);
    expect(find.textContaining('24:32'), findsOneWidget);
    expect(find.textContaining('3 days ago'), findsOneWidget);
  });

  testWidgets('renders SizedBox.shrink when prs is null', (tester) async {
    await tester.pumpWidget(_wrap(RecentPrCard(prs: null, now: now)));
    expect(find.byType(Card), findsNothing);
    expect(find.textContaining('PR'), findsNothing);
  });

  testWidgets('renders SizedBox.shrink when all PRs are stale', (tester) async {
    final prs = Prs(
      fastest1k: null,
      fastest5k: _pr(
        at: DateTime.parse('2026-05-01T08:00:00Z'),  // 18 days ago
        duration: const Duration(minutes: 24, seconds: 32),
      ),
      fastest10k: null,
      longestDistance: null,
      longestDuration: null,
    );
    await tester.pumpWidget(_wrap(RecentPrCard(prs: prs, now: now)));
    expect(find.textContaining('PR'), findsNothing);
  });

  testWidgets('labels longestDistance as "Longest run"', (tester) async {
    final prs = Prs(
      fastest1k: null,
      fastest5k: null,
      fastest10k: null,
      longestDistance: _pr(
        runId: 'r1',
        distanceKm: 12.1,
        at: DateTime.parse('2026-05-18T08:00:00Z'),
      ),
      longestDuration: null,
    );
    await tester.pumpWidget(_wrap(RecentPrCard(prs: prs, now: now)));
    expect(find.textContaining('Longest run'), findsOneWidget);
    expect(find.textContaining('12.1'), findsOneWidget);
  });
}
