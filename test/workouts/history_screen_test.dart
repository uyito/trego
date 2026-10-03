import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/activity/activity_models.dart';
import 'package:trego/workouts/activity/history_screen.dart';
import 'package:trego/workouts/activity/workout_service.dart';

import '../helpers/test_app.dart';

class _FakeService extends WorkoutService {
  final List<ActivitySession> sessions;
  _FakeService(this.sessions);
  @override
  Future<List<ActivitySession>> getHistory() async => sessions;
}

void main() {
  initTestEnv();

  testWidgets('lists sessions with names and primary metrics', (tester) async {
    final fake = _FakeService([
      ActivitySession(
          activityType: 'running', logKind: 'distanceCardio', distance: 5.2, duration: 30,
          createdAt: DateTime(2026, 3, 4, 12)),
      ActivitySession(
        activityType: 'weight-training',
        logKind: 'strength',
        duration: 45,
        createdAt: DateTime(2026, 3, 5, 12),
        exercises: [
          ExerciseLog(exerciseId: 'sq', name: 'Squat', sets: [
            ExerciseSet(reps: 5, weight: 100),
            ExerciseSet(reps: 5, weight: 100),
          ]),
        ],
      ),
    ]);
    await tester.pumpWidget(testApp(WorkoutHistoryScreen(service: fake)));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Weight Training'), findsOneWidget);
    expect(find.text('5.2 km'), findsOneWidget);
    expect(find.text('1000 kg'), findsOneWidget);
    expect(find.text('2026-03-04'), findsOneWidget);
    expect(find.text('2026-03-05'), findsOneWidget);
    expect(find.text('No workouts logged yet'), findsNothing);
  });

  testWidgets('strength with zero volume falls back to duration', (tester) async {
    await tester.pumpWidget(testApp(WorkoutHistoryScreen(
        service: _FakeService([
      ActivitySession(activityType: 'weight-training', logKind: 'strength', duration: 40),
    ]))));
    await tester.pumpAndSettle();
    expect(find.text('40 min'), findsOneWidget);
    expect(find.text('0 kg'), findsNothing);
  });

  testWidgets('shows empty state when no history', (tester) async {
    await tester.pumpWidget(testApp(WorkoutHistoryScreen(service: _FakeService([]))));
    await tester.pumpAndSettle();
    expect(find.text('No workouts logged yet'), findsOneWidget);
  });
}
