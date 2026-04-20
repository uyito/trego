import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';

class SectionHead extends StatelessWidget {
  final String label;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  const SectionHead({
    super.key,
    required this.label,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, Space.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: context.typo.label.copyWith(color: tokens.inkMuted),
            ),
          ),
          if (trailingLabel != null)
            InkWell(
              onTap: onTrailingTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Text(
                  trailingLabel!,
                  style: context.typo.label.copyWith(
                    color: tokens.brand,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
