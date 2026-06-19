import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/metrics_provider.dart';
import 'package:trego/screens/record/summary_screen.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/tracker/record_state.dart';
import 'package:trego/tracker/run_model.dart';
import 'package:trego/tracker/session_controller.dart';

class _FakeSession extends ChangeNotifier implements SessionController {
  final Run _run;
  _FakeSession(this._run);
  @override Run? get lastRun => _run;
  @override RecordState get state => RecordState.summary;
  @override bool get offlineQueued => false;
  @override void exitSummary() {}
  @override noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

MetricsSnapshot _snapshot({
  required PrEntry? fastest5k,
  WeeklyMetrics? history,
}) =>
    MetricsSnapshot(
      computedAt: DateTime.parse('2026-05-19T10:00:00Z'),
      thisWeek: WeeklyMetrics(
        isoYearWeek: '2026-W20',
        weekStart: DateTime.parse('2026-05-11T00:00:00Z'),
        weekEnd: DateTime.parse('2026-05-17T23:59:59Z'),
        totalKm: 23.4,
        totalRuns: 4,
        totalTime: const Duration(hours: 1, minutes: 30),
        avgPacePerKm: const Duration(minutes: 5, seconds: 8),
        longestKm: 8.2,
        streakDays: 3,
      ),
      prs: Prs(
        fastest1k: null,
        fastest5k: fastest5k,
        fastest10k: null,
        longestDistance: null,
        longestDuration: null,
      ),
      totals: const LifetimeTotals(
        totalKm: 23.4,
        totalRuns: 4,
        totalTime: Duration(hours: 1, minutes: 30),
      ),
      history: history == null ? const [] : [history],
    );

Run _run({String id = 'r-new'}) => Run(
      id: id,
      userId: 'u',
      startTime: DateTime.parse('2026-05-19T08:00:00Z'),
      endTime: DateTime.parse('2026-05-19T08:24:32Z'),
      duration: const Duration(seconds: 1472),
      distance: 5.02,
      averagePace: 4.9,
      route: const [],
    );

/// Test-only provider that bypasses the API and exposes a pre-set snapshot
/// + previousSnapshot. Implements the same surface MetricsProvider does.
class _PreloadedProvider extends ChangeNotifier implements MetricsProvider {
  final MetricsSnapshot? _snap;
  final MetricsSnapshot? _prev;
  _PreloadedProvider({MetricsSnapshot? snapshot, MetricsSnapshot? previous})
      : _snap = snapshot,
        _prev = previous;
  @override MetricsSnapshot? get snapshot => _snap;
  @override MetricsSnapshot? get previousSnapshot => _prev;
  @override bool get hasData => _snap != null;
  @override bool get loading => false;
  @override Object? get lastError => null;
  @override Future<void> refresh({Duration maxAge = const Duration(minutes: 5)}) async {}
  @override Future<void> recomputeAndRefresh() async {}
  @override void clear() {}
  @override noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _pump({
  required Run run,
  required MetricsSnapshot? snapshot,
  required MetricsSnapshot? previous,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MetricsProvider>.value(
        value: _PreloadedProvider(snapshot: snapshot, previous: previous),
      ),
      ChangeNotifierProvider<SessionController>.value(value: _FakeSession(run)),
    ],
    child: MaterialApp(
      theme: TregoTheme.light(),
      home: const SummaryScreen(),
    ),
  );
}

/// Set a tall viewport so both the top-most PR banner and the bottom-most
/// weekly card lay out in a single pump. CustomScrollView culls slivers
/// outside the cache extent otherwise.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400 * 3, 2400 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('PR run with prior snapshot shows banner with delta', (tester) async {
    final snap = _snapshot(
      fastest5k: PrEntry(
        runId: 'r-new',
        distanceKm: 5.0,
        runStartTime: DateTime.parse('2026-05-19T08:00:00Z'),
        duration: const Duration(seconds: 1472),
      ),
    );
    final prevSnap = _snapshot(
      fastest5k: PrEntry(
        runId: 'r-old',
        distanceKm: 5.0,
        runStartTime: DateTime.parse('2026-05-12T08:00:00Z'),
        duration: const Duration(seconds: 1490),
      ),
    );
    _useTallViewport(tester);
    await tester.pumpWidget(_pump(
      run: _run(id: 'r-new'),
      snapshot: snap,
      previous: prevSnap,
    ));
    await tester.pump();

    expect(find.textContaining('New 5k PR'), findsOneWidget);
    expect(find.textContaining('18 sec faster'), findsOneWidget);
    expect(find.textContaining('This week so far'), findsOneWidget);
  });

  testWidgets('PR run without prior snapshot shows banner with no delta',
      (tester) async {
    final snap = _snapshot(
      fastest5k: PrEntry(
        runId: 'r-new',
        distanceKm: 5.0,
        runStartTime: DateTime.parse('2026-05-19T08:00:00Z'),
        duration: const Duration(seconds: 1472),
      ),
    );
    _useTallViewport(tester);
    await tester.pumpWidget(_pump(
      run: _run(id: 'r-new'),
      snapshot: snap,
      previous: null,
    ));
    await tester.pump();

    expect(find.textContaining('New 5k PR'), findsOneWidget);
    expect(find.textContaining('faster than'), findsNothing);
  });

  testWidgets('non-PR run shows no banner but still shows weekly card',
      (tester) async {
    final snap = _snapshot(
      fastest5k: PrEntry(
        runId: 'r-someone-else',
        distanceKm: 5.0,
        runStartTime: DateTime.parse('2026-05-12T08:00:00Z'),
        duration: const Duration(seconds: 1490),
      ),
    );
    _useTallViewport(tester);
    await tester.pumpWidget(_pump(
      run: _run(id: 'r-new'),
      snapshot: snap,
      previous: null,
    ));
    await tester.pump();

    expect(find.textContaining('New'), findsNothing);
    expect(find.textContaining('PR'), findsNothing);
    expect(find.textContaining('This week so far'), findsOneWidget);
  });

  testWidgets('null snapshot hides both banner and card', (tester) async {
    _useTallViewport(tester);
    await tester.pumpWidget(_pump(
      run: _run(id: 'r-new'),
      snapshot: null,
      previous: null,
    ));
    await tester.pump();

    expect(find.textContaining('PR'), findsNothing);
    expect(find.textContaining('This week so far'), findsNothing);
  });
}
