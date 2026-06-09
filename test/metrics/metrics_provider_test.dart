import 'package:flutter_test/flutter_test.dart';
import 'package:trego/metrics/metrics_api_client.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/metrics/metrics_provider.dart';

class _FakeMetricsApi implements MetricsApiClient {
  MetricsSnapshot? nextSnapshot;
  Object? throwOnFetch;
  Object? throwOnRecompute;
  int fetchCallCount = 0;
  int recomputeCallCount = 0;
  DateTime nextRecomputedAt = DateTime.parse('2026-04-27T18:34:12Z');

  @override
  Future<MetricsSnapshot> fetchSnapshot() async {
    fetchCallCount++;
    if (throwOnFetch != null) throw throwOnFetch!;
    return nextSnapshot!;
  }

  @override
  Future<DateTime> recompute() async {
    recomputeCallCount++;
    if (throwOnRecompute != null) throw throwOnRecompute!;
    return nextRecomputedAt;
  }
}

MetricsSnapshot _snapshotFixture({DateTime? computedAt}) => MetricsSnapshot(
      computedAt: computedAt ?? DateTime.now(),
      thisWeek: WeeklyMetrics(
        isoYearWeek: '2026-W17',
        weekStart: DateTime.parse('2026-04-20T00:00:00Z'),
        weekEnd: DateTime.parse('2026-04-26T23:59:59Z'),
        totalKm: 5.0,
        totalRuns: 1,
        totalTime: const Duration(minutes: 30),
        avgPacePerKm: const Duration(minutes: 6),
        longestKm: 5.0,
        streakDays: 1,
      ),
      prs: const Prs(fastest1k: null, fastest5k: null, fastest10k: null,
                     longestDistance: null, longestDuration: null),
      totals: const LifetimeTotals(totalKm: 5.0, totalRuns: 1, totalTime: Duration(minutes: 30)),
      history: const [],
    );

void main() {
  test('refresh fetches when snapshot is null', () async {
    final api = _FakeMetricsApi()..nextSnapshot = _snapshotFixture();
    final p = MetricsProvider(client: api);

    await p.refresh();

    expect(api.fetchCallCount, 1);
    expect(p.snapshot, isNotNull);
    expect(p.hasData, isTrue);
  });

  test('refresh skips when cache is fresh (< maxAge)', () async {
    final api = _FakeMetricsApi()..nextSnapshot = _snapshotFixture();
    final p = MetricsProvider(client: api);

    await p.refresh();
    await p.refresh(maxAge: const Duration(minutes: 5));

    expect(api.fetchCallCount, 1, reason: 'second refresh should hit cache');
  });

  test('refresh re-fetches when cache stale', () async {
    final api = _FakeMetricsApi()..nextSnapshot = _snapshotFixture();
    final p = MetricsProvider(client: api);

    await p.refresh();
    await p.refresh(maxAge: Duration.zero);  // force re-fetch

    expect(api.fetchCallCount, 2);
  });

  test('refresh sets lastError on network failure but keeps prior snapshot', () async {
    final api = _FakeMetricsApi()..nextSnapshot = _snapshotFixture();
    final p = MetricsProvider(client: api);
    await p.refresh();
    final firstSnapshot = p.snapshot;

    api.throwOnFetch = Exception('no net');
    await p.refresh(maxAge: Duration.zero);

    expect(p.lastError, isNotNull);
    expect(p.snapshot, equals(firstSnapshot), reason: 'previous data preserved');
  });

  test('recomputeAndRefresh calls recompute then refresh', () async {
    final api = _FakeMetricsApi()..nextSnapshot = _snapshotFixture();
    final p = MetricsProvider(client: api);

    await p.recomputeAndRefresh();

    expect(api.recomputeCallCount, 1);
    expect(api.fetchCallCount, 1);
    expect(p.hasData, isTrue);
  });

  test('recomputeAndRefresh survives recompute failure (still fetches)', () async {
    final api = _FakeMetricsApi()
      ..throwOnRecompute = Exception('500')
      ..nextSnapshot = _snapshotFixture();
    final p = MetricsProvider(client: api);

    await p.recomputeAndRefresh();

    expect(api.recomputeCallCount, 1);
    expect(api.fetchCallCount, 1, reason: 'fetch should still run after recompute failure');
    expect(p.hasData, isTrue);
  });

  test('clear drops cached state and notifies', () async {
    final api = _FakeMetricsApi()..nextSnapshot = _snapshotFixture();
    final p = MetricsProvider(client: api);
    await p.refresh();

    var notified = 0;
    p.addListener(() => notified++);
    p.clear();

    expect(p.snapshot, isNull);
    expect(p.hasData, isFalse);
    expect(notified, 1);
  });

  test('concurrent refresh calls de-duplicate', () async {
    final api = _FakeMetricsApi()..nextSnapshot = _snapshotFixture();
    final p = MetricsProvider(client: api);

    final f1 = p.refresh();
    final f2 = p.refresh();
    await Future.wait([f1, f2]);

    expect(api.fetchCallCount, 1,
        reason: 'second concurrent refresh should be a no-op while loading');
  });

  test('refresh stashes prior snapshot before overwriting', () async {
    final api = _FakeMetricsApi()..nextSnapshot = _snapshotFixture(
      computedAt: DateTime.parse('2026-05-19T10:00:00Z'),
    );
    final p = MetricsProvider(client: api);

    await p.refresh();
    final first = p.snapshot;
    expect(p.previousSnapshot, isNull,
        reason: 'no prior snapshot on first ever refresh');

    api.nextSnapshot = _snapshotFixture(
      computedAt: DateTime.parse('2026-05-19T11:00:00Z'),
    );
    await p.refresh(maxAge: Duration.zero);

    expect(p.previousSnapshot, equals(first),
        reason: 'previousSnapshot reflects the snapshot we had just before this refresh');
    expect(p.snapshot, isNot(equals(first)));
  });

  test('refresh failure does not overwrite previousSnapshot', () async {
    final api = _FakeMetricsApi()..nextSnapshot = _snapshotFixture();
    final p = MetricsProvider(client: api);
    await p.refresh();
    final first = p.snapshot;
    expect(p.previousSnapshot, isNull);

    api.throwOnFetch = Exception('boom');
    await p.refresh(maxAge: Duration.zero);

    expect(p.previousSnapshot, isNull,
        reason: 'failed fetch should not touch previousSnapshot');
    expect(p.snapshot, equals(first),
        reason: 'failed fetch keeps the existing snapshot');
  });

  test('clear nulls both snapshot and previousSnapshot', () async {
    final api = _FakeMetricsApi()..nextSnapshot = _snapshotFixture();
    final p = MetricsProvider(client: api);
    await p.refresh();
    api.nextSnapshot = _snapshotFixture(
      computedAt: DateTime.parse('2026-05-19T11:00:00Z'),
    );
    await p.refresh(maxAge: Duration.zero);
    expect(p.snapshot, isNotNull);
    expect(p.previousSnapshot, isNotNull);

    p.clear();
    expect(p.snapshot, isNull);
    expect(p.previousSnapshot, isNull);
  });
}
