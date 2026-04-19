import 'package:flutter/material.dart';
import '../../models/day_status.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';

class WeekBar extends StatelessWidget {
  final List<DayStatus> days;
  final int? streakCount;

  WeekBar({
    super.key,
    required this.days,
    this.streakCount,
  }) : assert(days.length == 7, 'WeekBar requires exactly 7 days (Mon–Sun)');

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final completed = days.where((d) => d == DayStatus.done).length;
    final planned = days.where((d) => d != DayStatus.future).length;

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(Radii.compactCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed of $planned sessions',
                style: context.typo.titleSmall,
              ),
              if (streakCount != null)
                Text(
                  '🔥 $streakCount day streak',
                  style: context.typo.bodySmall.copyWith(color: tokens.success),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _Dot(label: _labels[i], status: days[i]),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final String label;
  final DayStatus status;

  const _Dot({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    Color bg;
    Color? fg;
    Border? border;
    Widget? child;

    switch (status) {
      case DayStatus.done:
        bg = tokens.success;
        fg = tokens.onSuccess;
        child = const Icon(Icons.check, size: 14);
        break;
      case DayStatus.today:
        bg = tokens.brand;
        fg = tokens.onBrand;
        border = Border.all(color: tokens.brand, width: 2);
        break;
      case DayStatus.future:
        bg = tokens.border;
        fg = tokens.inkFaint;
        break;
      case DayStatus.missed:
        bg = Colors.transparent;
        fg = tokens.danger;
        border = Border.all(color: tokens.danger, width: 1.5);
        break;
    }

    return Column(
      children: [
        Text(label, style: context.typo.bodySmall.copyWith(color: tokens.inkMuted)),
        const SizedBox(height: Space.xs),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: border,
          ),
          alignment: Alignment.center,
          child: DefaultTextStyle(
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
            child: IconTheme(
              data: IconThemeData(color: fg),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
