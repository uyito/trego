import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/activity/activity_picker_screen.dart';
import 'package:trego/workouts/workout_hub.dart';

import '../helpers/test_app.dart';

void main() {
  initTestEnv();

  testWidgets('WorkoutHub shows the activity picker on the log tab',
      (tester) async {
    await tester.pumpWidget(testApp(const WorkoutHub()));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityPickerScreen), findsOneWidget);
    expect(find.text('Log Activity'), findsWidgets);
    expect(find.text('Workout Plans'), findsOneWidget);
  });
}
