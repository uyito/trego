import 'package:flutter/material.dart';
import '../screens/feed_placeholder_screen.dart';
import '../screens/home_screen.dart';
import '../screens/plan_placeholder_screen.dart';
import '../screens/record_placeholder_screen.dart';
import '../screens/you_screen.dart';
import '../shared/theme/context_tokens.dart';
import 'tab_config.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  TregoTab _current = TregoTab.home;

  void _switchTab(TregoTab tab) => setState(() => _current = tab);

  void _openRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const RecordPlaceholderScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final index = switch (_current) {
      TregoTab.home => 0,
      TregoTab.plan => 1,
      TregoTab.feed => 2,
      TregoTab.you => 3,
    };

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: IndexedStack(
        index: index,
        children: [
          HomeScreen(onSwitchTab: _switchTab),
          const PlanPlaceholderScreen(),
          const FeedPlaceholderScreen(),
          const YouScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _current,
        onSelect: _switchTab,
        onRecord: _openRecord,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final TregoTab current;
  final ValueChanged<TregoTab> onSelect;
  final VoidCallback onRecord;

  const _BottomNav({required this.current, required this.onSelect, required this.onRecord});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceSunken,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              Expanded(child: _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home, selected: current == TregoTab.home, onTap: () => onSelect(TregoTab.home))),
              Expanded(child: _NavItem(label: 'Plan', icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, selected: current == TregoTab.plan, onTap: () => onSelect(TregoTab.plan))),
              _RecordButton(onTap: onRecord),
              Expanded(child: _NavItem(label: 'Feed', icon: Icons.people_outline, activeIcon: Icons.people, selected: current == TregoTab.feed, onTap: () => onSelect(TregoTab.feed))),
              Expanded(child: _NavItem(label: 'You', icon: Icons.person_outline, activeIcon: Icons.person, selected: current == TregoTab.you, onTap: () => onSelect(TregoTab.you))),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = selected ? tokens.brand : tokens.inkMuted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? activeIcon : icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.typo.label.copyWith(
              color: color,
              letterSpacing: 0,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RecordButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      width: 80,
      child: Center(
        child: Semantics(
          label: 'Start recording a workout',
          button: true,
          child: InkWell(
            key: const Key('shell-record-button'),
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: tokens.brand,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: tokens.brand.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(Icons.fiber_manual_record, color: tokens.onBrand, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
