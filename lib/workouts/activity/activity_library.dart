import 'activity.dart';

const List<Activity> activityLibrary = [
  // Cardio
  Activity(id: 'running', name: 'Running', category: 'Cardio', logKind: ActivityLogKind.distanceCardio, tracksElevation: true),
  Activity(id: 'walking', name: 'Walking', category: 'Cardio', logKind: ActivityLogKind.distanceCardio, tracksElevation: true),
  Activity(id: 'hiking', name: 'Hiking', category: 'Cardio', logKind: ActivityLogKind.distanceCardio, tracksElevation: true),
  Activity(id: 'cycling', name: 'Cycling', category: 'Cardio', logKind: ActivityLogKind.distanceCardio, tracksElevation: true),
  Activity(id: 'swimming', name: 'Swimming', category: 'Cardio', logKind: ActivityLogKind.distanceCardio, tracksStroke: true),
  Activity(id: 'rowing', name: 'Rowing', category: 'Cardio', logKind: ActivityLogKind.distanceCardio),
  Activity(id: 'elliptical', name: 'Elliptical', category: 'Cardio', logKind: ActivityLogKind.duration),
  Activity(id: 'stair-climber', name: 'Stair Climber', category: 'Cardio', logKind: ActivityLogKind.duration),
  // Sport
  Activity(id: 'soccer', name: 'Soccer', category: 'Sport', logKind: ActivityLogKind.sport),
  Activity(id: 'basketball', name: 'Basketball', category: 'Sport', logKind: ActivityLogKind.sport),
  Activity(id: 'tennis', name: 'Tennis', category: 'Sport', logKind: ActivityLogKind.sport),
  Activity(id: 'volleyball', name: 'Volleyball', category: 'Sport', logKind: ActivityLogKind.sport),
  Activity(id: 'badminton', name: 'Badminton', category: 'Sport', logKind: ActivityLogKind.sport),
  Activity(id: 'golf', name: 'Golf', category: 'Sport', logKind: ActivityLogKind.sport),
  Activity(id: 'climbing', name: 'Climbing', category: 'Sport', logKind: ActivityLogKind.sport),
  Activity(id: 'skiing', name: 'Skiing', category: 'Sport', logKind: ActivityLogKind.sport),
  // Strength
  Activity(id: 'weight-training', name: 'Weight Training', category: 'Strength', logKind: ActivityLogKind.strength),
  Activity(id: 'bodyweight', name: 'Bodyweight', category: 'Strength', logKind: ActivityLogKind.strength),
  Activity(id: 'powerlifting', name: 'Powerlifting', category: 'Strength', logKind: ActivityLogKind.strength),
  Activity(id: 'crossfit', name: 'CrossFit', category: 'Strength', logKind: ActivityLogKind.strength),
  // Mind-body
  Activity(id: 'yoga', name: 'Yoga', category: 'Mind-body', logKind: ActivityLogKind.duration),
  Activity(id: 'pilates', name: 'Pilates', category: 'Mind-body', logKind: ActivityLogKind.duration),
  Activity(id: 'stretching', name: 'Stretching', category: 'Mind-body', logKind: ActivityLogKind.duration),
  Activity(id: 'meditation', name: 'Meditation', category: 'Mind-body', logKind: ActivityLogKind.duration),
];

Activity? activityById(String id) {
  for (final a in activityLibrary) { if (a.id == id) return a; }
  return null;
}

List<String> activityCategories() {
  final seen = <String>[];
  for (final a in activityLibrary) { if (!seen.contains(a.category)) seen.add(a.category); }
  return seen;
}

List<Activity> activitiesInCategory(String category) =>
    activityLibrary.where((a) => a.category == category).toList();
