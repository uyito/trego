import 'package:flutter/material.dart';

import '../../../shared/theme/context_tokens.dart';
import '../../../shared/theme/trego_tokens.dart';

/// Token-styled text field shared by the activity logging forms.
class ActivityField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final int maxLines;

  const ActivityField({
    super.key,
    required this.label,
    required this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: c),
        );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: typo.body,
      cursorColor: tokens.brand,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: typo.bodySmall.copyWith(color: tokens.inkMuted),
        filled: true,
        fillColor: tokens.surface,
        enabledBorder: border(tokens.border),
        focusedBorder: border(tokens.brand),
      ),
    );
  }
}

int? parseIntField(String s) => int.tryParse(s.trim());
double? parseDoubleField(String s) => double.tryParse(s.trim());
