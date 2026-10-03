import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/activity/widgets/rest_timer.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('counts down and fires onDone at zero', (tester) async {
    var doneCount = 0;
    await tester.pumpWidget(
        testApp(RestTimer(seconds: 2, onDone: () => doneCount++)));
    expect(find.text('00:02'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(doneCount, 1);
    await tester.pump(const Duration(seconds: 3));
    expect(doneCount, 1);
  });

  testWidgets('Skip fires onDone immediately, once', (tester) async {
    var doneCount = 0;
    await tester.pumpWidget(
        testApp(RestTimer(seconds: 90, onDone: () => doneCount++)));
    expect(find.text('01:30'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(doneCount, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(doneCount, 1);
  });
}
