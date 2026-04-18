import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/shared/theme/trego_typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Inter is bundled as a Flutter asset (see pubspec.yaml). Disable
  // runtime fetching so tests never attempt HTTP — google_fonts will
  // use the local asset.
  GoogleFonts.config.allowRuntimeFetching = false;

  final typo = TregoTypography.forColor(const Color(0xFF000000));

  group('TregoTypography', () {
    test('display has correct size/weight', () {
      expect(typo.display.fontSize, 32);
      expect(typo.display.fontWeight, FontWeight.w900);
      expect(typo.display.height, closeTo(1.05, 0.001));
      expect(typo.display.letterSpacing, closeTo(-0.8, 0.001));
    });

    test('stat has tabular figures feature', () {
      expect(typo.stat.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(typo.stat.fontSize, 24);
      expect(typo.stat.fontWeight, FontWeight.w900);
    });

    test('statLarge has tabular figures and size 44', () {
      expect(typo.statLarge.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(typo.statLarge.fontSize, 44);
    });

    test('label is uppercase spacing', () {
      expect(typo.label.fontSize, 10);
      expect(typo.label.fontWeight, FontWeight.w700);
      expect(typo.label.letterSpacing, closeTo(0.8, 0.001));
    });

    test('body has size 14 weight 400', () {
      expect(typo.body.fontSize, 14);
      expect(typo.body.fontWeight, FontWeight.w400);
    });

    test('color is applied', () {
      final redTypo = TregoTypography.forColor(const Color(0xFFFF0000));
      expect(redTypo.display.color, const Color(0xFFFF0000));
      expect(redTypo.body.color, const Color(0xFFFF0000));
    });
  });
}
