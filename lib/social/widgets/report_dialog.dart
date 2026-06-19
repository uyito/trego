import 'package:flutter/material.dart';

/// Reasons a user can pick when reporting a post. Value is sent to the backend.
const Map<String, String> kReportReasons = {
  'spam': 'Spam',
  'harassment': 'Harassment',
  'inappropriate': 'Inappropriate content',
  'other': 'Other',
};

/// Shows a reason-picker dialog. Resolves to the chosen reason key, or null if
/// the user cancels.
Future<String?> showReportDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _ReportDialog(),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String _selected = kReportReasons.keys.first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report post'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in kReportReasons.entries)
            RadioListTile<String>(
              value: entry.key,
              groupValue: _selected,
              title: Text(entry.value),
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _selected = v!),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Report'),
        ),
      ],
    );
  }
}
