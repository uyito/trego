import 'package:flutter/material.dart';

import '../../../shared/theme/context_tokens.dart';
import '../../../shared/theme/trego_tokens.dart';
import '../../../widgets/core/trego_button.dart';
import '../activity.dart';
import '../activity_models.dart';
import 'activity_field.dart';
import 'rest_timer.dart';

class _ExerciseEntry {
  final ExerciseLog log;
  final reps = TextEditingController();
  final weight = TextEditingController();
  _ExerciseEntry(this.log);

  void dispose() {
    reps.dispose();
    weight.dispose();
  }
}

/// Strength: free-text exercises, each with an add-set row and rest timer.
class StrengthForm extends StatefulWidget {
  final Activity activity;
  final ValueChanged<ActivitySession> onChanged;

  const StrengthForm({super.key, required this.activity, required this.onChanged});

  @override
  State<StrengthForm> createState() => _StrengthFormState();
}

class _StrengthFormState extends State<StrengthForm> {
  final _name = TextEditingController();
  final _entries = <_ExerciseEntry>[];
  int? _restIndex;
  int _restRun = 0;

  @override
  void dispose() {
    _name.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final a = widget.activity;
    widget.onChanged(ActivitySession(
      activityType: a.id,
      logKind: a.logKind.name,
      exercises: [for (final e in _entries) e.log],
    ));
  }

  void _addExercise() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _entries.add(_ExerciseEntry(ExerciseLog(
        exerciseId: name.toLowerCase().replaceAll(RegExp(r'\s+'), '-'),
        name: name,
        sets: <ExerciseSet>[],
      )));
      _name.clear();
    });
    _emit();
  }

  void _addSet(int i) {
    final e = _entries[i];
    final reps = parseIntField(e.reps.text);
    if (reps == null) return;
    setState(() {
      e.log.sets.add(ExerciseSet(
        setNumber: e.log.sets.length + 1,
        reps: reps,
        weight: parseDoubleField(e.weight.text),
      ));
      e.reps.clear();
      _restIndex = i;
      _restRun++;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ActivityField(
                key: const Key('exercise-name-field'),
                label: 'Exercise',
                controller: _name,
              ),
            ),
            const SizedBox(width: Space.sm),
            TregoButton(
              key: const Key('add-exercise'),
              label: 'Add',
              onPressed: _addExercise,
            ),
          ],
        ),
        for (var i = 0; i < _entries.length; i++) ...[
          const SizedBox(height: Space.lg),
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: tokens.surface,
              border: Border.all(color: tokens.border),
              borderRadius: BorderRadius.circular(Radii.compactCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_entries[i].log.name, style: typo.titleSmall),
                const SizedBox(height: Space.sm),
                for (final s in _entries[i].log.sets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.xs),
                    child: Text(
                      'Set ${s.setNumber}: ${s.reps} reps'
                      '${s.weight != null ? ' @ ${s.weight} kg' : ''}',
                      style: typo.bodySmall.copyWith(color: tokens.inkMuted),
                    ),
                  ),
                const SizedBox(height: Space.sm),
                Row(
                  children: [
                    Expanded(
                      child: ActivityField(
                        key: Key('reps-field-$i'),
                        label: 'Reps',
                        controller: _entries[i].reps,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: ActivityField(
                        key: Key('weight-field-$i'),
                        label: 'Weight (kg)',
                        controller: _entries[i].weight,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    TregoButton(
                      key: Key('add-set-$i'),
                      label: 'Add set',
                      variant: TregoButtonVariant.secondary,
                      onPressed: () => _addSet(i),
                    ),
                  ],
                ),
                if (_restIndex == i) ...[
                  const SizedBox(height: Space.md),
                  RestTimer(
                    key: ValueKey('rest-$_restRun'),
                    seconds: 90,
                    onDone: () {
                      if (mounted) setState(() => _restIndex = null);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
