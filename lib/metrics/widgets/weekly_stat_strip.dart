import 'package:flutter/material.dart';
import '../../shared/theme/trego_tokens.dart';
import '../../widgets/core/stat_tile.dart';
import '../metrics_models.dart';

/// Horizontal row of 4 tiles summarising a week: km / runs / time / avg pace.
/// Zero values render as an em-dash.
class WeeklyStatStrip extends StatelessWidget {
  final WeeklyMetrics metrics;

  const WeeklyStatStrip({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: Row(
        children: [
          Expanded(child: StatTile(label: 'km', value: _km(metrics.totalKm))),
          const SizedBox(width: Space.sm),
          Expanded(child: StatTile(label: 'runs', value: _runs(metrics.totalRuns))),
          const SizedBox(width: Space.sm),
          Expanded(child: StatTile(label: 'time', value: _time(metrics.totalTime))),
          const SizedBox(width: Space.sm),
          Expanded(child: StatTile(label: '/km', value: _pace(metrics.avgPacePerKm))),
        ],
      ),
    );
  }

  static String _km(double v) => v <= 0 ? '—' : v.toStringAsFixed(1);
  static String _runs(int v) => v <= 0 ? '—' : '$v';

  static String _time(Duration d) {
    if (d == Duration.zero) return '—';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String _pace(Duration d) {
    if (d == Duration.zero) return '—';
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
