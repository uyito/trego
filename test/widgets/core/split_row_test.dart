import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/widgets/core/split_row.dart';
import '../../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('formats pace as M:SS', (tester) async {
    await tester.pumpWidget(testApp(
      const Center(
        child: SplitRow(
          kmIndex: 1,
          splitPace: Duration(minutes: 4, seconds: 32),
          fastestPaceSecPerKm: 270,
          slowestPaceSecPerKm: 300,
        ),
      ),
    ));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4:32'), findsOneWidget);
  });

  testWidgets('golden: splits list dark', (tester) async {
    await tester.pumpWidget(testApp(
      const Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          SplitRow(kmIndex: 1, splitPace: Duration(minutes: 4, seconds: 32),
                   fastestPaceSecPerKm: 270, slowestPaceSecPerKm: 282),
          SplitRow(kmIndex: 2, splitPace: Duration(minutes: 4, seconds: 36),
                   fastestPaceSecPerKm: 270, slowestPaceSecPerKm: 282),
          SplitRow(kmIndex: 3, splitPace: Duration(minutes: 4, seconds: 30),
                   fastestPaceSecPerKm: 270, slowestPaceSecPerKm: 282),
        ]),
      ),
    ));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/split_row_dark.png'),
    );
  });

  testWidgets('golden: splits list light', (tester) async {
    await tester.pumpWidget(testApp(
      const Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          SplitRow(kmIndex: 1, splitPace: Duration(minutes: 4, seconds: 32),
                   fastestPaceSecPerKm: 270, slowestPaceSecPerKm: 282),
          SplitRow(kmIndex: 2, splitPace: Duration(minutes: 4, seconds: 36),
                   fastestPaceSecPerKm: 270, slowestPaceSecPerKm: 282),
          SplitRow(kmIndex: 3, splitPace: Duration(minutes: 4, seconds: 30),
                   fastestPaceSecPerKm: 270, slowestPaceSecPerKm: 282),
        ]),
      ),
      mode: ThemeMode.light,
    ));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../goldens/split_row_light.png'),
    );
  });
}
