import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/widgets/core/workout_hero_card.dart';

Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) => MaterialApp(
  theme: TregoTheme.light(),
  darkTheme: TregoTheme.dark(),
  themeMode: mode,
  home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('renders all fields', (tester) async {
    await tester.pumpWidget(_wrap(WorkoutHeroCard(
      todayLabel: 'Today · Tuesday',
      title: 'Tempo Run',
      metaLine: '30 min · 5.2 km · Zone 3–4',
      ctaLabel: 'Start Workout',
      onStart: () {},
    )));
    expect(find.text('TODAY · TUESDAY'), findsOneWidget);
    expect(find.text('Tempo Run'), findsOneWidget);
    expect(find.text('30 min · 5.2 km · Zone 3–4'), findsOneWidget);
    expect(find.text('Start Workout'), findsOneWidget);
  });

  testWidgets('tapping CTA invokes onStart', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(WorkoutHeroCard(
      todayLabel: 'T',
      title: 'T',
      metaLine: 'T',
      ctaLabel: 'Go',
      onStart: () => taps++,
    )));
    await tester.tap(find.text('Go'));
    expect(taps, 1);
  });

  testWidgets('empty shape renders browse plans CTA', (tester) async {
    await tester.pumpWidget(_wrap(WorkoutHeroCard(
      todayLabel: 'Today',
      title: 'No plan yet',
      metaLine: 'Quick-start a run from Record',
      ctaLabel: 'Browse plans',
      onStart: () {},
      isEmpty: true,
    )));
    expect(find.text('No plan yet'), findsOneWidget);
    expect(find.text('Browse plans'), findsOneWidget);
  });

  testWidgets('golden: hero dark', (tester) async {
    await tester.pumpWidget(_wrap(WorkoutHeroCard(
      todayLabel: 'Today · Tuesday',
      title: 'Tempo Run',
      metaLine: '30 min · 5.2 km · Zone 3–4',
      ctaLabel: 'Start Workout',
      onStart: () {},
    ), mode: ThemeMode.dark));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/workout_hero_card_dark.png'));
  });

  testWidgets('golden: hero light', (tester) async {
    await tester.pumpWidget(_wrap(WorkoutHeroCard(
      todayLabel: 'Today · Tuesday',
      title: 'Tempo Run',
      metaLine: '30 min · 5.2 km · Zone 3–4',
      ctaLabel: 'Start Workout',
      onStart: () {},
    ), mode: ThemeMode.light));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/workout_hero_card_light.png'));
  });
}
