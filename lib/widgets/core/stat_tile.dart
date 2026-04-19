import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';

enum StatTone { neutral, success }

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final StatTone tone;
  final String? prefix;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.tone = StatTone.neutral,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final valueColor = tone == StatTone.success ? tokens.success : tokens.ink;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.md, horizontal: Space.sm),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(Radii.statTile),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${prefix ?? ''}$value',
            style: context.typo.stat.copyWith(color: valueColor),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: context.typo.label.copyWith(color: tokens.inkMuted),
          ),
        ],
      ),
    );
  }
}
