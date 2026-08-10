# Activity Tracking — Flutter Implementation Plan (Phase 1, Parts 2 & 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add a multi-activity logging experience to the Flutter app — a curated activity library, per-activity logging forms, save to the backend, plus history and PR views — replacing the crude `SimpleWorkoutTracker`.

**Architecture:** A bundled const `activityLibrary` drives the picker; a `logKind` per activity selects the logging form (strength / distanceCardio / sport / duration). An injectable `WorkoutService` (thin wrapper over `ApiClient`, testable with a fake) calls the `/api/workouts` backend. Screens live under `lib/workouts/activity/`.

**Tech Stack:** Flutter 3.44 / Dart, `provider`, `dio`-backed `ApiClient`, `flutter_test`.

## Global Constraints

- Service paths are relative to the base URL, which already ends in `/api` — use `/workouts/...` (NO `/api` prefix), matching `PushApi` (`lib/push/push_api.dart`). Do NOT copy `SocialService`'s `/api/...` prefix.
- `WorkoutService` takes an optional `ApiClient` ctor param defaulting to `ApiClient.instance` (mirror `PushApi`). `ApiClient.get/post` return a `Response` whose `.data` is the decoded JSON map; success is `response.data['success'] == true`.
- Units: distance km, elevation m, weight kg. `duration` sent to the backend is **minutes** (backend derives pace from it).
- `logKind` values (must match backend exactly): `strength`, `distanceCardio`, `sport`, `duration`.
- `lib/workouts` is EXEMPT from `scripts/check-tokens.sh` — follow existing workout-screen styling (`Theme.of(context)`); do not block on token purity.
- Widget tests that read `context.tokens` must wrap in `TregoTheme` (only if you use tokens; the exempt dir need not).
- Keep the existing Flutter test suite green. The pre-existing 6 `notifications_screen_test.dart` failures are unrelated to this work (documented on `main`) — do not attempt to fix them here.

---

## Part 2 — `feat/activity-logging`

### Task 1: Activity library (bundled const data)

**Files:**
- Create: `lib/workouts/activity/activity.dart`
- Create: `lib/workouts/activity/activity_library.dart`
- Test: `test/workouts/activity_library_test.dart`

**Interfaces:**
- Produces: `enum ActivityLogKind { strength, distanceCardio, sport, duration }`; `class Activity { final String id, name, category; final ActivityLogKind logKind; final bool tracksElevation, tracksStroke; const Activity(...); }`; `const List<Activity> activityLibrary`; `Activity? activityById(String id)`; `List<String> activityCategories()`; `List<Activity> activitiesInCategory(String category)`.

- [ ] **Step 1: Write the failing test**

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/workouts/activity_library_test.dart`
Expected: FAIL — files/symbols do not exist.

- [ ] **Step 3: Implement**

`lib/workouts/activity/activity.dart`:

```dart
enum ActivityLogKind { strength, distanceCardio, sport, duration }

class Activity {
  final String id;
  final String name;
  final String category; // 'Cardio' | 'Sport' | 'Strength' | 'Mind-body'
  final ActivityLogKind logKind;
  final bool tracksElevation;
  final bool tracksStroke;

  const Activity({
    required this.id,
    required this.name,
    required this.category,
    required this.logKind,
    this.tracksElevation = false,
    this.tracksStroke = false,
  });
}
```

`lib/workouts/activity/activity_library.dart` — provide a const list of ~30 activities. Include at minimum every id asserted in the test. Example entries (fill out the full set following this shape):

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/workouts/activity_library_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/workouts/activity/activity.dart lib/workouts/activity/activity_library.dart test/workouts/activity_library_test.dart
git commit -m "feat(activity): bundled activity library (categorized, logKind-tagged)"
```

---

### Task 2: Dart models (session + sets)

**Files:**
- Create: `lib/workouts/activity/activity_models.dart`
- Test: `test/workouts/activity_models_test.dart`

**Interfaces:**
- Produces:
  - `class ExerciseSet { int? setNumber, reps; double? weight; int? rpe, restTime; ExerciseSet({...}); Map<String,dynamic> toJson(); factory ExerciseSet.fromJson(Map); }`
  - `class ExerciseLog { String exerciseId, name; List<ExerciseSet> sets; ExerciseLog({...}); Map<String,dynamic> toJson(); factory ExerciseLog.fromJson(Map); }`
  - `class ActivitySession { String? id; String activityType; String logKind; String? sessionName, notes, stroke; int? duration, perceivedExertion; double? distance, elevationGain, avgPace; List<ExerciseLog> exercises; Map<String,dynamic> toLogPayload(); factory ActivitySession.fromJson(Map); }`
  - `toLogPayload()` emits exactly the keys the backend `logSession` reads: `activityType, logKind, sessionName, notes, duration, distance, elevationGain, stroke, perceivedExertion, exercises[]` (each exercise `{exerciseId, name, sets:[{setNumber,reps,weight,rpe,restTime}]}`), omitting nulls.

