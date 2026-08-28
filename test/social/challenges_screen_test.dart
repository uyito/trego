import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/social/screens/challenges_screen.dart';
import 'package:trego/social/social_service.dart';

import '../helpers/test_app.dart';

/// Fake SocialService: serves fixed challenges and records action calls.
class _FakeSocialService implements SocialService {
  List<Map<String, dynamic>> challenges;
  bool joinResult = true;
  bool leaveResult = true;
  Map<String, dynamic>? createdChallenge;

  String? joinedChallengeId;
  String? leftChallengeId;
  Map<String, dynamic>? lastCreateArgs;

  _FakeSocialService({this.challenges = const []});

  @override
  Future<List<Map<String, dynamic>>> getChallenges({bool? isPublic}) async => challenges;

  @override
  Future<bool> joinChallenge(String challengeId) async {
    joinedChallengeId = challengeId;
    return joinResult;
  }

  @override
  Future<bool> leaveChallenge(String challengeId) async {
    leftChallengeId = challengeId;
    return leaveResult;
  }

  @override
  Future<Map<String, dynamic>?> createChallenge({
    required String title,
    required String description,
    required String type,
    required int target,
    required int duration,
    bool isPublic = true,
    int? maxParticipants,
  }) async {
    lastCreateArgs = {
      'title': title,
      'description': description,
      'type': type,
      'target': target,
      'duration': duration,
      'isPublic': isPublic,
      'maxParticipants': maxParticipants,
    };
    return createdChallenge;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Silent SocialService so the base render test doesn't hit the network.
class _StubSocial implements SocialService {
  @override
  Future<List<Map<String, dynamic>>> getChallenges({bool? isPublic}) async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _challenge({
  String id = 'c1',
  String title = 'Step It Up',
  String type = 'steps',
  String status = 'active',
  bool isParticipating = false,
  double userProgress = 0,
  int target = 10000,
  bool isPublic = true,
  bool isCreator = false,
}) =>
    {
      'id': id,
      'title': title,
      'description': 'Walk more every day',
      'type': type,
      'status': status,
      'isParticipating': isParticipating,
      'userProgress': userProgress,
      'target': target,
      'duration': 30,
      'participantsCount': 4,
      'isPublic': isPublic,
      'isCreator': isCreator,
    };

void main() {
  initTestEnv();

  Widget wrap(SocialService service) => testApp(ChallengesScreen(service: service));

  testWidgets('renders with a stubbed service and shows tab labels', (tester) async {
    await tester.pumpWidget(wrap(_StubSocial()));
    await tester.pumpAndSettle();

    expect(find.byType(ChallengesScreen), findsOneWidget);
    expect(find.textContaining('Active'), findsWidgets);
    expect(find.textContaining('Available'), findsWidgets);
    expect(find.textContaining('Completed'), findsWidgets);
  });

  testWidgets('renders an available challenge card with a Join button', (tester) async {
    final svc = _FakeSocialService(challenges: [
      _challenge(id: 'c1', title: 'Step It Up', isParticipating: false),
    ]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    // Available tab is the second tab; switch to it.
    await tester.tap(find.textContaining('Available'));
    await tester.pumpAndSettle();

    expect(find.text('Step It Up'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Join'), findsOneWidget);
  });

  testWidgets('joining a challenge calls joinChallenge and reloads', (tester) async {
    final svc = _FakeSocialService(challenges: [
      _challenge(id: 'c1', title: 'Step It Up', isParticipating: false),
    ]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Available'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Join'));
    await tester.pumpAndSettle();

    expect(svc.joinedChallengeId, 'c1');
  });

  testWidgets('leaving an active challenge calls leaveChallenge', (tester) async {
    final svc = _FakeSocialService(challenges: [
      _challenge(id: 'c1', title: 'Step It Up', isParticipating: true, userProgress: 5000),
    ]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    // Active tab is the default (first) tab.
    expect(find.text('Step It Up'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Leave'));
    await tester.pumpAndSettle();

    expect(svc.leftChallengeId, 'c1');
  });

  testWidgets('create-challenge dialog submits via createChallenge', (tester) async {
    final svc = _FakeSocialService();
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Challenge Title'), 'My Challenge');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
    await tester.pumpAndSettle();

    expect(svc.lastCreateArgs?['title'], 'My Challenge');
  });
}
