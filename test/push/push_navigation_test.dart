import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/push/push_navigation.dart';
import 'package:trego/social/screens/friends_screen.dart';
import 'package:trego/social/screens/social_hub_screen.dart';
import 'package:trego/social/social_service.dart';
import 'package:trego/social/widgets/comments_sheet.dart';
import 'package:trego/shared/theme/trego_theme.dart';

import '../helpers/test_app.dart';

/// Silent SocialService so pushed screens/sheets don't hit the network.
class _StubSocial implements SocialService {
  @override
  Future<List<Map<String, dynamic>>> getFriends() async => const [];
  @override
  Future<List<Map<String, dynamic>>> getFriendRequests() async => const [];
  @override
  Future<List<Map<String, dynamic>>> getComments(String postId) async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  initTestEnv();

  Future<GlobalKey<NavigatorState>> pumpApp(WidgetTester tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      theme: TregoTheme.light(),
      darkTheme: TregoTheme.dark(),
      home: const Scaffold(body: Text('home')),
    ));
    return key;
  }

  testWidgets('friend_request push opens the Social hub on the Friends tab', (tester) async {
    final key = await pumpApp(tester);
    handlePushDestination(
      {'type': 'friend_request', 'targetType': 'friend_request', 'targetId': 'r1'},
      navigatorKey: key,
      social: _StubSocial(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SocialHubScreen), findsOneWidget);
    expect(find.byType(FriendsScreen), findsOneWidget);
  });

  testWidgets('post mention push opens the comments sheet', (tester) async {
    final key = await pumpApp(tester);
    handlePushDestination(
      {'type': 'mention', 'targetType': 'post', 'targetId': 'p1'},
      navigatorKey: key,
      social: _StubSocial(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CommentsSheet), findsOneWidget);
  });

  testWidgets('unknown type navigates nowhere', (tester) async {
    final key = await pumpApp(tester);
    handlePushDestination(
      {'type': 'mystery'},
      navigatorKey: key,
      social: _StubSocial(),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FriendsScreen), findsNothing);
    expect(find.byType(CommentsSheet), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
