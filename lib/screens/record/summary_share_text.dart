import '../../metrics/metrics_helpers.dart';
import '../../metrics/metrics_models.dart';
import '../../tracker/run_model.dart';

/// Auto-generated title for a run based on local hour.
String autoRunTitle(DateTime start) {
  final h = start.hour;
  if (h < 11) return 'Morning Run';
  if (h < 17) return 'Afternoon Run';
  if (h < 21) return 'Evening Run';
  return 'Night Run';
}

/// "m:ss" pace string from minutes-per-km.
String formatPace(double minutesPerKm) {
  final total = (minutesPerKm * 60).round();
  final mm = total ~/ 60;
  final ss = total % 60;
  return '$mm:${ss.toString().padLeft(2, '0')}';
}

/// Composes the share-sheet text for a finished run.
///
/// Always includes title + distance + duration + pace. Appends a PR call-out
/// line when [pickHeroPr] returns non-null for the run; the delta clause is
/// added when a prior PR exists in [previousPrs] and represents a true
/// improvement (see [prDelta]).
String buildShareText({
  required Run run,
  Prs? prs,
  Prs? previousPrs,
}) {
  final title = autoRunTitle(run.startTime);
  final distance = run.distance.toStringAsFixed(2);
  final duration = Run.formatDuration(run.duration);
  final pace = formatPace(run.averagePace);

  final lines = <String>['$title · $distance km in $duration ($pace/km)'];

  final pick = pickHeroPr(prs, run.id);
  if (pick != null) {
    final label = _prLabel(pick.category);
    final delta = prDelta(
      pick.category,
      pick.current,
      _entryFor(previousPrs, pick.category),
    );
    final suffix = delta != null ? ' — $delta' : '';
    lines.add('🏆 New $label$suffix');
  }

  return lines.join('\n');
}

String _prLabel(PrCategory cat) {
  switch (cat) {
    case PrCategory.fastest1k:
      return '1K PR';
    case PrCategory.fastest5k:
      return '5K PR';
    case PrCategory.fastest10k:
      return '10K PR';
    case PrCategory.longestDistance:
      return 'longest distance';
    case PrCategory.longestDuration:
      return 'longest run';
  }
}

PrEntry? _entryFor(Prs? prs, PrCategory cat) {
  if (prs == null) return null;
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
