import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/widgets/pr_hero_banner.dart';
import 'package:trego/shared/theme/trego_theme.dart';

PrEntry _pr({
  required String runId,
  double distanceKm = 5.0,
  Duration? duration,
}) =>
    PrEntry(
      runId: runId,
      distanceKm: distanceKm,
      runStartTime: DateTime.parse('2026-05-19T08:00:00Z'),
      duration: duration,
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: TregoTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders banner with delta when prior PR exists', (tester) async {
    final prs = Prs(
      fastest1k: null,
      fastest5k: _pr(runId: 'rnew', duration: const Duration(seconds: 1472)),
      fastest10k: null,
      longestDistance: null,
      longestDuration: null,
    );
    final previousPrs = Prs(
      fastest1k: null,
      fastest5k: _pr(runId: 'rold', duration: const Duration(seconds: 1490)),
      fastest10k: null,
      longestDistance: null,
      longestDuration: null,
    );

    await tester.pumpWidget(_wrap(PrHeroBanner(
      prs: prs,
      previousPrs: previousPrs,
      runId: 'rnew',
    )));

    expect(find.textContaining('New 5k PR'), findsOneWidget);
    expect(find.textContaining('24:32'), findsOneWidget);
    expect(find.textContaining('18 sec faster'), findsOneWidget);
  });

  testWidgets('renders banner without delta when previousPrs is null', (tester) async {
    final prs = Prs(
      fastest1k: null,
      fastest5k: _pr(runId: 'rnew', duration: const Duration(seconds: 1472)),
      fastest10k: null,
      longestDistance: null,
      longestDuration: null,
    );

    await tester.pumpWidget(_wrap(PrHeroBanner(
      prs: prs,
      previousPrs: null,
      runId: 'rnew',
    )));

    expect(find.textContaining('New 5k PR'), findsOneWidget);
    expect(find.textContaining('faster than'), findsNothing);
  });

  testWidgets('renders nothing when runId does not match any PR', (tester) async {
    final prs = Prs(
      fastest1k: null,
      fastest5k: _pr(runId: 'other', duration: const Duration(seconds: 1472)),
      fastest10k: null,
      longestDistance: null,
      longestDuration: null,
    );
    await tester.pumpWidget(_wrap(PrHeroBanner(
      prs: prs,
      previousPrs: null,
      runId: 'rnew',
    )));

    expect(find.textContaining('PR'), findsNothing);
  });

  testWidgets('renders nothing when runId is null', (tester) async {
    final prs = Prs(
      fastest1k: null,
      fastest5k: _pr(runId: 'rnew'),
      fastest10k: null,
      longestDistance: null,
      longestDuration: null,
    );
    await tester.pumpWidget(_wrap(PrHeroBanner(
      prs: prs,
      previousPrs: null,
      runId: null,
    )));
    expect(find.textContaining('PR'), findsNothing);
  });
}
