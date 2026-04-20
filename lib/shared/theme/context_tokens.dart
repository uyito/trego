import 'package:flutter/material.dart';
import 'trego_tokens.dart';
import 'trego_typography.dart';

extension TregoContextExt on BuildContext {
  /// Access to the app's design tokens (colors).
  TregoTokens get tokens {
    final ext = Theme.of(this).extension<TregoTokens>();
    assert(
      ext != null,
      'TregoTokens not found in Theme. Ensure MaterialApp.theme is built via TregoTheme.',
    );
    return ext!;
  }

  /// Access to the app's typography, tinted with the current ink color.
  TregoTypography get typo => TregoTypography.forColor(tokens.ink);
}
