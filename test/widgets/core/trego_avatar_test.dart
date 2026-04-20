import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/widgets/core/trego_avatar.dart';

Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) => MaterialApp(
  theme: TregoTheme.light(),
  darkTheme: TregoTheme.dark(),
  themeMode: mode,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('shows single initial for one-word name', (tester) async {
    await tester.pumpWidget(_wrap(const TregoAvatar(name: 'Alex')));
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('shows two initials for two-word name', (tester) async {
    await tester.pumpWidget(_wrap(const TregoAvatar(name: 'Jordan Chen')));
    expect(find.text('JC'), findsOneWidget);
  });

  testWidgets('uppercase initials', (tester) async {
    await tester.pumpWidget(_wrap(const TregoAvatar(name: 'priya patel')));
    expect(find.text('PP'), findsOneWidget);
  });

  testWidgets('sm size is 24x24', (tester) async {
    await tester.pumpWidget(_wrap(const TregoAvatar(name: 'X', size: TregoAvatarSize.sm)));
    final size = tester.getSize(find.byType(TregoAvatar));
    expect(size, const Size(24, 24));
  });

  testWidgets('md size is 34x34', (tester) async {
    await tester.pumpWidget(_wrap(const TregoAvatar(name: 'X')));
    expect(tester.getSize(find.byType(TregoAvatar)), const Size(34, 34));
  });

  testWidgets('lg size is 48x48', (tester) async {
    await tester.pumpWidget(_wrap(const TregoAvatar(name: 'X', size: TregoAvatarSize.lg)));
    expect(tester.getSize(find.byType(TregoAvatar)), const Size(48, 48));
  });

  testWidgets('has semantic label from name', (tester) async {
    await tester.pumpWidget(_wrap(const TregoAvatar(name: 'Alex Kim')));
    expect(find.bySemanticsLabel('Alex Kim'), findsOneWidget);
  });

  testWidgets('golden: avatar grid dark', (tester) async {
    await tester.pumpWidget(_wrap(
      const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TregoAvatar(name: 'Alex Kim', size: TregoAvatarSize.sm),
            SizedBox(width: 12),
            TregoAvatar(name: 'Jordan Chen'),
            SizedBox(width: 12),
            TregoAvatar(name: 'Priya Patel', size: TregoAvatarSize.lg),
          ],
        ),
      ),
      mode: ThemeMode.dark,
    ));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/trego_avatar_dark.png'));
  });

  testWidgets('golden: avatar grid light', (tester) async {
    await tester.pumpWidget(_wrap(
      const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TregoAvatar(name: 'Alex Kim', size: TregoAvatarSize.sm),
            SizedBox(width: 12),
            TregoAvatar(name: 'Jordan Chen'),
            SizedBox(width: 12),
            TregoAvatar(name: 'Priya Patel', size: TregoAvatarSize.lg),
          ],
        ),
      ),
      mode: ThemeMode.light,
    ));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/trego_avatar_light.png'));
  });
}
