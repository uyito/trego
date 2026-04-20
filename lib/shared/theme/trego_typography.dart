import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text styles for Trego, built from Inter with a default ink color.
/// Call [TregoTypography.forColor] with the correct ink color for the
/// current theme.
class TregoTypography {
  final TextStyle display;
  final TextStyle title;
  final TextStyle titleSmall;
  final TextStyle body;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle stat;
  final TextStyle statLarge;
  final TextStyle button;

  const TregoTypography._({
    required this.display,
    required this.title,
    required this.titleSmall,
    required this.body,
    required this.bodySmall,
    required this.label,
    required this.stat,
    required this.statLarge,
    required this.button,
  });

  /// Build the typography set with [ink] as the default text color.
  /// Widgets that need a different color (e.g., `onBrand`) should use
  /// `style.copyWith(color: ...)` at the call site.
  factory TregoTypography.forColor(Color ink) {
    return TregoTypography._(
      display: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        height: 1.05,
        letterSpacing: -0.8,
        color: ink,
      ),
      title: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.3,
        color: ink,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: ink,
      ),
      body: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: ink,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: ink,
      ),
      label: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: 0.8,
        color: ink,
      ),
      stat: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -0.3,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: ink,
      ),
      statLarge: GoogleFonts.inter(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -1.5,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: ink,
      ),
      button: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.0,
        color: ink,
      ),
    );
  }
}
