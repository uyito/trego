import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';

class SplitRow extends StatelessWidget {
  final int kmIndex;
  final Duration splitPace;
  final double fastestPaceSecPerKm;
  final double slowestPaceSecPerKm;

  const SplitRow({
    super.key,
    required this.kmIndex,
    required this.splitPace,
    required this.fastestPaceSecPerKm,
    required this.slowestPaceSecPerKm,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final paceSec = splitPace.inSeconds.toDouble();

    // Faster split = longer bar. Normalized to 15%–100%.
    final range = (slowestPaceSecPerKm - fastestPaceSecPerKm).abs();
    final fill = range == 0
        ? 1.0
        : (1.0 - ((paceSec - fastestPaceSecPerKm) / range)).clamp(0.15, 1.0);

    final minutes = splitPace.inMinutes;
    final seconds = splitPace.inSeconds % 60;
    final formatted = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$kmIndex',
              style: context.typo.titleSmall.copyWith(color: tokens.inkMuted),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fill,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tokens.brand, tokens.brandContainerEnd],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          SizedBox(
            width: 52,
            child: Text(
              formatted,
              textAlign: TextAlign.right,
              style: context.typo.titleSmall.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
