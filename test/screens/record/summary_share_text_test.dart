import 'package:flutter_test/flutter_test.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/screens/record/summary_share_text.dart';
import 'package:trego/tracker/run_model.dart';

Run _run({
  String id = 'run-1',
  DateTime? start,
  Duration duration = const Duration(minutes: 24, seconds: 13),
  double distance = 5.20,
  double pace = 4.633, // ≈ 4:38
}) =>
    Run(
      id: id,
      userId: 'u',
      startTime: start ?? DateTime(2026, 4, 19, 8, 4),
      duration: duration,
      distance: distance,
      averagePace: pace,
      route: const [],
    );

Prs _prs({
  PrEntry? fastest1k,
  PrEntry? fastest5k,
  PrEntry? fastest10k,
  PrEntry? longestDistance,
  PrEntry? longestDuration,
}) =>
    Prs(
      fastest1k: fastest1k,
      fastest5k: fastest5k,
      fastest10k: fastest10k,
      longestDistance: longestDistance,
      longestDuration: longestDuration,
    );

void main() {
  group('autoRunTitle', () {
    test('Morning before 11', () {
      expect(autoRunTitle(DateTime(2026, 1, 1, 7)), 'Morning Run');
    });
    test('Afternoon 11-16', () {
      expect(autoRunTitle(DateTime(2026, 1, 1, 14)), 'Afternoon Run');
    });
    test('Evening 17-20', () {
      expect(autoRunTitle(DateTime(2026, 1, 1, 19)), 'Evening Run');
    });
    test('Night 21+', () {
      expect(autoRunTitle(DateTime(2026, 1, 1, 22)), 'Night Run');
    });
  });

  group('formatPace', () {
    test('4.633 → 4:38', () {
      expect(formatPace(4.633), '4:38');
    });
    test('5.0 → 5:00 (zero-pads seconds)', () {
      expect(formatPace(5.0), '5:00');
    });
    test('0.5 → 0:30', () {
      expect(formatPace(0.5), '0:30');
    });
  });

  group('buildShareText', () {
    test('no PR → single summary line', () {
      final text = buildShareText(run: _run(), prs: null, previousPrs: null);
      expect(text, 'Morning Run · 5.20 km in 24:13 (4:38/km)');
    });

    test('PR with no prior PR → trophy line, no delta', () {
      final fiveK = PrEntry(
        runId: 'run-1',
        distanceKm: 5.0,
        runStartTime: DateTime(2026, 4, 19, 8, 4),
        duration: const Duration(minutes: 23),
      );
      final text = buildShareText(
        run: _run(),
        prs: _prs(fastest5k: fiveK),
        previousPrs: null,
      );
      expect(text, contains('Morning Run · 5.20 km in 24:13 (4:38/km)'));
      expect(text, contains('🏆 New 5K PR'));
      expect(text, isNot(contains('faster')));
    });

    test('PR with prior PR → trophy line + delta', () {
      final cur = PrEntry(
        runId: 'run-1',
        distanceKm: 5.0,
        runStartTime: DateTime(2026, 4, 19, 8, 4),
        duration: const Duration(minutes: 23),
      );
      final prev = PrEntry(
        runId: 'run-0',
        distanceKm: 5.0,
        runStartTime: DateTime(2026, 4, 12, 8, 0),
        duration: const Duration(minutes: 23, seconds: 12),
      );
      final text = buildShareText(
        run: _run(),
        prs: _prs(fastest5k: cur),
        previousPrs: _prs(fastest5k: prev),
      );
      expect(text, contains('🏆 New 5K PR — 12 sec faster than your best'));
    });

    test('hero priority: 10K beats 5K when both set in same run', () {
      final tenK = PrEntry(
        runId: 'run-1',
        distanceKm: 10.0,
        runStartTime: DateTime(2026, 4, 19, 8, 4),
        duration: const Duration(minutes: 48),
      );
      final fiveK = PrEntry(
        runId: 'run-1',
        distanceKm: 5.0,
        runStartTime: DateTime(2026, 4, 19, 8, 4),
        duration: const Duration(minutes: 23),
      );
      final text = buildShareText(
        run: _run(),
        prs: _prs(fastest5k: fiveK, fastest10k: tenK),
        previousPrs: null,
      );
      expect(text, contains('10K PR'));
      expect(text, isNot(contains('5K PR')));
    });

    test('PR for a different runId is not mentioned', () {
      final fiveK = PrEntry(
        runId: 'other-run',
        distanceKm: 5.0,
        runStartTime: DateTime(2026, 4, 12, 8, 0),
        duration: const Duration(minutes: 23),
      );
      final text = buildShareText(
        run: _run(id: 'run-1'),
        prs: _prs(fastest5k: fiveK),
        previousPrs: null,
      );
      expect(text, isNot(contains('🏆')));
    });

    test('longest distance PR uses meters delta wording', () {
      final cur = PrEntry(
        runId: 'run-1',
        distanceKm: 7.5,
        runStartTime: DateTime(2026, 4, 19, 8, 4),
      );
      final prev = PrEntry(
        runId: 'run-0',
        distanceKm: 7.0,
        runStartTime: DateTime(2026, 4, 12, 8, 0),
      );
      final text = buildShareText(
        run: _run(distance: 7.5),
        prs: _prs(longestDistance: cur),
        previousPrs: _prs(longestDistance: prev),
      );
      expect(text, contains('🏆 New longest distance — 500 m further than your best'));
    });
  });
}
