import 'package:flutter/material.dart';

/// A small count badge to overlay on a notifications icon. Renders nothing when
/// [count] is 0; shows "9+" above 9.
class NotificationBadge extends StatelessWidget {
  final int count;

  const NotificationBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final label = count > 9 ? '9+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE31E24),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}
