import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/shared/theme/context_tokens.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/shared/theme/trego_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('dark theme exposes dark tokens via context.tokens', (tester) async {
    late TregoTokens captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: TregoTheme.light(),
        darkTheme: TregoTheme.dark(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            captured = context.tokens;
            return const Scaffold();
          },
        ),
      ),
    );
    expect(captured.canvas, const Color(0xFF0E0F12));
    expect(captured.ink, const Color(0xFFFFFFFF));
  });

  testWidgets('light theme exposes light tokens via context.tokens', (tester) async {
    late TregoTokens captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: TregoTheme.light(),
        darkTheme: TregoTheme.dark(),
        themeMode: ThemeMode.light,
        home: Builder(
          builder: (context) {
            captured = context.tokens;
            return const Scaffold();
          },
        ),
      ),
    );
    expect(captured.canvas, const Color(0xFFFAFAFA));
    expect(captured.ink, const Color(0xFF111111));
  });

  testWidgets('dark theme scaffoldBackground matches canvas', (tester) async {
    final theme = TregoTheme.dark();
    expect(theme.scaffoldBackgroundColor, const Color(0xFF0E0F12));
    expect(theme.brightness, Brightness.dark);
  });

  testWidgets('light theme scaffoldBackground matches canvas', (tester) async {
    final theme = TregoTheme.light();
    expect(theme.scaffoldBackgroundColor, const Color(0xFFFAFAFA));
    expect(theme.brightness, Brightness.light);
  });
}
