import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../metrics_helpers.dart';
import '../metrics_models.dart';

/// Post-run "This week so far" card. Distance / runs / streak rows with
/// week-over-week deltas (arrows + values). Streak row renders 🔥 when
/// streakDays >= 3.
class WeeklyProgressCard extends StatelessWidget {
  final WeeklyMetrics thisWeek;
  final WeeklyMetrics? previousWeek;

  const WeeklyProgressCard({
    super.key,
    required this.thisWeek,
    required this.previousWeek,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final delta = weeklyDelta(thisWeek, previousWeek);
    final showStreakFire = thisWeek.streakDays >= 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.lg, Space.md, Space.md),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border),
          borderRadius: BorderRadius.circular(Radii.standardCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This week so far',
              style: context.typo.label.copyWith(color: tokens.inkMuted),
            ),
            const SizedBox(height: Space.sm),
            _row(
              context,
              label: 'Distance',
              value: '${thisWeek.totalKm.toStringAsFixed(1)} km',
              delta: _formatDoubleDelta(delta.distanceKmDelta, suffix: '', dir: delta.distanceDir),
              dir: delta.distanceDir,
            ),
            _row(
              context,
              label: 'Runs',
              value: '${thisWeek.totalRuns}',
              delta: _formatIntDelta(delta.runsDelta, dir: delta.runsDir),
              dir: delta.runsDir,
            ),
            _row(
              context,
              label: 'Streak',
              value: '${thisWeek.streakDays} day${thisWeek.streakDays == 1 ? '' : 's'}${showStreakFire ? ' 🔥' : ''}',
              delta: null,
              dir: DeltaDirection.flat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required String value,
    required String? delta,
    required DeltaDirection dir,
  }) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: context.typo.bodySmall.copyWith(color: tokens.inkMuted)),
          ),
          Text(
            value,
            style: context.typo.body.copyWith(
              color: tokens.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (delta != null) ...[
            const SizedBox(width: Space.sm),
            Text(
              delta,
              style: context.typo.bodySmall.copyWith(color: _colorFor(tokens, dir)),
            ),
          ],
        ],
      ),
    );
  }

  static String? _formatDoubleDelta(double v, {required String suffix, required DeltaDirection dir}) {
    if (dir == DeltaDirection.unknown) return null;
    if (dir == DeltaDirection.flat) return '±0$suffix';
    final sign = v >= 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(1)}$suffix';
  }

  static String? _formatIntDelta(int v, {required DeltaDirection dir}) {
    if (dir == DeltaDirection.unknown) return null;
    if (dir == DeltaDirection.flat) return '±0';
    final sign = v >= 0 ? '+' : '';
    return '$sign$v';
  }

  static Color _colorFor(TregoTokens t, DeltaDirection dir) {
    switch (dir) {
      case DeltaDirection.up:
        return t.success;
      case DeltaDirection.down:
        return t.danger;
      case DeltaDirection.flat:
      case DeltaDirection.unknown:
        return t.inkMuted;
    }
  }
}
