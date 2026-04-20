import 'package:flutter/material.dart';
import '../../models/activity.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import 'trego_avatar.dart';

enum ActivityCardDensity { standard, compact }

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final ActivityCardDensity density;
  final VoidCallback? onKudos;
  final VoidCallback? onComment;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.density = ActivityCardDensity.standard,
    this.onKudos,
    this.onComment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return density == ActivityCardDensity.compact ? _buildCompact(context) : _buildStandard(context);
  }

  Widget _buildStandard(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(Radii.standardCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.standardCard),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: tokens.border),
            borderRadius: BorderRadius.circular(Radii.standardCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Row(
                  children: [
                    TregoAvatar(name: activity.userName),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activity.userName, style: typo.titleSmall),
                          const SizedBox(height: 1),
                          Text(
                            [activity.timestampLabel, if (activity.locationLabel != null) activity.locationLabel].join(' · '),
                            style: typo.bodySmall.copyWith(color: tokens.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.more_horiz, color: tokens.inkMuted, size: 20),
                  ],
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
                child: Text(activity.title, style: typo.titleSmall),
              ),
              // Map placeholder
              Container(
                key: const Key('activity-map-placeholder'),
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A2F), Color(0xFF0E2418)], // ALLOW-HEX: placeholder map gradient until google_maps_flutter integration
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 180,
                  height: 2,
                  color: tokens.brand,
                ),
              ),
              // Stats row
              Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.border))),
                padding: const EdgeInsets.symmetric(vertical: Space.md),
                child: Row(
                  children: [
                    Expanded(child: _stat(context, activity.distanceKm.toStringAsFixed(1), 'km')),
                    _divider(tokens),
                    Expanded(child: _stat(context, activity.pacePerKm, '/km pace')),
                    _divider(tokens),
                    Expanded(child: _stat(context, activity.durationLabel, 'time')),
                  ],
                ),
              ),
              // Actions
              Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: tokens.border))),
                padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
                child: Row(
                  children: [
                    InkWell(
                      key: const Key('activity-kudos-button'),
                      onTap: onKudos,
                      child: Padding(
                        // vertical: Space.sm brings the row to ~32pt; combined
                        // with the action-bar's own Space.sm vertical padding
                        // the total target area is 48pt (HIG minimum: 44pt).
                        padding: const EdgeInsets.symmetric(vertical: Space.sm),
                        child: Row(children: [
                          Icon(
                            activity.userHasKudosed ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: activity.userHasKudosed ? tokens.brand : tokens.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${activity.kudosCount}',
                            style: typo.bodySmall.copyWith(
                              color: activity.userHasKudosed ? tokens.brand : tokens.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(width: Space.lg),
                    InkWell(
                      key: const Key('activity-comment-button'),
                      onTap: onComment,
                      child: Padding(
                        // Match kudos-button tap-target; HIG minimum is 44pt.
                        padding: const EdgeInsets.symmetric(vertical: Space.sm),
                        child: Row(children: [
                          Icon(Icons.chat_bubble_outline, size: 16, color: tokens.inkMuted),
                          const SizedBox(width: 4),
                          Text('${activity.commentCount}', style: typo.bodySmall.copyWith(color: tokens.inkMuted)),
                        ]),
                      ),
                    ),
                    const Spacer(),
                    Text('Share', style: typo.bodySmall.copyWith(color: tokens.inkMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(Radii.compactCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.compactCard),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: tokens.border),
            borderRadius: BorderRadius.circular(Radii.compactCard),
          ),
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              TregoAvatar(name: activity.userName, size: TregoAvatarSize.md),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.userName, style: typo.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${activity.distanceKm.toStringAsFixed(1)} km · ${activity.durationLabel} · ${activity.timestampLabel}',
                      style: typo.bodySmall.copyWith(color: tokens.inkMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${activity.kudosCount}',
                  style: typo.bodySmall.copyWith(color: tokens.onBrand, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final tokens = context.tokens;
    return Column(
      children: [
        Text(value, style: context.typo.stat.copyWith(fontSize: 15)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: context.typo.label.copyWith(color: tokens.inkMuted)),
      ],
    );
  }

  Widget _divider(TregoTokens tokens) =>
      Container(width: 1, height: 32, color: tokens.border);
}
