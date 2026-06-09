import 'package:flutter_test/flutter_test.dart';
import 'package:trego/metrics/metrics_helpers.dart';
import 'package:trego/metrics/metrics_models.dart';

PrEntry _pr({
  required String runId,
  double distanceKm = 5.0,
  DateTime? startedAt,
  Duration? pace,
  Duration? duration,
}) =>
    PrEntry(
      runId: runId,
      distanceKm: distanceKm,
      runStartTime: startedAt ?? DateTime.parse('2026-05-01T08:00:00Z'),
      pacePerKm: pace,
      duration: duration,
    );

Prs _prsAll({
  PrEntry? f1k,
  PrEntry? f5k,
  PrEntry? f10k,
  PrEntry? longestDist,
  PrEntry? longestDur,
}) =>
    Prs(
      fastest1k: f1k,
      fastest5k: f5k,
      fastest10k: f10k,
      longestDistance: longestDist,
      longestDuration: longestDur,
    );

WeeklyMetrics _wk({
  double km = 10.0,
  int runs = 2,
  Duration time = const Duration(minutes: 60),
  Duration pace = const Duration(minutes: 6),
  double longest = 5.0,
  int streak = 1,
  String iso = '2026-W18',
}) =>
    WeeklyMetrics(
      isoYearWeek: iso,
      weekStart: DateTime.parse('2026-04-27T00:00:00Z'),
      weekEnd: DateTime.parse('2026-05-03T23:59:59Z'),
      totalKm: km,
      totalRuns: runs,
      totalTime: time,
      avgPacePerKm: pace,
      longestKm: longest,
      streakDays: streak,
    );

