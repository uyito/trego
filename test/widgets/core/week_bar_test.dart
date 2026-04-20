import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/models/day_status.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/widgets/core/week_bar.dart';

Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) => MaterialApp(
  theme: TregoTheme.light(),
  darkTheme: TregoTheme.dark(),
  themeMode: mode,
  home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final demo = [
    DayStatus.done, DayStatus.today, DayStatus.future,
    DayStatus.future, DayStatus.future, DayStatus.done, DayStatus.done,
  ];

  testWidgets('shows summary of completed / planned', (tester) async {
    await tester.pumpWidget(_wrap(WeekBar(days: demo)));
    // completed=3 (done), planned=4 (done+today+missed)
    expect(find.textContaining('3 of 4 sessions'), findsOneWidget);
  });

  testWidgets('streak renders when provided', (tester) async {
    await tester.pumpWidget(_wrap(WeekBar(days: demo, streakCount: 6)));
    expect(find.textContaining('🔥 6 day streak'), findsOneWidget);
  });

  testWidgets('asserts 7 days', (tester) async {
    expect(
      () => WeekBar(days: const [DayStatus.done, DayStatus.done]),
      throwsAssertionError,
    );
  });

  final full = [
    DayStatus.done, DayStatus.done, DayStatus.missed,
    DayStatus.today, DayStatus.future, DayStatus.future, DayStatus.future,
  ];

  testWidgets('golden: week bar dark', (tester) async {
    await tester.pumpWidget(_wrap(WeekBar(days: full, streakCount: 6), mode: ThemeMode.dark));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/week_bar_dark.png'));
  });

  testWidgets('golden: week bar light', (tester) async {
    await tester.pumpWidget(_wrap(WeekBar(days: full, streakCount: 6), mode: ThemeMode.light));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/week_bar_light.png'));
  });
}
