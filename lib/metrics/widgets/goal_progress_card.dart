import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../metrics_helpers.dart';
import '../metrics_models.dart';

/// "Weekly goal" card. Shows progress bars toward the user's km / run-count
/// targets, an "X of Y" line per target, and a subtle checkmark when a target
/// is met. When no goal is set, shows a "Set a weekly goal" prompt.
///
/// [onEdit] opens the goal editor; [onSet] is the CTA when no goal exists.
class GoalProgressCard extends StatelessWidget {
  final WeeklyMetrics thisWeek;
  final WeeklyGoal? goal;
  final VoidCallback? onEdit;

  const GoalProgressCard({
    super.key,
    required this.thisWeek,
    required this.goal,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasGoal = goal != null && !goal!.isEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.sm),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border),
          borderRadius: BorderRadius.circular(Radii.standardCard),
        ),
        child: hasGoal ? _buildGoal(context, tokens) : _buildEmpty(context, tokens),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, TregoTokens tokens) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weekly goal',
                  style: context.typo.label.copyWith(color: tokens.inkMuted)),
              const SizedBox(height: 4),
              Text('Set a target to track your week',
                  style: context.typo.bodySmall.copyWith(color: tokens.inkMuted)),
            ],
          ),
        ),
        TextButton(
          onPressed: onEdit,
          child: Text('Set goal',
              style: context.typo.button.copyWith(color: tokens.brand)),
        ),
      ],
    );
  }

  Widget _buildGoal(BuildContext context, TregoTokens tokens) {
    final progress = goalProgress(thisWeek, goal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Weekly goal',
                  style: context.typo.label.copyWith(color: tokens.inkMuted)),
            ),
            if (progress.allMet)
              Icon(Icons.check_circle, size: 18, color: tokens.success),
            IconButton(
              icon: Icon(Icons.edit, size: 18, color: tokens.inkMuted),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onEdit,
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        if (progress.hasKm)
          _bar(
            context,
            tokens,
            label: 'Distance',
            valueLabel: '${thisWeek.totalKm.toStringAsFixed(1)} of '
                '${goal!.targetKm!.toStringAsFixed(0)} km',
            fraction: progress.kmFraction!,
            met: progress.kmFraction! >= 1.0,
          ),
        if (progress.hasKm && progress.hasRuns) const SizedBox(height: Space.sm),
        if (progress.hasRuns)
          _bar(
            context,
            tokens,
            label: 'Runs',
            valueLabel: '${thisWeek.totalRuns} of ${goal!.targetRuns} runs',
            fraction: progress.runsFraction!,
            met: progress.runsFraction! >= 1.0,
          ),
      ],
    );
  }

  Widget _bar(
    BuildContext context,
    TregoTokens tokens, {
    required String label,
    required String valueLabel,
    required double fraction,
    required bool met,
  }) {
    final barColor = met ? tokens.success : tokens.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: context.typo.bodySmall.copyWith(color: tokens.ink)),
            Row(
              children: [
                if (met) Icon(Icons.check, size: 14, color: tokens.success),
                if (met) const SizedBox(width: 4),
                Text(valueLabel,
                    style: context.typo.bodySmall.copyWith(color: tokens.inkMuted)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: tokens.border,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
