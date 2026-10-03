import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../../widgets/core/trego_app_bar.dart';
import '../../widgets/core/trego_scaffold.dart';
import 'activity_library.dart';
import 'workout_service.dart';

/// Shows the user's personal records: cardio bests per activity and
/// strength bests per exercise.
class PRsScreen extends StatefulWidget {
  /// Injectable for tests; defaults to a real [WorkoutService].
  final WorkoutService? service;

  const PRsScreen({super.key, this.service});

  @override
  State<PRsScreen> createState() => _PRsScreenState();
}

class _PRsScreenState extends State<PRsScreen> {
  late final WorkoutService _service = widget.service ?? WorkoutService();
  List<Map<String, dynamic>> _prs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final prs = await _service.getPRs();
    if (!mounted) return;
    setState(() {
      _prs = prs;
      _isLoading = false;
    });
  }

  static const _dash = '—';

  double? _asDouble(dynamic v) => v is num ? v.toDouble() : null;

  String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  String _withUnit(dynamic v, String unit) {
    final d = _asDouble(v);
    return d == null ? _dash : '${_num(d)} $unit';
  }

  /// Pace is seconds per km; rendered as m:ss /km.
  String _pace(dynamic v) {
    final d = _asDouble(v);
    if (d == null || d <= 0) return _dash;
    final total = d.round();
    final m = total ~/ 60;
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s /km';
  }

  @override
  Widget build(BuildContext context) {
    return TregoScaffold(
      appBar: const TregoAppBar(title: 'Personal Records'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final tokens = context.tokens;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_prs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: tokens.inkMuted),
            const SizedBox(height: Space.lg),
            Text('No personal records yet', style: context.typo.title),
            const SizedBox(height: Space.xs),
            Text(
              'Log activities to set your first records',
              style: context.typo.body.copyWith(color: tokens.inkMuted),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _prs.length,
      itemBuilder: (context, i) {
        final pr = _prs[i];
        if (pr['activityType'] != null) return _cardioCard(pr);
        if (pr['exerciseId'] != null) return _strengthCard(pr);
        return const SizedBox.shrink();
      },
    );
  }

  Widget _cardioCard(Map<String, dynamic> pr) {
    final type = pr['activityType'].toString();
    return _card(
      activityById(type)?.name ?? type,
      [
        ('Best distance', _withUnit(pr['bestDistance'], 'km')),
        ('Best pace', _pace(pr['bestPace'])),
        ('Best elevation', _withUnit(pr['bestElevation'], 'm')),
      ],
    );
  }

  Widget _strengthCard(Map<String, dynamic> pr) {
    final name = pr['name']?.toString() ?? pr['exerciseId'].toString();
    return _card(
      name,
      [
        ('Heaviest weight', _withUnit(pr['heaviestWeight'], 'kg')),
        ('Est. 1RM', _withUnit(pr['estimatedOneRepMax'], 'kg')),
      ],
    );
  }

  Widget _card(String title, List<(String, String)> stats) {
    final tokens = context.tokens;
    return Card(
      color: tokens.surface,
      margin: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.standardCard),
        side: BorderSide(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.typo.titleSmall),
            const SizedBox(height: Space.sm),
            for (final (label, value) in stats)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: context.typo.bodySmall.copyWith(color: tokens.inkMuted)),
                    Text(value, style: context.typo.titleSmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
