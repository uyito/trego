import 'package:flutter/material.dart';

import '../../../shared/theme/context_tokens.dart';
import '../../../shared/theme/trego_tokens.dart';
import '../activity.dart';
import '../activity_models.dart';
import 'activity_field.dart';

const List<String> swimStrokes = [
  'Freestyle',
  'Backstroke',
  'Breaststroke',
  'Butterfly',
  'Mixed',
];

/// Distance cardio: distance, duration, optional elevation / stroke.
class CardioForm extends StatefulWidget {
  final Activity activity;
  final ValueChanged<ActivitySession> onChanged;

  const CardioForm({super.key, required this.activity, required this.onChanged});

  @override
  State<CardioForm> createState() => _CardioFormState();
}

class _CardioFormState extends State<CardioForm> {
  final _distance = TextEditingController();
  final _duration = TextEditingController();
  final _elevation = TextEditingController();
  String? _stroke;

  @override
  void dispose() {
    _distance.dispose();
    _duration.dispose();
    _elevation.dispose();
    super.dispose();
  }

  void _emit() {
    final a = widget.activity;
    widget.onChanged(ActivitySession(
      activityType: a.id,
      logKind: a.logKind.name,
      distance: parseDoubleField(_distance.text),
      duration: parseIntField(_duration.text),
      elevationGain:
          a.tracksElevation ? parseDoubleField(_elevation.text) : null,
      stroke: a.tracksStroke ? _stroke : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    final a = widget.activity;
    const decimal = TextInputType.numberWithOptions(decimal: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivityField(
          key: const Key('distance-field'),
          label: 'Distance (km)',
          controller: _distance,
          keyboardType: decimal,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: Space.md),
        ActivityField(
          key: const Key('duration-field'),
          label: 'Duration (min)',
          controller: _duration,
          keyboardType: TextInputType.number,
          onChanged: (_) => _emit(),
        ),
        if (a.tracksElevation) ...[
          const SizedBox(height: Space.md),
          ActivityField(
            key: const Key('elevation-field'),
            label: 'Elevation gain (m)',
            controller: _elevation,
            keyboardType: decimal,
            onChanged: (_) => _emit(),
          ),
        ],
        if (a.tracksStroke) ...[
          const SizedBox(height: Space.md),
          DropdownButtonFormField<String>(
            key: const Key('stroke-field'),
            initialValue: _stroke,
            dropdownColor: tokens.surface,
            style: typo.body,
            decoration: InputDecoration(
              labelText: 'Stroke',
              labelStyle: typo.bodySmall.copyWith(color: tokens.inkMuted),
              filled: true,
              fillColor: tokens.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.button),
                borderSide: BorderSide(color: tokens.border),
              ),
            ),
            items: [
              for (final s in swimStrokes)
                DropdownMenuItem(value: s, child: Text(s, style: typo.body)),
            ],
            onChanged: (v) {
              setState(() => _stroke = v);
              _emit();
            },
          ),
        ],
      ],
    );
  }
}
