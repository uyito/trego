import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../metrics_models.dart';

/// 12-bar mini chart of weekly km. Bars normalised to the tallest week.
/// Zero-km weeks render a 2-pixel "presence" stripe.
class WeeklySparkline extends StatelessWidget {
  final List<WeeklyMetrics> history;
  final double height;

  const WeeklySparkline({
    super.key,
    required this.history,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (history.isEmpty) {
      return SizedBox(height: height);
    }
    final maxKm = history
        .map((w) => w.totalKm)
        .fold<double>(0, (a, b) => b > a ? b : a);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: Container(
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border),
          borderRadius: BorderRadius.circular(Radii.compactCard),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'LAST ${history.length} WEEKS · KM',
              style: context.typo.label.copyWith(color: tokens.inkMuted),
            ),
            const SizedBox(height: Space.xs),
            SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < history.length; i++) ...[
                    Expanded(
                      child: SparkBar(
                        key: ValueKey('sparkline-bar-$i'),
                        heightRatio: maxKm == 0 ? 0 : history[i].totalKm / maxKm,
                        isPresenceOnly: history[i].totalKm <= 0,
                      ),
                    ),
                    if (i != history.length - 1) const SizedBox(width: 2),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single bar in the sparkline. Public so the widget test can introspect its
/// `heightRatio` and `isPresenceOnly` props.
class SparkBar extends StatelessWidget {
  /// 0..1 fraction of available height to fill. Ignored when [isPresenceOnly].
  final double heightRatio;
  final bool isPresenceOnly;

  const SparkBar({
    super.key,
    required this.heightRatio,
    required this.isPresenceOnly,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight;
        final h = isPresenceOnly
            ? 2.0
            : (heightRatio.clamp(0.0, 1.0) * available).clamp(2.0, available);
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: isPresenceOnly ? tokens.border : tokens.brand,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}
