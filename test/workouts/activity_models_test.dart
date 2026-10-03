import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/activity/activity_models.dart';

void main() {
  test('strength session payload nests exercises and sets', () {
    final s = ActivitySession(
      activityType: 'weight-training', logKind: 'strength', sessionName: 'Push day',
      exercises: [
        ExerciseLog(exerciseId: 'bench-press', name: 'Bench Press', sets: [
          ExerciseSet(setNumber: 1, reps: 10, weight: 60), ExerciseSet(setNumber: 2, reps: 8, weight: 65),
        ]),
      ],
    );
    final p = s.toLogPayload();
    expect(p['logKind'], 'strength');
    expect((p['exercises'] as List).length, 1);
    final ex = (p['exercises'] as List).first as Map;
    expect(ex['exerciseId'], 'bench-press');
    expect((ex['sets'] as List).first['weight'], 60);
    expect(p.containsKey('distance'), isFalse); // nulls omitted
  });

  test('cardio session payload carries distance + elevation, no exercises key', () {
    final s = ActivitySession(
      activityType: 'hiking', logKind: 'distanceCardio', distance: 12.5, elevationGain: 430, duration: 95);
    final p = s.toLogPayload();
    expect(p['distance'], 12.5);
    expect(p['elevationGain'], 430);
    expect(p['duration'], 95);
    expect(p.containsKey('exercises'), isFalse);
  });

  test('fromJson round-trips a server session', () {
    final json = {
      'id': 's1', 'activityType': 'running', 'logKind': 'distanceCardio',
      'distance': 10.0, 'elevationGain': 120.0, 'avgPace': 330.0, 'duration': 55,
    };
    final s = ActivitySession.fromJson(json);
    expect(s.id, 's1');
    expect(s.activityType, 'running');
    expect(s.distance, 10.0);
    expect(s.avgPace, 330.0);
  });
}
