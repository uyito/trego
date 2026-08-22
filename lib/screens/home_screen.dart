import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../achievements/achievements_screen.dart';
import '../metrics/metrics_provider.dart';
import '../metrics/widgets/goal_edit_dialog.dart';
import '../metrics/widgets/goal_progress_card.dart';
import '../metrics/widgets/recent_pr_card.dart';
import '../metrics/widgets/weekly_sparkline.dart';
import '../metrics/widgets/weekly_stat_strip.dart';
import '../navigation/tab_config.dart';
import '../notifications/notifications_provider.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/widgets/notification_badge.dart';
import '../personalization/for_you_hub.dart';
import '../providers/feed_provider.dart';
import '../providers/plan_provider.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/activity_card.dart';
import '../widgets/core/section_head.dart';
import '../widgets/core/trego_app_bar.dart';
import '../widgets/core/trego_button.dart';
import '../widgets/core/trego_scaffold.dart';
import '../widgets/core/workout_hero_card.dart';
import '../workouts/workout_hub.dart';
import 'progress_screen.dart';

/// Home tab. Reference application of the design system.
/// Layout (top → bottom):
/// AppBar greeting → WorkoutHeroCard → quick links (For You / Training) →
/// metrics section (live) → Achievements preview → friends list.
class HomeScreen extends StatelessWidget {
  /// Optional callback to switch tabs. Wired by [AppShell].
  final ValueChanged<TregoTab>? onSwitchTab;

