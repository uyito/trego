import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../achievements/achievements_screen.dart';
import '../metrics/metrics_models.dart';
import '../metrics/metrics_provider.dart';
import '../providers/app_state_provider.dart';
import '../shared/notification_settings_screen.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/trego_app_bar.dart';
import '../widgets/core/trego_avatar.dart';
import '../widgets/core/trego_scaffold.dart';
import 'appearance_settings_screen.dart';
import 'recording_settings_screen.dart';
import 'username_edit_screen.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppStateProvider>();
    final metrics = context.watch<MetricsProvider>();
    final displayName = (auth.user?['displayName'] as String?)
        ?? (auth.user?['email'] as String?)
        ?? 'You';
    final username = auth.user?['username'] as String?;

    return TregoScaffold(
      appBar: const TregoAppBar(title: 'You'),
      body: ListView(
        children: [
          _ProfileHeader(
            name: displayName,
            username: username,
            snapshot: metrics.snapshot,
          ),
          const _SectionLabel(label: 'Activity'),
          _Row(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            onTap: () => _push(context, const AchievementsScreen()),
          ),
          const _SectionLabel(label: 'Account'),
          _Row(
            icon: Icons.alternate_email,
            title: 'Username',
            onTap: () => _push(
              context,
              UsernameEditScreen(currentUsername: username),
            ),
          ),
          const _SectionLabel(label: 'Preferences'),
          _Row(icon: Icons.palette_outlined, title: 'Appearance', onTap: () => _push(context, const AppearanceSettingsScreen())),
          _Row(icon: Icons.directions_run, title: 'Recording', onTap: () => _push(context, const RecordingSettingsScreen())),
          _Row(icon: Icons.notifications_none, title: 'Notifications', onTap: () => _push(context, const NotificationSettingsScreen())),
          const SizedBox(height: Space.xl),
          _Row(icon: Icons.logout, title: 'Sign out', destructive: true, onTap: () => auth.signOut()),
          const SizedBox(height: Space.xxl),
        ],
      ),
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String? username;
  final MetricsSnapshot? snapshot;

  const _ProfileHeader({required this.name, required this.username, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TregoAvatar(name: name, size: TregoAvatarSize.lg),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: context.typo.title),
                    if (username != null)
                      Text('@$username', style: context.typo.bodySmall.copyWith(color: tokens.inkMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          _StatRow(snapshot: snapshot),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final MetricsSnapshot? snapshot;
  const _StatRow({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final totalRuns = snapshot?.totals.totalRuns;
    final thisWeekKm = snapshot?.thisWeek.totalKm;
    final streakDays = snapshot?.thisWeek.streakDays;

    return Row(
      children: [
        Expanded(child: _StatTile(label: 'Runs', value: totalRuns?.toString() ?? '—')),
        Expanded(child: _StatTile(label: 'This Week', value: thisWeekKm != null ? '${thisWeekKm.toStringAsFixed(1)} km' : '—')),
        Expanded(child: _StatTile(label: 'Streak', value: streakDays != null ? '$streakDays d' : '—')),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      children: [
        Text(value, style: context.typo.stat),
        const SizedBox(height: Space.xs),
        Text(label.toUpperCase(), style: context.typo.label.copyWith(color: tokens.inkMuted)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.xl, Space.lg, Space.sm),
      child: Text(
        label.toUpperCase(),
        style: context.typo.label.copyWith(color: context.tokens.inkMuted),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = destructive ? tokens.danger : tokens.ink;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.border))),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: Space.md),
            Expanded(child: Text(title, style: context.typo.titleSmall.copyWith(color: color))),
            Icon(Icons.chevron_right, size: 18, color: tokens.inkMuted),
          ],
        ),
      ),
    );
  }
}
