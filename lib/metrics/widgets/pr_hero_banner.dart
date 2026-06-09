import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../metrics_helpers.dart';
import '../metrics_models.dart';

/// Full-width celebration banner shown above the Summary header iff the
/// just-finished run set a new PR. Always token-pure.
class PrHeroBanner extends StatelessWidget {
  final Prs? prs;
  final Prs? previousPrs;
  final String? runId;

  const PrHeroBanner({
    super.key,
    required this.prs,
    required this.previousPrs,
    required this.runId,
  });

  @override
  Widget build(BuildContext context) {
    final pick = pickHeroPr(prs, runId);
    if (pick == null) return const SizedBox.shrink();

    final tokens = context.tokens;
    final previousEntry = previousPrs == null
        ? null
        : _entryFor(previousPrs!, pick.category);
    final deltaLine = prDelta(pick.category, pick.current, previousEntry);
    final darker = Color.lerp(tokens.success, tokens.ink, 0.18) ?? tokens.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.success, darker],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.onSuccess.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star, color: tokens.onSuccess, size: 22),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headline(pick),
                  style: context.typo.body.copyWith(
                    color: tokens.onSuccess,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (deltaLine != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    deltaLine,
                    style: context.typo.bodySmall.copyWith(
                      color: tokens.onSuccess.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _headline(PrPick pick) {
    switch (pick.category) {
      case PrCategory.fastest1k:
        return 'New 1k PR · ${_dur(pick.current.duration)}';
      case PrCategory.fastest5k:
        return 'New 5k PR · ${_dur(pick.current.duration)}';
      case PrCategory.fastest10k:
        return 'New 10k PR · ${_dur(pick.current.duration)}';
      case PrCategory.longestDistance:
        return 'Longest run · ${pick.current.distanceKm.toStringAsFixed(1)} km';
      case PrCategory.longestDuration:
        return 'Longest time · ${_dur(pick.current.duration)}';
    }
  }

  static String _dur(Duration? d) {
    if (d == null) return '—';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static PrEntry? _entryFor(Prs prs, PrCategory cat) {
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
}
