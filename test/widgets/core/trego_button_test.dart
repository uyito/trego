import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/widgets/core/trego_button.dart';

Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) {
  return MaterialApp(
    theme: TregoTheme.light(),
    darkTheme: TregoTheme.dark(),
    themeMode: mode,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('renders label', (tester) async {
    await tester.pumpWidget(_wrap(TregoButton(label: 'Go', onPressed: () {})));
    expect(find.text('Go'), findsOneWidget);
  });

  testWidgets('calls onPressed when tapped', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_wrap(TregoButton(label: 'Tap', onPressed: () => tapped++)));
    await tester.tap(find.text('Tap'));
    expect(tapped, 1);
  });

  testWidgets('disabled when onPressed is null', (tester) async {
    await tester.pumpWidget(_wrap(const TregoButton(label: 'Off', onPressed: null)));
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });

  testWidgets('loading state shows spinner and disables tap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_wrap(TregoButton(
      label: 'Save',
      loading: true,
      onPressed: () => tapped++,
    )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(TregoButton));
    expect(tapped, 0);
  });

  testWidgets('md size height is 44', (tester) async {
    await tester.pumpWidget(_wrap(TregoButton(label: 'M', onPressed: () {})));
    final size = tester.getSize(find.byType(TregoButton));
    expect(size.height, 44);
  });

  testWidgets('lg size height is 52', (tester) async {
    await tester.pumpWidget(_wrap(TregoButton(
      label: 'L',
      size: TregoButtonSize.lg,
      onPressed: () {},
    )));
    final size = tester.getSize(find.byType(TregoButton));
    expect(size.height, 52);
  });

  testWidgets('fullWidth expands to parent', (tester) async {
    await tester.pumpWidget(_wrap(SizedBox(
      width: 300,
      child: TregoButton(label: 'F', fullWidth: true, onPressed: () {}),
    )));
    final size = tester.getSize(find.byType(TregoButton));
    expect(size.width, 300);
  });

  testWidgets('golden: primary button dark', (tester) async {
    await tester.pumpWidget(_wrap(
      Padding(
        padding: const EdgeInsets.all(16),
        child: TregoButton(label: 'Start Workout', onPressed: () {}),
      ),
      mode: ThemeMode.dark,
    ));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/trego_button_dark.png'),
    );
  });

  testWidgets('golden: primary button light', (tester) async {
    await tester.pumpWidget(_wrap(
      Padding(
        padding: const EdgeInsets.all(16),
        child: TregoButton(label: 'Start Workout', onPressed: () {}),
      ),
      mode: ThemeMode.light,
    ));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/trego_button_light.png'),
    );
  });
}
