import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/username_api.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/trego_app_bar.dart';
import '../widgets/core/trego_scaffold.dart';

/// Lets the user claim or rename their unique username.
class UsernameEditScreen extends StatefulWidget {
  final String? currentUsername;

  /// Injectable for tests; defaults to a real [UsernameApi].
  final UsernameApi? api;

  const UsernameEditScreen({super.key, this.currentUsername, this.api});

  @override
  State<UsernameEditScreen> createState() => _UsernameEditScreenState();
}

class _UsernameEditScreenState extends State<UsernameEditScreen> {
  late final UsernameApi _api = widget.api ?? UsernameApi();
  late final TextEditingController _controller =
      TextEditingController(text: widget.currentUsername ?? '');

  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim().toLowerCase();

    // Client-side validation first for instant feedback.
    final localError = validateUsername(value);
    if (localError != null) {
      setState(() => _error = localError);
      return;
    }
    // No-op if unchanged.
    if (value == (widget.currentUsername ?? '')) {
      Navigator.of(context).pop(value);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final serverError = await _api.setUsername(value);
    if (!mounted) return;

    if (serverError == null) {
      Navigator.of(context).pop(value);
    } else {
      setState(() {
        _saving = false;
        _error = serverError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TregoScaffold(
      appBar: const TregoAppBar(title: 'Username'),
      body: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pick a unique username. Friends can add you by it.',
              style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                LengthLimitingTextInputFormatter(20),
              ],
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                prefixText: '@',
                hintText: 'yourname',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
