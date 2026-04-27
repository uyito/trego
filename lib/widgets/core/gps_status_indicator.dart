import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';

enum GpsStatus { acquiring, weak, ready }

class GpsStatusIndicator extends StatelessWidget {
  final GpsStatus status;
  final double? accuracyMeters;

  const GpsStatusIndicator({
    super.key,
    required this.status,
    this.accuracyMeters,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (color, label) = switch (status) {
      GpsStatus.acquiring => (tokens.inkMuted, 'Acquiring GPS…'),
      GpsStatus.weak => (
          const Color(0xFFFFC107), // ALLOW-HEX: amber is not in the token palette; used only here
          'GPS — ±${accuracyMeters?.round() ?? 0} m',
        ),
      GpsStatus.ready => (
          tokens.success,
          'GPS — ±${accuracyMeters?.round() ?? 0} m',
        ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: status != GpsStatus.acquiring
                ? [BoxShadow(color: color, blurRadius: 4)]
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.typo.label.copyWith(color: color),
        ),
      ],
    );
  }
}
