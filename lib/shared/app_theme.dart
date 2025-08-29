import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryRed = Color(0xFFE31E24);
  static const Color primaryRedDark = Color(0xFFC62828);
  static const Color primaryGreen = Color(0xFF00C851);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryPurple = Color(0xFF9C27B0);

  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color divider = Color(0xFFE0E0E0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, primaryRedDark],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, Color(0xFF00A843)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryOrange, Color(0xFFF57C00)],
  );

  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, Color(0xFF1976D2)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, Color(0xFFF8F9FA)],
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primaryRed.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusExtraLarge = 32.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Text Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    letterSpacing: -1.0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textTertiary,
  );

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryRed,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: primaryRed.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingL,
      vertical: spacingM,
    ),
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: surface,
    foregroundColor: primaryRed,
    elevation: 0,
    side: const BorderSide(color: primaryRed, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingL,
      vertical: spacingM,
    ),
  );

  static ButtonStyle get outlineButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryRed,
    side: const BorderSide(color: primaryRed, width: 1.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingL,
      vertical: spacingM,
    ),
  );

  // Card Decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: cardShadow,
  );

  static BoxDecoration get gradientCardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: cardShadow,
  );

  // Input Decoration
  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: primaryRed, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: primaryRed, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: spacingM,
      vertical: spacingM,
    ),
  );

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Animation Curves
  static const Curve animationCurve = Curves.easeInOut;
  static const Curve animationCurveFast = Curves.easeOutCubic;
  static const Curve animationCurveSlow = Curves.easeInOutCubic;
} 