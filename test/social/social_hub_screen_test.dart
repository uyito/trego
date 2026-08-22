import 'package:flutter_test/flutter_test.dart';
import 'package:trego/social/screens/social_hub_screen.dart';
import 'package:trego/social/social_service.dart';
import 'package:trego/social/screens/friends_screen.dart';

import '../helpers/test_app.dart';

class _StubSocial implements SocialService {
  @override
  Future<List<Map<String, dynamic>>> getFriends() async => const [];
  @override
  Future<List<Map<String, dynamic>>> getFriendRequests() async => const [];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  initTestEnv();

  testWidgets('Social hub shows Feed/Friends/Challenges and can open Friends tab', (tester) async {
    await tester.pumpWidget(testApp(SocialHubScreen(service: _StubSocial(), initialTab: 1)));
    await tester.pumpAndSettle();
    expect(find.text('Feed'), findsWidgets);
    expect(find.text('Friends'), findsWidgets);
    expect(find.text('Challenges'), findsWidgets);
    expect(find.byType(FriendsScreen), findsOneWidget); // initialTab=1 => Friends
  });
}
