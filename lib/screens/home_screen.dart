import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../metrics/metrics_provider.dart';
import '../metrics/widgets/recent_pr_card.dart';
import '../metrics/widgets/weekly_sparkline.dart';
import '../metrics/widgets/weekly_stat_strip.dart';
import '../navigation/tab_config.dart';
import '../providers/feed_provider.dart';
import '../providers/plan_provider.dart';
import '../shared/notification_settings_screen.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/activity_card.dart';
import '../widgets/core/section_head.dart';
import '../widgets/core/trego_app_bar.dart';
import '../widgets/core/trego_button.dart';
import '../widgets/core/trego_scaffold.dart';
import '../widgets/core/workout_hero_card.dart';

/// Home tab. Reference application of the design system.
/// Layout (top → bottom):
/// AppBar greeting → WorkoutHeroCard → metrics section (live) → friends list.
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
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
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
                    onSwitchTab?.call(TregoTab.plan);
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
            const _MetricsSection(),
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
        const SectionHead(label: 'This Week'),
        WeeklyStatStrip(metrics: snap.thisWeek),
        RecentPrCard(prs: snap.prs, now: DateTime.now()),
        const SizedBox(height: Space.sm),
        WeeklySparkline(history: snap.history),
      ],
    );
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
