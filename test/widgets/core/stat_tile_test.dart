import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/widgets/core/stat_tile.dart';

Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) => MaterialApp(
  theme: TregoTheme.light(),
  darkTheme: TregoTheme.dark(),
  themeMode: mode,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('renders label and value', (tester) async {
    await tester.pumpWidget(_wrap(const StatTile(label: 'km / wk', value: '23.4')));
    expect(find.text('23.4'), findsOneWidget);
    expect(find.text('KM / WK'), findsOneWidget);
  });

  testWidgets('prefix is rendered before value', (tester) async {
    await tester.pumpWidget(_wrap(const StatTile(label: 'streak', value: '6', prefix: '🔥 ')));
    expect(find.text('🔥 6'), findsOneWidget);
  });

  testWidgets('success tone applies success color', (tester) async {
    await tester.pumpWidget(_wrap(
      const StatTile(label: 'streak', value: '6', tone: StatTone.success),
      mode: ThemeMode.dark,
    ));
    final text = tester.widget<Text>(find.text('6'));
    expect(text.style?.color, const Color(0xFF00C853));
  });

  testWidgets('golden: stat row dark', (tester) async {
    await tester.pumpWidget(_wrap(
      const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 340,
          child: Row(
            children: [
              Expanded(child: StatTile(label: 'km', value: '23.4')),
              SizedBox(width: 8),
              Expanded(child: StatTile(label: 'runs', value: '4')),
              SizedBox(width: 8),
              Expanded(child: StatTile(label: 'streak', value: '6', prefix: '🔥 ', tone: StatTone.success)),
            ],
          ),
        ),
      ),
      mode: ThemeMode.dark,
    ));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/stat_tile_dark.png'));
  });

  testWidgets('golden: stat row light', (tester) async {
    await tester.pumpWidget(_wrap(
      const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 340,
          child: Row(
            children: [
              Expanded(child: StatTile(label: 'km', value: '23.4')),
              SizedBox(width: 8),
              Expanded(child: StatTile(label: 'runs', value: '4')),
              SizedBox(width: 8),
              Expanded(child: StatTile(label: 'streak', value: '6', prefix: '🔥 ', tone: StatTone.success)),
            ],
          ),
        ),
      ),
      mode: ThemeMode.light,
    ));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/stat_tile_light.png'));
  });
}
