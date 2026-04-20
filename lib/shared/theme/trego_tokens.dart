import 'package:flutter/material.dart';

/// Design tokens for Trego. Attached to every [ThemeData] as a
/// [ThemeExtension] and consumed via `context.tokens`.
@immutable
class TregoTokens extends ThemeExtension<TregoTokens> {
  final Color brand;
  final Color brandContainerStart;
  final Color brandContainerEnd;
  final Color onBrand;
  final Color success;
  final Color onSuccess;
  final Color canvas;
  final Color surface;
  final Color surfaceSunken;
  final Color border;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color danger;
  final Color onDanger;

  const TregoTokens({
    required this.brand,
    required this.brandContainerStart,
    required this.brandContainerEnd,
    required this.onBrand,
    required this.success,
    required this.onSuccess,
    required this.canvas,
    required this.surface,
    required this.surfaceSunken,
    required this.border,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.danger,
    required this.onDanger,
  });

  static const dark = TregoTokens(
    brand: Color(0xFFC5181E),
    brandContainerStart: Color(0xFFC5181E),
    brandContainerEnd: Color(0xFF7A0F16),
    onBrand: Color(0xFFFFFFFF),
    success: Color(0xFF00C853),
    onSuccess: Color(0xFF0E0F12),
    canvas: Color(0xFF0E0F12),
    surface: Color(0xFF1A1C22),
    surfaceSunken: Color(0xFF14161B),
    border: Color(0xFF232630),
    ink: Color(0xFFFFFFFF),
    inkMuted: Color(0xFF8B93A3),
    inkFaint: Color(0xFF5E6674),
    danger: Color(0xFFFF5252),
    onDanger: Color(0xFFFFFFFF),
  );

  static const light = TregoTokens(
    brand: Color(0xFFC5181E),
    brandContainerStart: Color(0xFFC5181E),
    brandContainerEnd: Color(0xFFB71C1C),
    onBrand: Color(0xFFFFFFFF),
    success: Color(0xFF00A344),
    onSuccess: Color(0xFFFFFFFF),
    canvas: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF4F4F6),
    border: Color(0xFFEDEDED),
    ink: Color(0xFF111111),
    inkMuted: Color(0xFF6B7280),
    inkFaint: Color(0xFF9CA3AF),
    danger: Color(0xFFE53935),
    onDanger: Color(0xFFFFFFFF),
  );

  @override
  TregoTokens copyWith({
    Color? brand,
    Color? brandContainerStart,
    Color? brandContainerEnd,
    Color? onBrand,
    Color? success,
    Color? onSuccess,
    Color? canvas,
    Color? surface,
    Color? surfaceSunken,
    Color? border,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? danger,
    Color? onDanger,
  }) {
    return TregoTokens(
      brand: brand ?? this.brand,
      brandContainerStart: brandContainerStart ?? this.brandContainerStart,
      brandContainerEnd: brandContainerEnd ?? this.brandContainerEnd,
      onBrand: onBrand ?? this.onBrand,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
    );
  }

  @override
  TregoTokens lerp(ThemeExtension<TregoTokens>? other, double t) {
    if (other is! TregoTokens) return this;
    return TregoTokens(
      brand: Color.lerp(brand, other.brand, t)!,
      brandContainerStart: Color.lerp(brandContainerStart, other.brandContainerStart, t)!,
      brandContainerEnd: Color.lerp(brandContainerEnd, other.brandContainerEnd, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
    );
  }
}

/// 4-pt spacing scale.
class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  Space._();
}

/// Border radii.
class Radii {
  static const double button = 8;
  static const double statTile = 12;
  static const double compactCard = 14;
  static const double standardCard = 16;
  static const double screenWrapper = 20;
  Radii._();
}

/// Motion durations and curves.
class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration defaultD = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 400);
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubic;
  Motion._();
}
