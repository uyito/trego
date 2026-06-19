import 'package:flutter/material.dart';

/// Shows a dialog to edit a post's content. Resolves to the new content, or
/// null if cancelled or unchanged/empty.
Future<String?> showEditPostDialog(BuildContext context, String initialContent) {
  return showDialog<String>(
    context: context,
    builder: (_) => _EditPostDialog(initialContent: initialContent),
  );
}

class _EditPostDialog extends StatefulWidget {
  final String initialContent;

  const _EditPostDialog({required this.initialContent});

  @override
  State<_EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<_EditPostDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialContent);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty || text == widget.initialContent.trim()) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit post'),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        minLines: 3,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Update your post...',
          border: OutlineInputBorder(),
        ),
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
