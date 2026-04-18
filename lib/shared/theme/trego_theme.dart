import 'package:flutter/material.dart';
import 'trego_tokens.dart';
import 'trego_typography.dart';

class TregoTheme {
  TregoTheme._();

  static ThemeData light() => _build(TregoTokens.light, Brightness.light);
  static ThemeData dark() => _build(TregoTokens.dark, Brightness.dark);

  static ThemeData _build(TregoTokens tokens, Brightness brightness) {
    final typo = TregoTypography.forColor(tokens.ink);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: tokens.canvas,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: tokens.brand,
        onPrimary: tokens.onBrand,
        secondary: tokens.success,
        onSecondary: tokens.onSuccess,
        error: tokens.danger,
        onError: tokens.onDanger,
        surface: tokens.surface,
        onSurface: tokens.ink,
      ),
      textTheme: TextTheme(
        displayLarge: typo.display,
        titleLarge: typo.title,
        titleMedium: typo.titleSmall,
        bodyLarge: typo.body,
        bodyMedium: typo.body,
        bodySmall: typo.bodySmall,
        labelSmall: typo.label,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}
