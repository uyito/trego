/// Metrics data models — typed mirrors of the backend DTOs.
/// All Duration fields serialize as integer milliseconds. All DateTime
/// fields serialize as ISO 8601 strings.

class WeeklyMetrics {
  final String isoYearWeek;
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalKm;
  final int totalRuns;
  final Duration totalTime;
  final Duration avgPacePerKm;
  final double longestKm;
  final int streakDays;

  const WeeklyMetrics({
    required this.isoYearWeek,
    required this.weekStart,
    required this.weekEnd,
    required this.totalKm,
    required this.totalRuns,
    required this.totalTime,
    required this.avgPacePerKm,
    required this.longestKm,
    required this.streakDays,
  });

  factory WeeklyMetrics.fromJson(Map<String, dynamic> j) => WeeklyMetrics(
        isoYearWeek: j['isoYearWeek'] as String,
        weekStart: DateTime.parse(j['weekStart'] as String),
        weekEnd: DateTime.parse(j['weekEnd'] as String),
        totalKm: (j['totalKm'] as num).toDouble(),
        totalRuns: j['totalRuns'] as int,
        totalTime: Duration(milliseconds: (j['totalTimeMs'] as num).toInt()),
        avgPacePerKm: Duration(seconds: (j['avgPaceSecPerKm'] as num).toInt()),
        longestKm: (j['longestKm'] as num).toDouble(),
        streakDays: j['streakDays'] as int,
      );

  Map<String, dynamic> toJson() => {
        'isoYearWeek': isoYearWeek,
        'weekStart': weekStart.toUtc().toIso8601String(),
        'weekEnd': weekEnd.toUtc().toIso8601String(),
        'totalKm': totalKm,
        'totalRuns': totalRuns,
        'totalTimeMs': totalTime.inMilliseconds,
        'avgPaceSecPerKm': avgPacePerKm.inSeconds,
        'longestKm': longestKm,
        'streakDays': streakDays,
      };
}

class PrEntry {
  final String runId;
  final double distanceKm;
  final DateTime runStartTime;
  final Duration? pacePerKm;
  final Duration? duration;

  const PrEntry({
    required this.runId,
    required this.distanceKm,
    required this.runStartTime,
    this.pacePerKm,
    this.duration,
  });

  factory PrEntry.fromJson(Map<String, dynamic> j) => PrEntry(
        runId: j['runId'] as String,
        distanceKm: (j['distanceKm'] as num).toDouble(),
        runStartTime: DateTime.parse(j['runStartTime'] as String),
        pacePerKm: j['paceSecPerKm'] == null
            ? null
            : Duration(seconds: (j['paceSecPerKm'] as num).toInt()),
        duration: j['durationMs'] == null
            ? null
            : Duration(milliseconds: (j['durationMs'] as num).toInt()),
      );

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'runId': runId,
      'distanceKm': distanceKm,
      'runStartTime': runStartTime.toUtc().toIso8601String(),
    };
    if (pacePerKm != null) m['paceSecPerKm'] = pacePerKm!.inSeconds;
    if (duration != null) m['durationMs'] = duration!.inMilliseconds;
    return m;
  }
}

class Prs {
  final PrEntry? fastest1k;
  final PrEntry? fastest5k;
  final PrEntry? fastest10k;
  final PrEntry? longestDistance;
  final PrEntry? longestDuration;

  const Prs({
    required this.fastest1k,
    required this.fastest5k,
    required this.fastest10k,
    required this.longestDistance,
    required this.longestDuration,
  });

  factory Prs.fromJson(Map<String, dynamic> j) => Prs(
        fastest1k: j['fastest1k'] == null ? null : PrEntry.fromJson(j['fastest1k'] as Map<String, dynamic>),
        fastest5k: j['fastest5k'] == null ? null : PrEntry.fromJson(j['fastest5k'] as Map<String, dynamic>),
        fastest10k: j['fastest10k'] == null ? null : PrEntry.fromJson(j['fastest10k'] as Map<String, dynamic>),
        longestDistance: j['longestDistance'] == null ? null : PrEntry.fromJson(j['longestDistance'] as Map<String, dynamic>),
        longestDuration: j['longestDuration'] == null ? null : PrEntry.fromJson(j['longestDuration'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'fastest1k': fastest1k?.toJson(),
        'fastest5k': fastest5k?.toJson(),
        'fastest10k': fastest10k?.toJson(),
        'longestDistance': longestDistance?.toJson(),
        'longestDuration': longestDuration?.toJson(),
      };
}

class LifetimeTotals {
  final double totalKm;
  final int totalRuns;
  final Duration totalTime;

  const LifetimeTotals({
    required this.totalKm,
    required this.totalRuns,
    required this.totalTime,
  });

  factory LifetimeTotals.fromJson(Map<String, dynamic> j) => LifetimeTotals(
        totalKm: (j['totalKm'] as num).toDouble(),
        totalRuns: j['totalRuns'] as int,
        totalTime: Duration(milliseconds: (j['totalTimeMs'] as num).toInt()),
      );

  Map<String, dynamic> toJson() => {
        'totalKm': totalKm,
        'totalRuns': totalRuns,
        'totalTimeMs': totalTime.inMilliseconds,
      };
}

class MetricsSnapshot {
  final DateTime computedAt;
  final WeeklyMetrics thisWeek;
  final Prs prs;
  final LifetimeTotals totals;
  final List<WeeklyMetrics> history;

  const MetricsSnapshot({
    required this.computedAt,
    required this.thisWeek,
    required this.prs,
    required this.totals,
    required this.history,
  });

  factory MetricsSnapshot.fromJson(Map<String, dynamic> j) => MetricsSnapshot(
        computedAt: DateTime.parse(j['computedAt'] as String),
        thisWeek: WeeklyMetrics.fromJson(j['thisWeek'] as Map<String, dynamic>),
        prs: Prs.fromJson(j['prs'] as Map<String, dynamic>),
        totals: LifetimeTotals.fromJson(j['totals'] as Map<String, dynamic>),
        history: (j['history'] as List<dynamic>)
            .map((e) => WeeklyMetrics.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'computedAt': computedAt.toUtc().toIso8601String(),
        'thisWeek': thisWeek.toJson(),
        'prs': prs.toJson(),
        'totals': totals.toJson(),
        'history': history.map((w) => w.toJson()).toList(),
      };
}

/// A user's weekly training goal. Both targets are optional (a user may set a
/// distance target, a run-count target, both, or neither).
class WeeklyGoal {
  final double? targetKm;
  final int? targetRuns;
  final DateTime? updatedAt;

  const WeeklyGoal({this.targetKm, this.targetRuns, this.updatedAt});

  /// True when neither target is set.
  bool get isEmpty => targetKm == null && targetRuns == null;

  factory WeeklyGoal.fromJson(Map<String, dynamic> j) => WeeklyGoal(
        targetKm: (j['targetKm'] as num?)?.toDouble(),
        targetRuns: (j['targetRuns'] as num?)?.toInt(),
        updatedAt: j['updatedAt'] != null
            ? DateTime.tryParse(j['updatedAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        if (targetKm != null) 'targetKm': targetKm,
        if (targetRuns != null) 'targetRuns': targetRuns,
      };
}
