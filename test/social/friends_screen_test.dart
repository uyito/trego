import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/social/screens/friends_screen.dart';
import 'package:trego/social/social_service.dart';

/// Fake SocialService: serves fixed friends/requests and records action calls.
class _FakeSocialService implements SocialService {
  List<Map<String, dynamic>> friends;
  List<Map<String, dynamic>> requests;
  bool unfriendResult = true;
  bool cancelResult = true;

  String? unfriendedUid;
  String? cancelledRequestId;
  String? respondedId;
  bool? respondedAccept;

  _FakeSocialService({this.friends = const [], this.requests = const []});

  @override
  Future<List<Map<String, dynamic>>> getFriends() async => friends;

  @override
  Future<List<Map<String, dynamic>>> getFriendRequests() async => requests;

  @override
  Future<bool> unfriend(String friendUid) async {
    unfriendedUid = friendUid;
    return unfriendResult;
  }

  @override
  Future<bool> cancelFriendRequest(String requestId) async {
    cancelledRequestId = requestId;
    return cancelResult;
  }

  @override
  Future<bool> respondToFriendRequest(String requestId, bool accept) async {
    respondedId = requestId;
    respondedAccept = accept;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _friend({String uid = 'bob', String name = 'Bob B'}) =>
    {'id': 'f1', 'uid': uid, 'name': name, 'photoURL': null};

Map<String, dynamic> _request({
  String id = 'r1',
  String type = 'incoming',
  String name = 'Carol C',
}) =>
    {
      'id': id,
      'type': type,
      'user': {'uid': 'carol', 'name': name, 'photoURL': null},
      'message': null,
      'createdAt': '2026-06-15T10:00:00.000',
    };

void main() {
  Widget wrap(SocialService service) => MaterialApp(home: FriendsScreen(service: service));

  testWidgets('renders friends in the Friends tab', (tester) async {
    final svc = _FakeSocialService(friends: [_friend(name: 'Bob B')]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    expect(find.text('Bob B'), findsOneWidget);
  });

  testWidgets('initialTab: 1 opens on the Requests tab', (tester) async {
    final svc = _FakeSocialService(requests: [_request(id: 'r1', type: 'incoming')]);
    await tester.pumpWidget(MaterialApp(
      home: FriendsScreen(service: svc, initialTab: 1),
    ));
    await tester.pumpAndSettle();

    // The incoming request's Accept/Decline are only on the Requests tab; if we
    // land there without tapping, the tab defaulted correctly.
    expect(find.widgetWithText(ElevatedButton, 'Accept'), findsOneWidget);
  });

  testWidgets('unfriend removes the friend optimistically on success', (tester) async {
    final svc = _FakeSocialService(friends: [_friend(uid: 'bob', name: 'Bob B')]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unfriend'));
    await tester.pumpAndSettle();
    // Confirm dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Unfriend'));
    await tester.pumpAndSettle();

    expect(svc.unfriendedUid, 'bob');
    expect(find.text('Bob B'), findsNothing);
  });

  testWidgets('unfriend restores the friend when backend fails', (tester) async {
    final svc = _FakeSocialService(friends: [_friend(uid: 'bob', name: 'Bob B')])
      ..unfriendResult = false;
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unfriend'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Unfriend'));
    await tester.pumpAndSettle();

    expect(svc.unfriendedUid, 'bob');
    expect(find.text('Bob B'), findsOneWidget); // restored
  });

  testWidgets('cancel outgoing request calls cancelFriendRequest', (tester) async {
    final svc = _FakeSocialService(requests: [_request(id: 'r9', type: 'outgoing')]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    // Switch to Requests tab.
    await tester.tap(find.textContaining('Requests'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(svc.cancelledRequestId, 'r9');
  });

  testWidgets('accept incoming request calls respondToFriendRequest', (tester) async {
    final svc = _FakeSocialService(requests: [_request(id: 'r1', type: 'incoming')]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Requests'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Accept'));
    await tester.pumpAndSettle();

    expect(svc.respondedId, 'r1');
    expect(svc.respondedAccept, true);
  });

  testWidgets('add-friend dialog offers username or email', (tester) async {
    final svc = _FakeSocialService();
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    expect(find.text('Add by username or email'), findsOneWidget);
  });
}
