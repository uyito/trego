import 'package:flutter_test/flutter_test.dart';
import 'package:trego/workouts/activity/prs_screen.dart';
import 'package:trego/workouts/activity/workout_service.dart';

import '../helpers/test_app.dart';

class _FakeService extends WorkoutService {
  final List<Map<String, dynamic>> prs;
  _FakeService(this.prs);
  @override
  Future<List<Map<String, dynamic>>> getPRs() async => prs;
}

void main() {
  initTestEnv();

  testWidgets('renders cardio and strength PR cards', (tester) async {
    await tester.pumpWidget(testApp(PRsScreen(
        service: _FakeService([
      {
        'activityType': 'running',
        'bestDistance': 10.5,
        'bestPace': 305, // 5:05 /km
        'bestElevation': 120,
      },
      {
        'exerciseId': 'sq',
        'name': 'Squat',
        'heaviestWeight': 140,
        'estimatedOneRepMax': 162.5,
      },
    ]))));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('10.5 km'), findsOneWidget);
    expect(find.text('5:05 /km'), findsOneWidget);
    expect(find.text('120 m'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('140 kg'), findsOneWidget);
    expect(find.text('162.5 kg'), findsOneWidget);
    expect(find.text('No personal records yet'), findsNothing);
  });

  testWidgets('null values show a dash, not a crash', (tester) async {
    await tester.pumpWidget(testApp(PRsScreen(
        service: _FakeService([
      {'activityType': 'running', 'bestDistance': 5, 'bestPace': null},
    ]))));
    await tester.pumpAndSettle();
    expect(find.text('5 km'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('shows empty state when no PRs', (tester) async {
    await tester.pumpWidget(testApp(PRsScreen(service: _FakeService([]))));
    await tester.pumpAndSettle();
    expect(find.text('No personal records yet'), findsOneWidget);
  });
}
