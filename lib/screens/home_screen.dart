import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/tab_config.dart';
import '../providers/feed_provider.dart';
import '../providers/plan_provider.dart';
import '../shared/notification_settings_screen.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/activity_card.dart';
import '../widgets/core/section_head.dart';
import '../widgets/core/stat_tile.dart';
import '../widgets/core/trego_app_bar.dart';
import '../widgets/core/trego_button.dart';
import '../widgets/core/trego_scaffold.dart';
import '../widgets/core/workout_hero_card.dart';
import 'record_placeholder_screen.dart';

/// Home tab. Reference application of the design system.
/// Layout (top → bottom):
/// AppBar greeting → WorkoutHeroCard → weekly stat strip → friends list.
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
      body: ListView(
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
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RecordPlaceholderScreen(), fullscreenDialog: true),
                  );
                }
              },
            ),
          ),
          const SectionHead(label: 'This Week'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.md),
            child: Row(
              children: [
                Expanded(child: StatTile(label: 'km', value: '—')),
                SizedBox(width: Space.sm),
                Expanded(child: StatTile(label: 'runs', value: '—')),
                SizedBox(width: Space.sm),
                Expanded(child: StatTile(label: 'streak', value: '—', prefix: '🔥 ', tone: StatTone.success)),
              ],
            ),
          ),
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
    );
  }
}
