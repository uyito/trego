import 'package:flutter/material.dart';

import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../../widgets/core/trego_app_bar.dart';
import '../../widgets/core/trego_button.dart';
import '../../widgets/core/trego_scaffold.dart';
import 'activity.dart';
import 'activity_models.dart';
import 'widgets/cardio_form.dart';
import 'widgets/duration_form.dart';
import 'widgets/sport_form.dart';
import 'widgets/strength_form.dart';
import 'workout_service.dart';

/// Routes to the form matching [Activity.logKind] and owns Save.
class LogActivityScreen extends StatefulWidget {
  final Activity activity;
  final WorkoutService? service;

  const LogActivityScreen({super.key, required this.activity, this.service});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  late final WorkoutService _service = widget.service ?? WorkoutService();
  late ActivitySession _session = ActivitySession(
    activityType: widget.activity.id,
    logKind: widget.activity.logKind.name,
    exercises: <ExerciseLog>[],
  );
  bool _saving = false;

  Widget _form() {
    final a = widget.activity;
    void onChanged(ActivitySession s) => _session = s;
    switch (a.logKind) {
      case ActivityLogKind.strength:
        return StrengthForm(activity: a, onChanged: onChanged);
      case ActivityLogKind.distanceCardio:
        return CardioForm(activity: a, onChanged: onChanged);
      case ActivityLogKind.sport:
        return SportForm(activity: a, onChanged: onChanged);
      case ActivityLogKind.duration:
        return DurationForm(activity: a, onChanged: onChanged);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final a = widget.activity;
    final s = _session
      ..activityType = a.id
      ..logKind = a.logKind.name;
    final saved = await _service.logSession(s);
    if (!mounted) return;
    setState(() => _saving = false);
    final messenger = ScaffoldMessenger.of(context);
    if (saved != null) {
      Navigator.pop(context);
      messenger.showSnackBar(
          SnackBar(content: Text('${a.name} logged')));
    } else {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not save activity. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TregoScaffold(
      appBar: TregoAppBar(title: widget.activity.name),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.lg),
        child: _form(),
      ),
      bottomNav: Container(
        color: tokens.surfaceSunken,
        padding: const EdgeInsets.all(Space.lg),
        child: SafeArea(
          top: false,
          child: TregoButton(
            key: const Key('save-activity'),
            label: 'Save',
            size: TregoButtonSize.lg,
            fullWidth: true,
            loading: _saving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