  const HomeScreen({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<PlanProvider>();
    final feed = context.watch<FeedProvider>();
    final today = plan.today();
    final summary = plan.progressSummary();
    final friends = feed.friendsRecent(limit: 3);
    final tokens = context.tokens;

    return TregoScaffold(
      appBar: TregoAppBar(
        greeting: 'Hello',
        subtitle: summary,
        trailing: [
          _NotificationsBell(
            unreadCount: context.watch<NotificationsProvider>().unreadCount,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<MetricsProvider>().refresh(maxAge: Duration.zero),
        child: ListView(
          // Required so RefreshIndicator works even when the list isn't
          // long enough to overflow the viewport.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: Space.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 0),
              child: WorkoutHeroCard(
                todayLabel: today?.todayLabel ?? 'Today',
                title: today?.title ?? 'No plan yet',
                metaLine: today?.metaLine ?? 'Quick-start a run from Record',
                ctaLabel: today == null ? 'Browse plans' : 'Start Workout',
                isEmpty: today == null,
                onStart: () {
                  if (today == null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WorkoutHub()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Start a run from the Record button in the bottom bar.'),
                      ),
                    );
                  }
                },
              ),
            ),
            const _QuickLinksRow(),
            const _MetricsSection(),
            SectionHead(
              label: 'Achievements',
              trailingLabel: 'See all →',
              onTrailingTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              ),
            ),
            const _AchievementsPreview(),
            SectionHead(
              label: 'Friends',
              trailingLabel: 'See all →',
              onTrailingTap: () => onSwitchTab?.call(TregoTab.feed),
            ),
            if (friends.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Container(
                  padding: const EdgeInsets.all(Space.xl),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    border: Border.all(color: tokens.border),
                    borderRadius: BorderRadius.circular(Radii.compactCard),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 32, color: tokens.inkMuted),
                      const SizedBox(height: Space.sm),
                      Text(
                        'Invite friends to see their runs',
                        style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
                      ),
                      const SizedBox(height: Space.md),
                      TregoButton(
                        label: 'Find friends',
                        variant: TregoButtonVariant.secondary,
                        onPressed: () => onSwitchTab?.call(TregoTab.feed),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.md),
                child: Column(
                  children: [
                    for (final a in friends) ...[
                      ActivityCard(activity: a, density: ActivityCardDensity.compact),
                      const SizedBox(height: Space.sm),
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

/// Live metrics block between the WorkoutHeroCard and the friends list.
/// Hidden entirely on the empty / null-and-no-error states; shows a skeleton
/// during the first ever fetch; otherwise renders strip + (optional) recent
/// PR card + 12-week sparkline.
class _MetricsSection extends StatelessWidget {
  const _MetricsSection();

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MetricsProvider>();
    final snap = mp.snapshot;

    // Loading skeleton (first fetch in flight, no cached data yet).
    if (snap == null && mp.loading) {
      return const _MetricsSkeleton();
    }
    // No data, not loading — hide entirely.
    if (snap == null) return const SizedBox.shrink();
    // Empty state — totalRuns == 0 — hide entirely; hero card has the CTA.
    if (snap.totals.totalRuns == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(
          label: 'This Week',
          trailingLabel: 'See all →',
          onTrailingTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProgressScreen()),
          ),
        ),
        WeeklyStatStrip(metrics: snap.thisWeek),
        RecentPrCard(prs: snap.prs, now: DateTime.now()),
        const SizedBox(height: Space.sm),
        WeeklySparkline(history: snap.history),
        GoalProgressCard(
          thisWeek: snap.thisWeek,
          goal: mp.goal,
          onEdit: () => _editGoal(context, mp),
        ),
      ],
    );
  }

  Future<void> _editGoal(BuildContext context, MetricsProvider mp) async {
    final result = await showGoalEditDialog(context, mp.goal);
    if (result == null) return;
    await mp.setGoal(targetKm: result.targetKm, targetRuns: result.targetRuns);
  }
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    Widget tile() => Container(
          height: 56,
          decoration: BoxDecoration(
            color: tokens.surfaceSunken,
            borderRadius: BorderRadius.circular(Radii.statTile),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHead(label: 'This Week'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          child: Row(
            children: [
              Expanded(child: tile()),
              const SizedBox(width: Space.sm),
              Expanded(child: tile()),
              const SizedBox(width: Space.sm),
              Expanded(child: tile()),
              const SizedBox(width: Space.sm),
              Expanded(child: tile()),
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: tokens.surfaceSunken,
              borderRadius: BorderRadius.circular(Radii.compactCard),
            ),
          ),
        ),
      ],
    );
  }
}

/// Row of two entry-point cards below the hero: the AI coach ("For You")
/// and the workout library ("Training").
class _QuickLinksRow extends StatelessWidget {
  const _QuickLinksRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickLinkCard(
              icon: Icons.auto_awesome,
              title: 'For You',
              subtitle: 'AI coaching & insights',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForYouHub()),
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: _QuickLinkCard(
              icon: Icons.fitness_center,
              title: 'Training',
              subtitle: 'Plans & exercises',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkoutHub()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(Radii.compactCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.compactCard),
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            border: Border.all(color: tokens.border),
            borderRadius: BorderRadius.circular(Radii.compactCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: tokens.brand),
              const SizedBox(height: Space.sm),
              Text(title, style: typo.titleSmall.copyWith(color: tokens.ink)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: typo.bodySmall.copyWith(color: tokens.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact horizontal strip of badge teasers; tapping any card (or the
/// "See all" trailing above it) opens the full [AchievementsScreen].
class _AchievementsPreview extends StatelessWidget {
  const _AchievementsPreview();

  static const _badges = [
    (Icons.local_fire_department, 'Streak'),
    (Icons.emoji_events, 'First 5K'),
    (Icons.bolt, 'Fast Pace'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.md),
        itemCount: _badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: Space.sm),
        itemBuilder: (context, i) {
          final (icon, label) = _badges[i];
          return Material(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(Radii.compactCard),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.compactCard),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              ),
              child: Container(
                width: 84,
                padding: const EdgeInsets.all(Space.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: tokens.border),
                  borderRadius: BorderRadius.circular(Radii.compactCard),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: tokens.brand),
                    const SizedBox(height: Space.xs),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typo.bodySmall.copyWith(color: tokens.ink),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// App-bar bell with an unread-count badge overlay.
class _NotificationsBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationsBell({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none),
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: NotificationBadge(count: unreadCount),
            ),
        ],
      ),
    );
  }
}
