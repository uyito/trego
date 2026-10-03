import 'package:flutter/material.dart';

import '../../../shared/theme/context_tokens.dart';
import '../../../shared/theme/trego_tokens.dart';
import '../activity.dart';
import '../activity_models.dart';
import 'activity_field.dart';

/// Sports: duration + perceived exertion (RPE 1-10) + notes.
class SportForm extends StatefulWidget {
  final Activity activity;
  final ValueChanged<ActivitySession> onChanged;

  const SportForm({super.key, required this.activity, required this.onChanged});

  @override
  State<SportForm> createState() => _SportFormState();
}

class _SportFormState extends State<SportForm> {
  final _duration = TextEditingController();
  final _notes = TextEditingController();
  double _rpe = 5;

  @override
  void initState() {
    super.initState();
    // Emit once so the default RPE is part of the session even if untouched.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emit();
    });
  }

  @override
  void dispose() {
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _emit() {
    final a = widget.activity;
    final notes = _notes.text.trim();
    widget.onChanged(ActivitySession(
      activityType: a.id,
      logKind: a.logKind.name,
      duration: parseIntField(_duration.text),
      perceivedExertion: _rpe.round(),
      notes: notes.isEmpty ? null : notes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivityField(
          key: const Key('duration-field'),
          label: 'Duration (min)',
          controller: _duration,
          keyboardType: TextInputType.number,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: Space.lg),
        Text('Perceived exertion: ${_rpe.round()} / 10', style: typo.label),
        Slider(
          key: const Key('rpe-slider'),
          value: _rpe,
          min: 1,
          max: 10,
          divisions: 9,
          label: _rpe.round().toString(),
          activeColor: tokens.brand,
          inactiveColor: tokens.border,
          onChanged: (v) {
            setState(() => _rpe = v);
            _emit();
          },
        ),
        const SizedBox(height: Space.md),
        ActivityField(
          key: const Key('notes-field'),
          label: 'Notes',
          controller: _notes,
          maxLines: 3,
          onChanged: (_) => _emit(),
        ),
      ],
    );
  }
}
