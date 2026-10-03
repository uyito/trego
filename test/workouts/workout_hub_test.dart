import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/activity/activity_picker_screen.dart';
import 'package:trego/workouts/activity/history_screen.dart';
import 'package:trego/workouts/activity/prs_screen.dart';
import 'package:trego/widgets/core/trego_app_bar.dart';
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

  testWidgets('WorkoutHub shows exactly one app bar (picker is embedded)',
      (tester) async {
    await tester.pumpWidget(testApp(const WorkoutHub()));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(TregoAppBar), findsNothing);
  });

  testWidgets('WorkoutHub app bar History action opens WorkoutHistoryScreen',
      (tester) async {
    await tester.pumpWidget(testApp(const WorkoutHub()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.history), findsOneWidget);
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutHistoryScreen), findsOneWidget);
  });

  testWidgets('WorkoutHub app bar PRs action opens PRsScreen', (tester) async {
    await tester.pumpWidget(testApp(const WorkoutHub()));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    await tester.tap(find.byIcon(Icons.emoji_events));
    await tester.pumpAndSettle();
    expect(find.byType(PRsScreen), findsOneWidget);
  });
}
