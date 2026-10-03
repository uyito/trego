import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/activity/activity.dart';
import 'package:trego/workouts/activity/activity_library.dart';

void main() {
  test('library has the key Strava-comparable activities', () {
    final ids = activityLibrary.map((a) => a.id).toSet();
    for (final id in ['running','walking','hiking','cycling','swimming','rowing',
                       'weight-training','yoga','soccer','basketball','tennis']) {
      expect(ids.contains(id), isTrue, reason: 'missing $id');
    }
  });

  test('ids are unique', () {
    final ids = activityLibrary.map((a) => a.id).toList();
    expect(ids.length, ids.toSet().length);
  });

  test('foot-based cardio tracks elevation; swimming tracks stroke not elevation', () {
    for (final id in ['running','walking','hiking']) {
      expect(activityById(id)!.tracksElevation, isTrue, reason: '$id elevation');
      expect(activityById(id)!.logKind, ActivityLogKind.distanceCardio);
    }
    final swim = activityById('swimming')!;
    expect(swim.tracksStroke, isTrue);
    expect(swim.tracksElevation, isFalse);
  });

  test('strength/sport/duration logKinds are represented', () {
    expect(activityById('weight-training')!.logKind, ActivityLogKind.strength);
    expect(activityById('soccer')!.logKind, ActivityLogKind.sport);
    expect(activityById('yoga')!.logKind, ActivityLogKind.duration);
  });

  test('categories partition the library', () {
    expect(activityCategories(), containsAll(['Cardio','Sport','Strength','Mind-body']));
    for (final c in activityCategories()) {
      expect(activitiesInCategory(c), isNotEmpty);
    }
  });
}
