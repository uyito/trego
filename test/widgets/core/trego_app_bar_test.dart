import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/widgets/core/trego_app_bar.dart';

Widget _wrap(PreferredSizeWidget bar, {ThemeMode mode = ThemeMode.dark}) => MaterialApp(
  theme: TregoTheme.light(),
  darkTheme: TregoTheme.dark(),
  themeMode: mode,
  home: Scaffold(appBar: bar, body: const SizedBox()),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('title mode shows title only', (tester) async {
    await tester.pumpWidget(_wrap(const TregoAppBar(title: 'Settings')));
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('greeting mode shows greeting + subtitle', (tester) async {
    await tester.pumpWidget(_wrap(const TregoAppBar(
      greeting: 'Morning, Alex',
      subtitle: 'Day 22 of 12-week plan',
    )));
    expect(find.text('Morning, Alex'), findsOneWidget);
    expect(find.text('Day 22 of 12-week plan'), findsOneWidget);
  });

  testWidgets('title mode preferredSize height is 56', (tester) async {
    const bar = TregoAppBar(title: 'X');
    expect(bar.preferredSize.height, 56);
  });

  testWidgets('greeting mode preferredSize height is 72', (tester) async {
    const bar = TregoAppBar(greeting: 'Hi');
    expect(bar.preferredSize.height, 72);
  });

  testWidgets('trailing widgets render', (tester) async {
    await tester.pumpWidget(_wrap(TregoAppBar(
      title: 'T',
      trailing: [const Icon(Icons.notifications)],
    )));
    expect(find.byIcon(Icons.notifications), findsOneWidget);
  });

  testWidgets('asserts title XOR greeting', (tester) async {
    expect(() => TregoAppBar(title: 'X', greeting: 'Y'), throwsAssertionError);
    expect(() => TregoAppBar(), throwsAssertionError);
  });

  testWidgets('golden: app bar greeting dark', (tester) async {
    await tester.pumpWidget(_wrap(TregoAppBar(
      greeting: 'Morning, Alex',
      subtitle: 'Day 22 of 12-week plan',
      trailing: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})],
    ), mode: ThemeMode.dark));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/trego_app_bar_dark.png'));
  });

  testWidgets('golden: app bar greeting light', (tester) async {
    await tester.pumpWidget(_wrap(TregoAppBar(
      greeting: 'Morning, Alex',
      subtitle: 'Day 22 of 12-week plan',
      trailing: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})],
    ), mode: ThemeMode.light));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/trego_app_bar_light.png'));
  });
}
