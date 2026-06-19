import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trego/metrics/metrics_api_client.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/metrics_provider.dart';
import 'package:trego/screens/record/record_flow.dart';
import 'package:trego/tracker/record_state.dart';

class _FakeMetricsApi implements MetricsApiClient {
  int recomputeCalls = 0;
  int fetchCalls = 0;

  @override
  Future<DateTime> recompute() async {
    recomputeCalls++;
    return DateTime.now();
  }

  @override
  Future<MetricsSnapshot> fetchSnapshot() async {
    fetchCalls++;
    // Return a minimal valid snapshot so refresh() inside recomputeAndRefresh
    // succeeds and we can assert that recompute fired without exceptions.
    return MetricsSnapshot(
      computedAt: DateTime.now(),
      thisWeek: WeeklyMetrics(
        isoYearWeek: '2026-W17',
        weekStart: DateTime.parse('2026-04-20T00:00:00Z'),
        weekEnd: DateTime.parse('2026-04-26T23:59:59Z'),
        totalKm: 0,
        totalRuns: 0,
        totalTime: Duration.zero,
        avgPacePerKm: Duration.zero,
        longestKm: 0,
        streakDays: 0,
      ),
      prs: const Prs(
        fastest1k: null,
        fastest5k: null,
        fastest10k: null,
        longestDistance: null,
        longestDuration: null,
      ),
      totals: const LifetimeTotals(
        totalKm: 0,
        totalRuns: 0,
        totalTime: Duration.zero,
      ),
      history: const [],
    );
  }
}

/// Minimal SessionController-shaped notifier the hook listens to.
class _FakeSessionState extends ChangeNotifier {
  RecordState _state = RecordState.preStart;
  RecordState get state => _state;
  void transitionTo(RecordState s) {
    _state = s;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'RecordFlowSummaryHook triggers MetricsProvider.recomputeAndRefresh on summary transition',
    (tester) async {
      final api = _FakeMetricsApi();
      final metricsProvider = MetricsProvider(client: api);
      final sessionState = _FakeSessionState();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MetricsProvider>.value(value: metricsProvider),
            ChangeNotifierProvider<_FakeSessionState>.value(value: sessionState),
          ],
          child: MaterialApp(
            home: RecordFlowSummaryHook<_FakeSessionState>(
              stateOf: (s) => s.state,
            ),
          ),
        ),
      );

      expect(api.recomputeCalls, 0);

      sessionState.transitionTo(RecordState.summary);
      await tester.pump();
      // Wait for post-frame callback + the recompute future to settle.
      await tester.pumpAndSettle();

      expect(api.recomputeCalls, 1,
          reason: 'summary transition should trigger recompute exactly once');
    },
  );
}
