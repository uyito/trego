import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/widgets/core/section_head.dart';

Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) => MaterialApp(
  theme: TregoTheme.light(),
  darkTheme: TregoTheme.dark(),
  themeMode: mode,
  home: Scaffold(body: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('renders uppercase label', (tester) async {
    await tester.pumpWidget(_wrap(const SectionHead(label: 'This Week')));
    expect(find.text('THIS WEEK'), findsOneWidget);
  });

  testWidgets('no trailing when trailingLabel is null', (tester) async {
    await tester.pumpWidget(_wrap(const SectionHead(label: 'Plain')));
    expect(find.text('See all →'), findsNothing);
  });

  testWidgets('trailing label rendered and tappable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(SectionHead(
      label: 'Friends',
      trailingLabel: 'See all →',
      onTrailingTap: () => taps++,
    )));
    expect(find.text('See all →'), findsOneWidget);
    await tester.tap(find.text('See all →'));
    expect(taps, 1);
  });

  testWidgets('golden: section head dark', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(children: [
        SectionHead(label: 'This Week'),
        SectionHead(label: 'Friends', trailingLabel: 'See all →'),
      ]),
      mode: ThemeMode.dark,
    ));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/section_head_dark.png'));
  });

  testWidgets('golden: section head light', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(children: [
        SectionHead(label: 'This Week'),
        SectionHead(label: 'Friends', trailingLabel: 'See all →'),
      ]),
      mode: ThemeMode.light,
    ));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/section_head_light.png'));
  });
}
