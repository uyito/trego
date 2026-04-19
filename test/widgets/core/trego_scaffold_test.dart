import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/widgets/core/trego_app_bar.dart';
import 'package:trego/widgets/core/trego_scaffold.dart';

Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) => MaterialApp(
  theme: TregoTheme.light(),
  darkTheme: TregoTheme.dark(),
  themeMode: mode,
  home: child,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('renders body', (tester) async {
    await tester.pumpWidget(_wrap(const TregoScaffold(body: Text('Hello'))));
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('uses canvas background', (tester) async {
    await tester.pumpWidget(_wrap(const TregoScaffold(body: SizedBox()), mode: ThemeMode.dark));
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF0E0F12));
  });

  testWidgets('renders appBar when provided', (tester) async {
    await tester.pumpWidget(_wrap(const TregoScaffold(
      appBar: TregoAppBar(title: 'Settings'),
      body: SizedBox(),
    )));
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('golden: scaffold dark', (tester) async {
    await tester.pumpWidget(_wrap(const TregoScaffold(
      appBar: TregoAppBar(title: 'Appearance'),
      body: Center(child: Text('Body')),
    ), mode: ThemeMode.dark));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/trego_scaffold_dark.png'));
  });

  testWidgets('golden: scaffold light', (tester) async {
    await tester.pumpWidget(_wrap(const TregoScaffold(
      appBar: TregoAppBar(title: 'Appearance'),
      body: Center(child: Text('Body')),
    ), mode: ThemeMode.light));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/trego_scaffold_light.png'));
  });
}
