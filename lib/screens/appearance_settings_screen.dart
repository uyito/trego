import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shared/theme/appearance_controller.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/trego_app_bar.dart';
import '../widgets/core/trego_scaffold.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppearanceController>();
    return TregoScaffold(
      appBar: const TregoAppBar(title: 'Appearance'),
      body: ListView(
        children: [
          for (final entry in const {
            ThemeMode.system: ('System', 'Match your device setting'),
            ThemeMode.light: ('Light', 'Always light mode'),
            ThemeMode.dark: ('Dark', 'Always dark mode'),
          }.entries)
            _Row(
              title: entry.value.$1,
              subtitle: entry.value.$2,
              selected: controller.mode == entry.key,
              onTap: () => controller.setMode(entry.key),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _Row({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.lg),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: tokens.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.typo.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.typo.bodySmall.copyWith(color: tokens.inkMuted)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: tokens.brand),
          ],
        ),
      ),
    );
  }
}
