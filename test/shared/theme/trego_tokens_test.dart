import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/shared/theme/trego_tokens.dart';

void main() {
  group('TregoTokens', () {
    test('dark tokens have correct brand color', () {
      const tokens = TregoTokens.dark;
      expect(tokens.brand, const Color(0xFFC5181E));
      expect(tokens.canvas, const Color(0xFF0E0F12));
      expect(tokens.surface, const Color(0xFF1A1C22));
      expect(tokens.ink, const Color(0xFFFFFFFF));
      expect(tokens.success, const Color(0xFF00C853));
    });

    test('light tokens have correct brand color', () {
      const tokens = TregoTokens.light;
      expect(tokens.brand, const Color(0xFFC5181E));
      expect(tokens.canvas, const Color(0xFFFAFAFA));
      expect(tokens.surface, const Color(0xFFFFFFFF));
      expect(tokens.ink, const Color(0xFF111111));
      expect(tokens.success, const Color(0xFF00A344));
    });

    test('lerp blends canvas between light and dark', () {
      const light = TregoTokens.light;
      const dark = TregoTokens.dark;
      final mid = light.lerp(dark, 0.5) as TregoTokens;
      expect(mid.canvas.red, inInclusiveRange(14, 250));
    });
  });

  test('Space constants match 4-pt grid', () {
    expect(Space.xs, 4);
    expect(Space.sm, 8);
    expect(Space.md, 12);
    expect(Space.lg, 16);
    expect(Space.xl, 24);
    expect(Space.xxl, 32);
    expect(Space.xxxl, 48);
  });

  test('Radii constants', () {
    expect(Radii.button, 8.0);
    expect(Radii.statTile, 12.0);
    expect(Radii.compactCard, 14.0);
    expect(Radii.standardCard, 16.0);
    expect(Radii.screenWrapper, 20.0);
  });
}
