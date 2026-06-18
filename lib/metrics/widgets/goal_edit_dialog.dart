import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../metrics_models.dart';

/// Result of the goal editor: the chosen targets (either may be null to clear).
class GoalEditResult {
  final double? targetKm;
  final int? targetRuns;
  const GoalEditResult({this.targetKm, this.targetRuns});
}

/// Shows the weekly-goal editor seeded from [current]. Resolves to a
/// [GoalEditResult] on save, or null if cancelled.
Future<GoalEditResult?> showGoalEditDialog(BuildContext context, WeeklyGoal? current) {
  return showDialog<GoalEditResult>(
    context: context,
    builder: (_) => _GoalEditDialog(current: current),
  );
}

class _GoalEditDialog extends StatefulWidget {
  final WeeklyGoal? current;
  const _GoalEditDialog({required this.current});

  @override
  State<_GoalEditDialog> createState() => _GoalEditDialogState();
}

class _GoalEditDialogState extends State<_GoalEditDialog> {
  late final TextEditingController _km = TextEditingController(
    text: widget.current?.targetKm != null
        ? widget.current!.targetKm!.toStringAsFixed(0)
        : '',
  );
  late final TextEditingController _runs = TextEditingController(
    text: widget.current?.targetRuns?.toString() ?? '',
  );

  @override
  void dispose() {
    _km.dispose();
    _runs.dispose();
    super.dispose();
  }

  void _save() {
    final km = double.tryParse(_km.text.trim());
    final runs = int.tryParse(_runs.text.trim());
    Navigator.pop(
      context,
      GoalEditResult(
        targetKm: (km != null && km > 0) ? km : null,
        targetRuns: (runs != null && runs > 0) ? runs : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Weekly goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _km,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: const InputDecoration(
              labelText: 'Distance target (km)',
              hintText: 'e.g. 25',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _runs,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Runs target',
              hintText: 'e.g. 4',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
