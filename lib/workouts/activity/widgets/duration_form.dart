import 'package:flutter/material.dart';

import '../../../shared/theme/trego_tokens.dart';
import '../activity.dart';
import '../activity_models.dart';
import 'activity_field.dart';

/// Duration-only activities (mind-body etc.): duration + notes.
class DurationForm extends StatefulWidget {
  final Activity activity;
  final ValueChanged<ActivitySession> onChanged;

  const DurationForm({super.key, required this.activity, required this.onChanged});

  @override
  State<DurationForm> createState() => _DurationFormState();
}

class _DurationFormState extends State<DurationForm> {
  final _duration = TextEditingController();
  final _notes = TextEditingController();

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
      notes: notes.isEmpty ? null : notes,
    ));
  }

  @override
  Widget build(BuildContext context) {
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