void main() {
  group('pickHeroPr', () {
    test('returns null when prs is null', () {
      expect(pickHeroPr(null, 'r1'), isNull);
    });

    test('returns null when runId is null', () {
      final prs = _prsAll(f5k: _pr(runId: 'r1'));
      expect(pickHeroPr(prs, null), isNull);
    });

    test('returns null when no category matches the run id', () {
      final prs = _prsAll(f5k: _pr(runId: 'other'));
      expect(pickHeroPr(prs, 'r1'), isNull);
    });

    test('returns the matching category when only one matches', () {
      final prs = _prsAll(f5k: _pr(runId: 'r1', duration: const Duration(minutes: 25)));
      final pick = pickHeroPr(prs, 'r1');
      expect(pick, isNotNull);
      expect(pick!.category, PrCategory.fastest5k);
      expect(pick.current.runId, 'r1');
    });

    test('prefers fastest10k over fastest5k when both match the same run', () {
      final prs = _prsAll(
        f5k: _pr(runId: 'r1'),
        f10k: _pr(runId: 'r1'),
      );
      expect(pickHeroPr(prs, 'r1')!.category, PrCategory.fastest10k);
    });

    test('prefers fastest5k over fastest1k when both match the same run', () {
      final prs = _prsAll(
        f1k: _pr(runId: 'r1'),
        f5k: _pr(runId: 'r1'),
      );
      expect(pickHeroPr(prs, 'r1')!.category, PrCategory.fastest5k);
    });

    test('prefers fastest1k over longestDistance when both match', () {
      final prs = _prsAll(
        f1k: _pr(runId: 'r1'),
        longestDist: _pr(runId: 'r1'),
      );
      expect(pickHeroPr(prs, 'r1')!.category, PrCategory.fastest1k);
    });

    test('prefers longestDistance over longestDuration when both match', () {
      final prs = _prsAll(
        longestDist: _pr(runId: 'r1'),
        longestDur: _pr(runId: 'r1'),
      );
      expect(pickHeroPr(prs, 'r1')!.category, PrCategory.longestDistance);
    });
  });

  group('pickRecentPr', () {
    final now = DateTime.parse('2026-05-10T12:00:00Z');

    test('returns null when prs is null', () {
      expect(pickRecentPr(null, now), isNull);
    });

    test('returns null when all PRs are older than the window', () {
      final old = DateTime.parse('2026-05-01T08:00:00Z');     // 9 days ago
      final prs = _prsAll(
        f5k: _pr(runId: 'r1', startedAt: old),
        longestDist: _pr(runId: 'r2', startedAt: old),
      );
      expect(pickRecentPr(prs, now), isNull);
    });

    test('returns the most recent PR within the window', () {
      final twoDaysAgo = DateTime.parse('2026-05-08T10:00:00Z');
      final sixDaysAgo = DateTime.parse('2026-05-04T10:00:00Z');
      final prs = _prsAll(
        f5k: _pr(runId: 'r5k', startedAt: sixDaysAgo),
        longestDist: _pr(runId: 'rdist', startedAt: twoDaysAgo),
      );
      final pick = pickRecentPr(prs, now);
      expect(pick, isNotNull);
      expect(pick!.current.runId, 'rdist');
      expect(pick.category, PrCategory.longestDistance);
    });

    test('ignores null categories', () {
      final recent = DateTime.parse('2026-05-09T10:00:00Z');
      final prs = _prsAll(f5k: _pr(runId: 'r1', startedAt: recent));
      final pick = pickRecentPr(prs, now);
      expect(pick!.category, PrCategory.fastest5k);
    });

    test('window is inclusive at exactly 7 days', () {
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final prs = _prsAll(f5k: _pr(runId: 'r1', startedAt: sevenDaysAgo));
      expect(pickRecentPr(prs, now), isNotNull);
    });
  });

  group('prDelta', () {
    test('returns null when previous is null', () {
      final current = _pr(runId: 'r1', duration: const Duration(seconds: 1472));
      expect(
        prDelta(PrCategory.fastest5k, current, null),
        isNull,
      );
    });

    test('returns null when previous has the same runId (same PR — no improvement)', () {
      final entry = _pr(runId: 'r1', duration: const Duration(seconds: 1472));
      expect(
        prDelta(PrCategory.fastest5k, entry, entry),
        isNull,
      );
    });

    test('returns "N sec faster" for pace PRs', () {
      final current = _pr(runId: 'r2', duration: const Duration(seconds: 1472));
      final previous = _pr(runId: 'r1', duration: const Duration(seconds: 1490));
      expect(
        prDelta(PrCategory.fastest5k, current, previous),
        '18 sec faster than your best',
      );
    });

    test('returns "N m further" for longestDistance PRs', () {
      final current = _pr(runId: 'r2', distanceKm: 12.1);
      final previous = _pr(runId: 'r1', distanceKm: 11.7);
      expect(
        prDelta(PrCategory.longestDistance, current, previous),
        '400 m further than your best',
      );
    });

    test('returns "N min longer" for longestDuration PRs over 60 sec delta', () {
      final current = _pr(runId: 'r2', duration: const Duration(minutes: 65));
      final previous = _pr(runId: 'r1', duration: const Duration(minutes: 60));
      expect(
        prDelta(PrCategory.longestDuration, current, previous),
        '5 min longer than your best',
      );
    });

    test('returns "N sec longer" for longestDuration PRs under 60 sec delta', () {
      final current = _pr(runId: 'r2', duration: const Duration(seconds: 3640));
      final previous = _pr(runId: 'r1', duration: const Duration(seconds: 3625));
      expect(
        prDelta(PrCategory.longestDuration, current, previous),
        '15 sec longer than your best',
      );
    });
  });

  group('weeklyDelta', () {
    test('returns unknown directions when previous is null', () {
      final delta = weeklyDelta(_wk(km: 20, runs: 3), null);
      expect(delta.distanceDir, DeltaDirection.unknown);
      expect(delta.runsDir, DeltaDirection.unknown);
      expect(delta.distanceKmDelta, 0);
      expect(delta.runsDelta, 0);
    });

    test('returns up direction with positive delta when current > previous', () {
      final delta = weeklyDelta(
        _wk(km: 23.4, runs: 4),
        _wk(km: 19.3, runs: 3),
      );
      expect(delta.distanceDir, DeltaDirection.up);
      expect(delta.runsDir, DeltaDirection.up);
      expect(delta.distanceKmDelta, closeTo(4.1, 0.001));
      expect(delta.runsDelta, 1);
    });

    test('returns down direction with negative delta when current < previous', () {
      final delta = weeklyDelta(
        _wk(km: 5.0, runs: 1),
        _wk(km: 12.0, runs: 3),
      );
      expect(delta.distanceDir, DeltaDirection.down);
      expect(delta.runsDir, DeltaDirection.down);
      expect(delta.distanceKmDelta, closeTo(-7.0, 0.001));
      expect(delta.runsDelta, -2);
    });

    test('returns flat direction when current == previous', () {
      final delta = weeklyDelta(_wk(km: 10, runs: 2), _wk(km: 10, runs: 2));
      expect(delta.distanceDir, DeltaDirection.flat);
      expect(delta.runsDir, DeltaDirection.flat);
    });
  });
}
