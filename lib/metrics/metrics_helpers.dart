import 'metrics_models.dart';

/// Identifies which PR category a [PrEntry] belongs to.
enum PrCategory { fastest1k, fastest5k, fastest10k, longestDistance, longestDuration }

/// Direction of a week-over-week metric change.
enum DeltaDirection { up, down, flat, unknown }

/// Result of picking a PR from a [Prs] bundle. Carries enough context for the
/// UI to render the right label and delta line.
class PrPick {
  final PrCategory category;
  final PrEntry current;

  const PrPick({required this.category, required this.current});
}

/// Week-over-week deltas for the Summary screen's progress card.
class WeeklyDelta {
  final double distanceKmDelta;
  final int runsDelta;
  final DeltaDirection distanceDir;
  final DeltaDirection runsDir;

  const WeeklyDelta({
    required this.distanceKmDelta,
    required this.runsDelta,
    required this.distanceDir,
    required this.runsDir,
  });
}

/// Priority order for picking the headline PR when a single run sets multiple.
/// Index 0 is the highest priority.
const List<PrCategory> _heroPriority = [
  PrCategory.fastest10k,
  PrCategory.fastest5k,
  PrCategory.fastest1k,
  PrCategory.longestDistance,
  PrCategory.longestDuration,
];

/// Returns the matching PR category for [runId], preferring higher-priority
/// categories when multiple match. Returns null if [prs] is null, [runId] is
/// null, or no category references [runId].
PrPick? pickHeroPr(Prs? prs, String? runId) {
  if (prs == null || runId == null) return null;
  for (final cat in _heroPriority) {
    final entry = _entryFor(prs, cat);
    if (entry != null && entry.runId == runId) {
      return PrPick(category: cat, current: entry);
    }
  }
  return null;
}

/// Returns the most recent PR whose `runStartTime` is within [window] of [now].
/// Considers all 5 categories. Ties broken by [_heroPriority] order.
PrPick? pickRecentPr(
  Prs? prs,
  DateTime now, {
  Duration window = const Duration(days: 7),
}) {
  if (prs == null) return null;
  PrPick? best;
  for (final cat in _heroPriority) {
    final entry = _entryFor(prs, cat);
    if (entry == null) continue;
    if (now.difference(entry.runStartTime) > window) continue;
    if (best == null || entry.runStartTime.isAfter(best.current.runStartTime)) {
      best = PrPick(category: cat, current: entry);
    }
  }
  return best;
}

/// Formats the delta line shown under the PR banner. Returns null if there's
/// no previous PR to compare against, or if the previous and current entries
/// share a runId (same PR — no improvement).
String? prDelta(PrCategory category, PrEntry current, PrEntry? previous) {
  if (previous == null) return null;
  if (previous.runId == current.runId) return null;

  switch (category) {
    case PrCategory.fastest1k:
    case PrCategory.fastest5k:
    case PrCategory.fastest10k:
      final cur = current.duration;
      final prev = previous.duration;
      if (cur == null || prev == null) return null;
      final secs = prev.inSeconds - cur.inSeconds;
      if (secs <= 0) return null;
      return '$secs sec faster than your best';
    case PrCategory.longestDistance:
      final meters = ((current.distanceKm - previous.distanceKm) * 1000).round();
      if (meters <= 0) return null;
      return '$meters m further than your best';
    case PrCategory.longestDuration:
      final cur = current.duration;
      final prev = previous.duration;
      if (cur == null || prev == null) return null;
      final secs = cur.inSeconds - prev.inSeconds;
      if (secs <= 0) return null;
      if (secs >= 60) {
        final mins = secs ~/ 60;
        return '$mins min longer than your best';
      }
      return '$secs sec longer than your best';
  }
}

/// Computes week-over-week deltas. If [previous] is null (no prior week),
/// directions are [DeltaDirection.unknown] and the numeric deltas are zero.
WeeklyDelta weeklyDelta(WeeklyMetrics current, WeeklyMetrics? previous) {
  if (previous == null) {
    return const WeeklyDelta(
      distanceKmDelta: 0,
      runsDelta: 0,
      distanceDir: DeltaDirection.unknown,
      runsDir: DeltaDirection.unknown,
    );
  }
  final dKm = current.totalKm - previous.totalKm;
  final dRuns = current.totalRuns - previous.totalRuns;
  return WeeklyDelta(
    distanceKmDelta: dKm,
    runsDelta: dRuns,
    distanceDir: _dir(dKm),
    runsDir: _dirInt(dRuns),
  );
}

DeltaDirection _dir(double v) {
  if (v > 0) return DeltaDirection.up;
  if (v < 0) return DeltaDirection.down;
  return DeltaDirection.flat;
}

DeltaDirection _dirInt(int v) {
  if (v > 0) return DeltaDirection.up;
  if (v < 0) return DeltaDirection.down;
  return DeltaDirection.flat;
}

PrEntry? _entryFor(Prs prs, PrCategory cat) {
  switch (cat) {
    case PrCategory.fastest1k:
      return prs.fastest1k;
    case PrCategory.fastest5k:
      return prs.fastest5k;
    case PrCategory.fastest10k:
      return prs.fastest10k;
    case PrCategory.longestDistance:
      return prs.longestDistance;
    case PrCategory.longestDuration:
      return prs.longestDuration;
  }
}