- [ ] **Step 1: Write the failing test**

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/workouts/activity_models_test.dart` — FAIL (models missing).

- [ ] **Step 3: Implement** `lib/workouts/activity/activity_models.dart`:

```dart
class ExerciseSet {
  int? setNumber, reps, rpe, restTime;
  double? weight;
  ExerciseSet({this.setNumber, this.reps, this.weight, this.rpe, this.restTime});

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (setNumber != null) m['setNumber'] = setNumber;
    if (reps != null) m['reps'] = reps;
    if (weight != null) m['weight'] = weight;
    if (rpe != null) m['rpe'] = rpe;
    if (restTime != null) m['restTime'] = restTime;
    return m;
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> j) => ExerciseSet(
        setNumber: (j['setNumber'] as num?)?.toInt(),
        reps: (j['reps'] as num?)?.toInt(),
        weight: (j['weight'] as num?)?.toDouble(),
        rpe: (j['rpe'] as num?)?.toInt(),
        restTime: (j['restTime'] as num?)?.toInt(),
      );
}

class ExerciseLog {
  String exerciseId, name;
  List<ExerciseSet> sets;
  ExerciseLog({required this.exerciseId, required this.name, this.sets = const []});

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'name': name,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> j) => ExerciseLog(
        exerciseId: j['exerciseId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        sets: ((j['sets'] as List?) ?? const [])
            .map((e) => ExerciseSet.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class ActivitySession {
  String? id, sessionName, notes, stroke;
  String activityType, logKind;
  int? duration, perceivedExertion;
  double? distance, elevationGain, avgPace;
  List<ExerciseLog> exercises;

  ActivitySession({
    this.id, required this.activityType, required this.logKind,
    this.sessionName, this.notes, this.stroke, this.duration,
    this.perceivedExertion, this.distance, this.elevationGain, this.avgPace,
    this.exercises = const [],
  });

  Map<String, dynamic> toLogPayload() {
    final m = <String, dynamic>{'activityType': activityType, 'logKind': logKind};
    if (sessionName != null) m['sessionName'] = sessionName;
    if (notes != null) m['notes'] = notes;
    if (duration != null) m['duration'] = duration;
    if (distance != null) m['distance'] = distance;
    if (elevationGain != null) m['elevationGain'] = elevationGain;
    if (stroke != null) m['stroke'] = stroke;
    if (perceivedExertion != null) m['perceivedExertion'] = perceivedExertion;
    if (exercises.isNotEmpty) m['exercises'] = exercises.map((e) => e.toJson()).toList();
    return m;
  }

  factory ActivitySession.fromJson(Map<String, dynamic> j) => ActivitySession(
        id: j['id'] as String?,
        activityType: j['activityType'] as String? ?? '',
        logKind: j['logKind'] as String? ?? 'duration',
        sessionName: j['sessionName'] as String?,
        notes: j['notes'] as String?,
        stroke: j['stroke'] as String?,
        duration: (j['duration'] as num?)?.toInt(),
        perceivedExertion: (j['perceivedExertion'] as num?)?.toInt(),
        distance: (j['distance'] as num?)?.toDouble(),
        elevationGain: (j['elevationGain'] as num?)?.toDouble(),
        avgPace: (j['avgPace'] as num?)?.toDouble(),
        exercises: ((j['exercises'] as List?) ?? const [])
            .map((e) => ExerciseLog.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
```

- [ ] **Step 4: Run test to verify it passes** — `flutter test test/workouts/activity_models_test.dart` → PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/workouts/activity/activity_models.dart test/workouts/activity_models_test.dart
git commit -m "feat(activity): session/exercise/set Dart models with payload + fromJson"
```

---

### Task 3: `WorkoutService`

**Files:**
- Create: `lib/workouts/activity/workout_service.dart`
- Test: `test/workouts/workout_service_test.dart`

**Interfaces:**
- Consumes: `ApiClient` (`post(path, {data})`, `get(path)`), `ActivitySession` (Task 2).
- Produces: `class WorkoutService { WorkoutService({ApiClient? apiClient}); Future<ActivitySession?> logSession(ActivitySession s); Future<List<ActivitySession>> getHistory(); Future<ActivitySession?> getSessionDetail(String id); Future<List<Map<String,dynamic>>> getPRs(); }`
  - `logSession` → `POST /workouts/sessions` with `s.toLogPayload()`; returns `ActivitySession.fromJson(response.data['session'])` on success, else null.
  - `getHistory` → `GET /workouts/sessions`; maps `response.data['sessions']` to `ActivitySession.fromJson`; `[]` on failure.
  - `getSessionDetail` → `GET /workouts/sessions/$id`; `fromJson(session)` or null.
  - `getPRs` → `GET /workouts/prs`; `List<Map<String,dynamic>>.from(response.data['prs'])`; `[]` on failure.

- [ ] **Step 1: Write the failing test** (fake `ApiClient`, mirroring `test/push/push_api_test.dart`)

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/shared/api_client.dart';
import 'package:trego/workouts/activity/activity_models.dart';
import 'package:trego/workouts/activity/workout_service.dart';

class _FakeApiClient implements ApiClient {
  String? lastMethod, lastPath;
  dynamic lastData;
  Map<String, dynamic>? response;
  bool throwError = false;

  Response<T> _resp<T>(String path) =>
      Response<T>(data: response as T, statusCode: 200, requestOptions: RequestOptions(path: path));

  @override
  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'POST'; lastPath = path; lastData = data;
    if (throwError) throw const ApiException(message: 'boom', statusCode: 500);
    return _resp<T>(path);
  }

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'GET'; lastPath = path;
    if (throwError) throw const ApiException(message: 'boom', statusCode: 500);
    return _resp<T>(path);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _FakeApiClient api;
  late WorkoutService sut;
  setUp(() { api = _FakeApiClient(); sut = WorkoutService(apiClient: api); });

  test('logSession POSTs payload and returns parsed session', () async {
    api.response = {'success': true, 'session': {'id': 's1', 'activityType': 'hiking', 'logKind': 'distanceCardio'}};
    final out = await sut.logSession(ActivitySession(activityType: 'hiking', logKind: 'distanceCardio', distance: 12.5));
    expect(api.lastMethod, 'POST');
    expect(api.lastPath, '/workouts/sessions');
    expect((api.lastData as Map)['distance'], 12.5);
    expect(out!.id, 's1');
  });

  test('logSession returns null on error', () async {
    api.throwError = true;
    expect(await sut.logSession(ActivitySession(activityType: 'yoga', logKind: 'duration')), isNull);
  });

  test('getHistory maps sessions', () async {
    api.response = {'success': true, 'sessions': [{'id': 'a', 'activityType': 'running', 'logKind': 'distanceCardio'}]};
    final out = await sut.getHistory();
    expect(api.lastPath, '/workouts/sessions');
    expect(out.single.id, 'a');
  });

  test('getPRs returns list of maps', () async {
    api.response = {'success': true, 'prs': [{'activityType': 'running', 'bestDistance': 10.0}]};
    final prs = await sut.getPRs();
    expect(api.lastPath, '/workouts/prs');
    expect(prs.single['activityType'], 'running');
  });

  test('getHistory returns [] on error', () async {
    api.throwError = true;
    expect(await sut.getHistory(), isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails** — `flutter test test/workouts/workout_service_test.dart` → FAIL.

- [ ] **Step 3: Implement** `lib/workouts/activity/workout_service.dart`:

```dart
import '../../shared/api_client.dart';
import 'activity_models.dart';

/// Injectable wrapper over [ApiClient] for the /workouts activity endpoints.
class WorkoutService {
  final ApiClient _apiClient;
  WorkoutService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient.instance;

  Future<ActivitySession?> logSession(ActivitySession session) async {
    try {
      final r = await _apiClient.post('/workouts/sessions', data: session.toLogPayload());
      if (r.data['success'] == true && r.data['session'] != null) {
        return ActivitySession.fromJson(Map<String, dynamic>.from(r.data['session']));
      }
      return null;
    } catch (e) {
      print('logSession failed: $e');
      return null;
    }
  }

  Future<List<ActivitySession>> getHistory() async {
    try {
      final r = await _apiClient.get('/workouts/sessions');
      if (r.data['success'] == true) {
        return ((r.data['sessions'] as List?) ?? const [])
            .map((e) => ActivitySession.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      print('getHistory failed: $e');
      return [];
    }
  }

  Future<ActivitySession?> getSessionDetail(String id) async {
    try {
      final r = await _apiClient.get('/workouts/sessions/$id');
      if (r.data['success'] == true && r.data['session'] != null) {
        return ActivitySession.fromJson(Map<String, dynamic>.from(r.data['session']));
      }
      return null;
    } catch (e) {
      print('getSessionDetail failed: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPRs() async {
    try {
      final r = await _apiClient.get('/workouts/prs');
      if (r.data['success'] == true) {
        return List<Map<String, dynamic>>.from(r.data['prs'] ?? const []);
      }
      return [];
    } catch (e) {
      print('getPRs failed: $e');
      return [];
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes** — `flutter test test/workouts/workout_service_test.dart` → PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/workouts/activity/workout_service.dart test/workouts/workout_service_test.dart
git commit -m "feat(activity): WorkoutService over ApiClient (log/history/detail/prs)"
```

---

### Task 4: Rest timer widget (strength)

**Files:**
- Create: `lib/workouts/activity/widgets/rest_timer.dart`
- Test: `test/workouts/rest_timer_test.dart`

**Interfaces:**
- Produces: `class RestTimer extends StatefulWidget { final int seconds; final VoidCallback? onDone; const RestTimer({required this.seconds, this.onDone}); }` — a countdown showing `mm:ss` from `seconds` to 0, a "Skip" button that calls `onDone`, and calls `onDone` when it reaches 0. Uses a `Timer.periodic`; cancels it in `dispose`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/activity/widgets/rest_timer.dart';

void main() {
  testWidgets('counts down and fires onDone at zero', (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: RestTimer(seconds: 2, onDone: () => done = true))));
    expect(find.text('00:02'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(done, isTrue);
  });

  testWidgets('Skip fires onDone immediately', (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: RestTimer(seconds: 90, onDone: () => done = true))));
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(done, isTrue);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — FAIL (widget missing).

- [ ] **Step 3: Implement** — a `StatefulWidget` with an `int _remaining` initialized to `widget.seconds`, a `Timer.periodic(const Duration(seconds:1))` decrementing `_remaining` and calling `widget.onDone?.call()` + cancelling at 0, a `Text` showing `_fmt(_remaining)` as `mm:ss`, and a `TextButton('Skip')` that cancels the timer and calls `onDone`. Cancel the timer in `dispose`. Guard `onDone` so it fires once.

- [ ] **Step 4: Run to verify it passes** — PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/workouts/activity/widgets/rest_timer.dart test/workouts/rest_timer_test.dart
git commit -m "feat(activity): rest timer widget for strength logging"
```

---

### Task 5: Logging flow — picker + per-logKind forms

**Files:**
- Create: `lib/workouts/activity/activity_picker_screen.dart` (browse by category → returns/opens the chosen `Activity`)
- Create: `lib/workouts/activity/log_activity_screen.dart` (routes to the right form by `activity.logKind`; owns Save)
- Create: `lib/workouts/activity/widgets/strength_form.dart`, `cardio_form.dart`, `sport_form.dart`, `duration_form.dart`
- Test: `test/workouts/activity_picker_test.dart`, `test/workouts/log_activity_test.dart`

**Interfaces:**
- Consumes: `activityLibrary`/`activityCategories`/`activitiesInCategory`, `Activity`, `ActivitySession`, `WorkoutService` (inject via optional ctor param, default `WorkoutService()`), `RestTimer`.
- Produces: `ActivityPickerScreen` (a categorized list; tapping an `Activity` pushes `LogActivityScreen(activity: a, service: ...)`). `LogActivityScreen` builds an `ActivitySession` from form state and calls `service.logSession(...)`, then pops with a success SnackBar. Each `*_form.dart` is a widget taking a callback that yields its slice of the session (cardio → distance/duration/elevation/stroke; strength → `List<ExerciseLog>` with a per-exercise set editor using `RestTimer`; sport → duration + RPE + notes; duration → duration + notes).

- [ ] **Step 1: Write the failing widget tests**

```dart
// test/workouts/activity_picker_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/activity/activity_picker_screen.dart';

void main() {
  testWidgets('picker lists categories and activities', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ActivityPickerScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Soccer'), findsOneWidget);
    expect(find.text('Weight Training'), findsOneWidget);
  });
}
```

```dart
// test/workouts/log_activity_test.dart — cardio path saves via an injected fake service
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/activity/activity.dart';
import 'package:trego/workouts/activity/activity_library.dart';
import 'package:trego/workouts/activity/activity_models.dart';
import 'package:trego/workouts/activity/log_activity_screen.dart';
import 'package:trego/workouts/activity/workout_service.dart';

class _CapturingService extends WorkoutService {
  ActivitySession? logged;
  _CapturingService() : super(apiClient: null);
  @override
  Future<ActivitySession?> logSession(ActivitySession s) async { logged = s; return s..id = 'saved'; }
}

void main() {
  testWidgets('cardio form saves distance + duration', (tester) async {
    final svc = _CapturingService();
    await tester.pumpWidget(MaterialApp(home: LogActivityScreen(activity: activityById('hiking')!, service: svc)));
    await tester.enterText(find.byKey(const Key('distance-field')), '12.5');
    await tester.enterText(find.byKey(const Key('duration-field')), '95');
    await tester.tap(find.byKey(const Key('save-activity')));
    await tester.pumpAndSettle();
    expect(svc.logged!.activityType, 'hiking');
    expect(svc.logged!.distance, 12.5);
    expect(svc.logged!.duration, 95);
  });
}
```

> `WorkoutService` must accept `apiClient: null` in its ctor (it already defaults to `ApiClient.instance` when null — the fake overrides `logSession` so the real client is never called). If constructing `WorkoutService(apiClient: null)` in a test would touch `ApiClient.instance`, add a no-network guard: the subclass overrides every method it uses, so the base ctor's default is never exercised. Confirm during implementation; if `ApiClient.instance` is touched at construction, change `_CapturingService` to not call `super` with a real client (e.g., give `WorkoutService` a `@visibleForTesting` bare constructor).

- [ ] **Step 2: Run to verify they fail** — FAIL (screens missing).

- [ ] **Step 3: Implement** the picker + `LogActivityScreen` + four forms. Requirements:
  - Picker: `ListView` grouped by `activityCategories()`, each with `activitiesInCategory(c)` as `ListTile`s; tapping pushes `LogActivityScreen`.
  - `LogActivityScreen`: `switch (activity.logKind)` selects the form; a Save button keyed `save-activity` builds the `ActivitySession` (always sets `activityType: activity.id`, `logKind: activity.logKind.name`) and awaits `service.logSession`, then `Navigator.pop(context)` + success SnackBar on non-null.
  - Cardio form: `TextField`s keyed `distance-field`, `duration-field`, plus `elevation-field` when `activity.tracksElevation`, and a stroke dropdown when `activity.tracksStroke`. Parse to double/int.
  - Strength form: add-exercise (from a small exercise sub-list per `weight-training`, or a free-text exercise name for v1), each exercise has an add-set row (reps + weight) and shows a `RestTimer(seconds: 90)` after adding a set.
  - Sport form: `duration-field` + an RPE slider (1–10) → `perceivedExertion` + notes.
  - Duration form: `duration-field` + notes.
  - Keep each form file focused (one widget each).

- [ ] **Step 4: Run to verify they pass** — both test files PASS. Then run `flutter test` (whole suite) to confirm no regressions.

- [ ] **Step 5: Commit**

```bash
git add lib/workouts/activity/ test/workouts/activity_picker_test.dart test/workouts/log_activity_test.dart
git commit -m "feat(activity): activity picker + per-logKind logging forms with save"
```

---

### Task 6: Replace `SimpleWorkoutTracker` in `WorkoutHub`

**Files:**
- Modify: `lib/workouts/workout_hub.dart`
- Delete: `lib/workouts/simple_workout_tracker.dart`
- Test: `test/workouts/workout_hub_test.dart`

**Interfaces:**
- Consumes: `ActivityPickerScreen` (Task 5).
- Produces: WorkoutHub's first tab (relabeled "Log Activity", icon `Icons.add`) shows `ActivityPickerScreen`; the "Workout Plans" tab is unchanged. No remaining references to `SimpleWorkoutTracker`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/workout_hub.dart';
import 'package:trego/workouts/activity/activity_picker_screen.dart';

void main() {
  testWidgets('WorkoutHub shows the activity picker on the log tab', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WorkoutHub()));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityPickerScreen), findsOneWidget);
    expect(find.text('Log Activity'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run to verify it fails** — FAIL.

- [ ] **Step 3: Implement** — in `workout_hub.dart` replace the `import 'simple_workout_tracker.dart';` with `import 'activity/activity_picker_screen.dart';`, change the first `Tab` label to `'Log Activity'` / icon `Icons.add`, and the first `TabBarView` child from `SimpleWorkoutTracker()` to `const ActivityPickerScreen()`. Delete `lib/workouts/simple_workout_tracker.dart`. Run `grep -rn SimpleWorkoutTracker lib test` → no matches.

- [ ] **Step 4: Run to verify it passes** — test PASS; then `flutter test` whole suite green (minus the known-unrelated 6 notifications failures).

- [ ] **Step 5: Commit**

```bash
git add lib/workouts/workout_hub.dart test/workouts/workout_hub_test.dart
git rm lib/workouts/simple_workout_tracker.dart
git commit -m "feat(activity): replace SimpleWorkoutTracker with activity picker in WorkoutHub"
```

---

### Task 7: Part 2 green + analyze + PR (deploy already live)

- [ ] **Step 1:** `flutter analyze` — no new errors (pre-existing infos OK).
- [ ] **Step 2:** `flutter test` — all green except the documented 6 `notifications_screen_test.dart` pre-existing failures.
- [ ] **Step 3:** Push `feat/activity-logging`, open PR to main; body references the spec + notes the SimpleWorkoutTracker removal.
- [ ] **Step 4:** Squash-merge after review, delete branch, verify main green.

---

## Part 3 — `feat/activity-history-prs`

### Task 8: History screen

**Files:**
- Create: `lib/workouts/activity/history_screen.dart`
- Test: `test/workouts/history_screen_test.dart`

**Interfaces:**
- Consumes: `WorkoutService.getHistory()`, `ActivitySession`, `activityById` (for display name).
- Produces: `WorkoutHistoryScreen({WorkoutService? service})` — loads history in `initState`, shows a loading spinner, then a `ListView` of sessions (activity name, date, primary metric: distance for distanceCardio, total volume for strength, duration otherwise); empty-state text when none; tapping a row is a no-op stub for v1 (detail wiring optional).

- [ ] **Step 1: Write the failing test** — inject a fake `WorkoutService` (subclass overriding `getHistory` to return two `ActivitySession`s), pump `WorkoutHistoryScreen(service: fake)`, `pumpAndSettle`, assert both activity names render and the empty-state is absent.

- [ ] **Step 2: Run to verify it fails.**

- [ ] **Step 3: Implement** the screen per the interface (FutureBuilder or initState+setState; follow `friends_screen.dart` loading/empty patterns).

- [ ] **Step 4: Run to verify it passes; whole suite green.**

- [ ] **Step 5: Commit** `feat(activity): workout history screen`.

### Task 9: PRs screen

**Files:**
- Create: `lib/workouts/activity/prs_screen.dart`
- Test: `test/workouts/prs_screen_test.dart`

**Interfaces:**
- Consumes: `WorkoutService.getPRs()` (list of maps).
- Produces: `PRsScreen({WorkoutService? service})` — renders cardio PR cards (`activityType`: best distance / best pace / best elevation) and strength PR cards (`name`: heaviest / est. 1RM), reading the map keys the backend emits (`bestDistance/bestPace/bestElevation/heaviestWeight/estimatedOneRepMax/exerciseId/activityType/name`); empty-state when none.

- [ ] **Step 1: Write the failing test** — fake service returns one cardio PR + one strength PR map; assert both render with their headline numbers.

- [ ] **Step 2–4:** fail → implement → pass; whole suite green.

- [ ] **Step 5: Commit** `feat(activity): personal-records screen`.

### Task 10: Wire history + PRs into the app + Part 3 PR

**Files:**
- Modify: `lib/workouts/workout_hub.dart` (or the activity picker app bar) to add navigation to History and PRs (e.g., app-bar actions/icons).
- Test: extend `workout_hub_test.dart` to assert the History/PRs entry points exist.

- [ ] Steps: add the entry points (icon buttons pushing `WorkoutHistoryScreen`/`PRsScreen`), test they're present, `flutter analyze` + `flutter test` green, push `feat/activity-history-prs`, PR, squash-merge, verify main green.

---

## Backend follow-ups to fold in during Part 2/3 (from the backend final review)

These are backend changes; make them as a small backend PR alongside Part 2 (or note as accepted):
1. **History/PRs scope:** filter `getHistory`/`computePRs` to `logKind != null` so plan-based sessions don't appear as logged activities. (Update the `getHistory` service test, whose fixtures currently omit `logKind`.)
2. **Document `duration` = minutes** in `ActivitySessionService.logSession` Javadoc.
3. **PR-shape note:** the `/workouts/prs` contract differs from `MetricsService` run-PRs — leave a comment; no merge of the two in v1.
