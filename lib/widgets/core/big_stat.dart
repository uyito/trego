import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';

enum BigStatSize { xl, l, m }

class BigStat extends StatelessWidget {
  final String value;
  final String label;
  final BigStatSize size;
  final Color? color;

  const BigStat({
    super.key,
    required this.value,
    required this.label,
    this.size = BigStatSize.m,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;

    final (valueStyle, labelStyle) = switch (size) {
      BigStatSize.xl => (
          typo.statLarge.copyWith(color: color ?? tokens.ink),
          typo.label.copyWith(color: tokens.inkMuted),
        ),
      BigStatSize.l => (
          typo.stat.copyWith(fontSize: 44, color: color ?? tokens.ink),
          typo.label.copyWith(color: tokens.inkMuted),
        ),
      BigStatSize.m => (
          typo.stat.copyWith(color: color ?? tokens.ink),
          typo.label.copyWith(color: tokens.inkMuted),
        ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: valueStyle),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: labelStyle),
      ],
    );
  }
}
