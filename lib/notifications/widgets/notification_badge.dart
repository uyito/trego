import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';

/// A small count badge to overlay on a notifications icon. Renders nothing when
/// [count] is 0; shows "9+" above 9.
class NotificationBadge extends StatelessWidget {
  final int count;

  const NotificationBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final tokens = context.tokens;
    final label = count > 9 ? '9+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: tokens.brand,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tokens.surface, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: context.typo.label.copyWith(
          color: tokens.onBrand,
          fontSize: 10,
          height: 1.1,
        ),
      ),
    );
  }
}
