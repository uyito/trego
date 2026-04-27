import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../achievements/achievements_screen.dart';
import '../personalization/for_you_hub.dart';
import '../providers/app_state_provider.dart';
import '../recipes/recipe_screen.dart';
import '../shared/notification_settings_screen.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../social/social_hub.dart';
import '../tdee/tdee_screen.dart';
import '../tracker/tracker_dashboard_screen.dart';
import '../widgets/core/trego_app_bar.dart';
import '../widgets/core/trego_avatar.dart';
import '../widgets/core/trego_scaffold.dart';
import 'appearance_settings_screen.dart';
import 'recording_settings_screen.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppStateProvider>();
    final displayName = (auth.user?['displayName'] as String?)
        ?? (auth.user?['email'] as String?)
        ?? 'You';

    return TregoScaffold(
      appBar: const TregoAppBar(title: 'You'),
      body: ListView(
        children: [
          _Header(name: displayName),
          const _SectionLabel(label: 'Tools'),
          _Row(icon: Icons.restaurant_menu, title: 'Recipes', onTap: () => _push(context, const RecipeScreen())),
          _Row(icon: Icons.calculate_outlined, title: 'TDEE Calculator', onTap: () => _push(context, const TdeeScreen())),
          _Row(icon: Icons.auto_awesome, title: 'For You', onTap: () => _push(context, const ForYouHub())),
          _Row(icon: Icons.timeline, title: 'Run History', onTap: () => _push(context, const TrackerDashboardScreen())),
          const _SectionLabel(label: 'Activity'),
          _Row(icon: Icons.emoji_events_outlined, title: 'Achievements', onTap: () => _push(context, const AchievementsScreen())),
          _Row(icon: Icons.people_outline, title: 'Social (legacy)', onTap: () => _push(context, const SocialHub())),
          const _SectionLabel(label: 'Settings'),
          _Row(icon: Icons.notifications_none, title: 'Notifications', onTap: () => _push(context, const NotificationSettingsScreen())),
          _Row(icon: Icons.palette_outlined, title: 'Appearance', onTap: () => _push(context, const AppearanceSettingsScreen())),
          _Row(icon: Icons.directions_run, title: 'Recording', onTap: () => _push(context, const RecordingSettingsScreen())),
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

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Row(
        children: [
          TregoAvatar(name: name, size: TregoAvatarSize.lg),
          const SizedBox(width: Space.md),
          Expanded(child: Text(name, style: context.typo.title)),
        ],
      ),
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
