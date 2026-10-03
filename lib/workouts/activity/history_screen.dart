import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../../widgets/core/trego_app_bar.dart';
import '../../widgets/core/trego_scaffold.dart';
import 'activity.dart';
import 'activity_library.dart';
import 'activity_models.dart';
import 'workout_service.dart';

/// Lists the user's logged activity sessions, newest first as returned by
/// the backend.
class WorkoutHistoryScreen extends StatefulWidget {
  /// Injectable for tests; defaults to a real [WorkoutService].
  final WorkoutService? service;

  const WorkoutHistoryScreen({super.key, this.service});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  late final WorkoutService _service = widget.service ?? WorkoutService();
  List<ActivitySession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final sessions = await _service.getHistory();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  String _name(ActivitySession s) =>
      activityById(s.activityType)?.name ?? s.activityType;

  String _metric(ActivitySession s) {
    if (s.logKind == ActivityLogKind.distanceCardio.name && s.distance != null) {
      return '${_num(s.distance!)} km';
    }
    if (s.logKind == ActivityLogKind.strength.name) {
      var volume = 0.0;
      for (final e in s.exercises) {
        for (final set in e.sets) {
          volume += (set.reps ?? 0) * (set.weight ?? 0);
        }
      }
      if (volume > 0) return '${_num(volume)} kg';
      return s.duration != null ? '${s.duration} min' : '';
    }
    return s.duration != null ? '${s.duration} min' : '';
  }

  String _date(ActivitySession s) {
    final d = s.createdAt?.toLocal();
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _num(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return TregoScaffold(
      appBar: const TregoAppBar(title: 'History'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final tokens = context.tokens;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64, color: tokens.inkMuted),
            const SizedBox(height: Space.lg),
            Text('No workouts logged yet', style: context.typo.title),
            const SizedBox(height: Space.xs),
            Text(
              'Log an activity and it will show up here',
              style: context.typo.body.copyWith(color: tokens.inkMuted),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _sessions.length,
      itemBuilder: (context, i) => _buildRow(_sessions[i]),
    );
  }

  Widget _buildRow(ActivitySession s) {
    final tokens = context.tokens;
    final metric = _metric(s);
    final date = _date(s);
    return Card(
      color: tokens.surface,
      margin: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.standardCard),
        side: BorderSide(color: tokens.border),
      ),
      child: ListTile(
        title: Text(_name(s), style: context.typo.titleSmall),
        subtitle: (s.sessionName != null || date.isNotEmpty)
            ? Text(
                [if (s.sessionName != null) s.sessionName!, if (date.isNotEmpty) date]
                    .join(' · '),
                style: context.typo.bodySmall.copyWith(color: tokens.inkMuted))
            : null,
        trailing: metric.isEmpty ? null : Text(metric, style: context.typo.titleSmall),
        onTap: () {}, // v1: detail view not wired yet.
      ),
    );
  }
}
