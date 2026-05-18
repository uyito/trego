import 'package:flutter_test/flutter_test.dart';
import 'package:trego/metrics/metrics_models.dart';

void main() {
  group('WeeklyMetrics', () {
    test('round-trips via JSON', () {
      final w = WeeklyMetrics(
        isoYearWeek: '2026-W17',
        weekStart: DateTime.parse('2026-04-20T00:00:00Z'),
        weekEnd: DateTime.parse('2026-04-26T23:59:59Z'),
        totalKm: 23.4,
        totalRuns: 4,
        totalTime: const Duration(milliseconds: 5418000),
        avgPacePerKm: const Duration(seconds: 308),
        longestKm: 8.2,
        streakDays: 6,
      );
      final back = WeeklyMetrics.fromJson(w.toJson());
      expect(back.isoYearWeek, w.isoYearWeek);
      expect(back.weekStart, w.weekStart);
      expect(back.totalKm, w.totalKm);
      expect(back.totalRuns, w.totalRuns);
      expect(back.totalTime, w.totalTime);
      expect(back.avgPacePerKm, w.avgPacePerKm);
      expect(back.streakDays, w.streakDays);
    });
  });

  group('PrEntry', () {
    test('pace PR round-trips', () {
      final p = PrEntry(
        runId: 'abc',
        distanceKm: 6.0,
        runStartTime: DateTime.parse('2026-04-21T08:04:00Z'),
        pacePerKm: const Duration(seconds: 198),
      );
      final back = PrEntry.fromJson(p.toJson());
      expect(back.runId, 'abc');
      expect(back.pacePerKm, const Duration(seconds: 198));
      expect(back.duration, isNull);
    });

    test('distance/duration PR round-trips', () {
      final p = PrEntry(
        runId: 'xyz',
        distanceKm: 12.1,
        runStartTime: DateTime.parse('2026-04-15T08:00:00Z'),
        duration: const Duration(milliseconds: 4500000),
      );
      final back = PrEntry.fromJson(p.toJson());
      expect(back.duration, const Duration(milliseconds: 4500000));
      expect(back.pacePerKm, isNull);
    });
  });

  group('Prs', () {
    test('null PRs round-trip as null', () {
      final p = Prs(fastest1k: null, fastest5k: null, fastest10k: null,
                    longestDistance: null, longestDuration: null);
      final back = Prs.fromJson(p.toJson());
      expect(back.fastest5k, isNull);
      expect(back.longestDistance, isNull);
    });
  });

  group('LifetimeTotals', () {
    test('round-trips', () {
      final t = LifetimeTotals(
        totalKm: 247.3,
        totalRuns: 42,
        totalTime: const Duration(milliseconds: 87600000),
      );
      final back = LifetimeTotals.fromJson(t.toJson());
      expect(back.totalKm, 247.3);
      expect(back.totalRuns, 42);
      expect(back.totalTime, const Duration(milliseconds: 87600000));
    });
  });

  group('MetricsSnapshot', () {
    test('full snapshot round-trips', () {
      final wk = WeeklyMetrics(
        isoYearWeek: '2026-W17',
        weekStart: DateTime.parse('2026-04-20T00:00:00Z'),
        weekEnd: DateTime.parse('2026-04-26T23:59:59Z'),
        totalKm: 23.4,
        totalRuns: 4,
        totalTime: const Duration(milliseconds: 5418000),
        avgPacePerKm: const Duration(seconds: 308),
        longestKm: 8.2,
        streakDays: 6,
      );
      final snap = MetricsSnapshot(
        computedAt: DateTime.parse('2026-04-27T18:34:12Z'),
        thisWeek: wk,
        prs: Prs(fastest1k: null, fastest5k: null, fastest10k: null,
                 longestDistance: null, longestDuration: null),
        totals: LifetimeTotals(totalKm: 0, totalRuns: 0, totalTime: Duration.zero),
        history: [wk],
      );
      final back = MetricsSnapshot.fromJson(snap.toJson());
      expect(back.thisWeek.isoYearWeek, '2026-W17');
      expect(back.history.length, 1);
    });
  });
}
