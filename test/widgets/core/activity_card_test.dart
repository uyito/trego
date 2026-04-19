import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trego/models/activity.dart';
import 'package:trego/shared/theme/trego_theme.dart';
import 'package:trego/widgets/core/activity_card.dart';

Widget _wrap(Widget child, {ThemeMode mode = ThemeMode.dark}) => MaterialApp(
  theme: TregoTheme.light(),
  darkTheme: TregoTheme.dark(),
  themeMode: mode,
  home: Scaffold(body: Padding(padding: const EdgeInsets.all(12), child: child)),
);

final sample = Activity(
  userName: 'Jordan Chen',
  timestampLabel: 'Today at 8:04 AM',
  locationLabel: 'Austin, TX',
  title: 'Morning Long Run',
  distanceKm: 8.2,
  pacePerKm: '4:56',
  durationLabel: '40:28',
  kudosCount: 12,
  commentCount: 3,
  userHasKudosed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('standard renders name, title, stats', (tester) async {
    await tester.pumpWidget(_wrap(ActivityCard(activity: sample)));
    expect(find.text('Jordan Chen'), findsOneWidget);
    expect(find.text('Morning Long Run'), findsOneWidget);
    expect(find.text('8.2'), findsOneWidget);
    expect(find.text('4:56'), findsOneWidget);
    expect(find.text('40:28'), findsOneWidget);
  });

  testWidgets('compact density hides map + actions', (tester) async {
    await tester.pumpWidget(_wrap(ActivityCard(
      activity: sample,
      density: ActivityCardDensity.compact,
    )));
    expect(find.byKey(const Key('activity-map-placeholder')), findsNothing);
    expect(find.text('Morning Long Run'), findsNothing);
    expect(find.text('Jordan Chen'), findsOneWidget);
  });

  testWidgets('onKudos invoked when ❤ tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(ActivityCard(
      activity: sample,
      onKudos: () => taps++,
    )));
    await tester.tap(find.byKey(const Key('activity-kudos-button')));
    expect(taps, 1);
  });

  testWidgets('golden: activity card dark', (tester) async {
    await tester.pumpWidget(_wrap(
      SizedBox(width: 340, child: ActivityCard(activity: sample)),
      mode: ThemeMode.dark,
    ));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/activity_card_dark.png'));
  });

  testWidgets('golden: activity card light', (tester) async {
    await tester.pumpWidget(_wrap(
      SizedBox(width: 340, child: ActivityCard(activity: sample)),
      mode: ThemeMode.light,
    ));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../goldens/activity_card_light.png'));
  });
}
