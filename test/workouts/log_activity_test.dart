import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/activity/activity_library.dart';
import 'package:trego/workouts/activity/activity_models.dart';
import 'package:trego/workouts/activity/log_activity_screen.dart';
import 'package:trego/workouts/activity/workout_service.dart';

import '../helpers/test_app.dart';

class _CapturingService extends WorkoutService {
  ActivitySession? logged;
  @override
  Future<ActivitySession?> logSession(ActivitySession s) async {
    logged = s;
    return s..id = 'saved';
  }
}

Future<_CapturingService> _pump(WidgetTester tester, String id) async {
  final svc = _CapturingService();
  await tester.pumpWidget(
      testApp(LogActivityScreen(activity: activityById(id)!, service: svc)));
  return svc;
}

void main() {
  initTestEnv();

  testWidgets('cardio form saves distance + duration', (tester) async {
    final svc = await _pump(tester, 'hiking');
    await tester.enterText(find.byKey(const Key('distance-field')), '12.5');
    await tester.enterText(find.byKey(const Key('duration-field')), '95');
    await tester.enterText(find.byKey(const Key('elevation-field')), '800');
    await tester.ensureVisible(find.byKey(const Key('save-activity')));
    await tester.tap(find.byKey(const Key('save-activity')));
    await tester.pumpAndSettle();
    expect(svc.logged!.activityType, 'hiking');
    expect(svc.logged!.logKind, 'distanceCardio');
    expect(svc.logged!.distance, 12.5);
    expect(svc.logged!.duration, 95);
    expect(svc.logged!.elevationGain, 800);
  });

  testWidgets('duration form saves duration + notes', (tester) async {
    final svc = await _pump(tester, 'meditation');
    await tester.enterText(find.byKey(const Key('duration-field')), '20');
    await tester.enterText(find.byKey(const Key('notes-field')), 'calm');
    await tester.tap(find.byKey(const Key('save-activity')));
    await tester.pumpAndSettle();
    expect(svc.logged!.logKind, 'duration');
    expect(svc.logged!.duration, 20);
    expect(svc.logged!.notes, 'calm');
  });

  testWidgets('sport form saves duration + default RPE', (tester) async {
    final svc = await _pump(tester, 'soccer');
    await tester.enterText(find.byKey(const Key('duration-field')), '60');
    await tester.tap(find.byKey(const Key('save-activity')));
    await tester.pumpAndSettle();
    expect(svc.logged!.logKind, 'sport');
    expect(svc.logged!.duration, 60);
    expect(svc.logged!.perceivedExertion, 5);
  });

  testWidgets('strength form saves exercise with sets', (tester) async {
    final svc = await _pump(tester, 'weight-training');
    await tester.enterText(find.byKey(const Key('exercise-name-field')), 'Squat');
    await tester.tap(find.byKey(const Key('add-exercise')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('reps-field-0')), '8');
    await tester.enterText(find.byKey(const Key('weight-field-0')), '100');
    await tester.tap(find.byKey(const Key('add-set-0')));
    await tester.pump();
    expect(find.text('01:30'), findsOneWidget); // rest timer
    await tester.tap(find.byKey(const Key('save-activity')));
    await tester.pumpAndSettle();
    final ex = svc.logged!.exercises.single;
    expect(ex.name, 'Squat');
    expect(ex.sets.single.reps, 8);
    expect(ex.sets.single.weight, 100);
    expect(ex.sets.single.setNumber, 1);
  });
}
