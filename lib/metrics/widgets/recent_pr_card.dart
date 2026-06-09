import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../metrics_helpers.dart';
import '../metrics_models.dart';

/// Small celebration card shown on Home when any PR was set in the last
/// 7 days. Renders nothing when there's no qualifying PR.
class RecentPrCard extends StatelessWidget {
  final Prs? prs;
  final DateTime now;

  const RecentPrCard({super.key, required this.prs, required this.now});

  @override
  Widget build(BuildContext context) {
    final pick = pickRecentPr(prs, now);
    if (pick == null) return const SizedBox.shrink();

    final tokens = context.tokens;
    final daysAgo = now.difference(pick.current.runStartTime).inDays;
    final daysLabel = daysAgo <= 0 ? 'Today' : (daysAgo == 1 ? 'Yesterday' : '$daysAgo days ago');

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, 0),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border),
          borderRadius: BorderRadius.circular(Radii.compactCard),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tokens.success,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.star, color: tokens.onSuccess, size: 20),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _headline(pick),
                    style: context.typo.body.copyWith(
                      color: tokens.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    daysLabel,
                    style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _headline(PrPick pick) {
    switch (pick.category) {
      case PrCategory.fastest1k:
        return 'New 1k PR · ${_fmtDuration(pick.current.duration)}';
      case PrCategory.fastest5k:
        return 'New 5k PR · ${_fmtDuration(pick.current.duration)}';
      case PrCategory.fastest10k:
        return 'New 10k PR · ${_fmtDuration(pick.current.duration)}';
      case PrCategory.longestDistance:
        return 'Longest run · ${pick.current.distanceKm.toStringAsFixed(1)} km';
      case PrCategory.longestDuration:
        return 'Longest time · ${_fmtDuration(pick.current.duration)}';
    }
  }

  static String _fmtDuration(Duration? d) {
    if (d == null) return '—';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
