import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trego/notifications/notifications_provider.dart';
import 'package:trego/notifications/notifications_screen.dart';
import 'package:trego/social/social_service.dart';

class _FakeSocialService implements SocialService {
  List<Map<String, dynamic>> items;
  int unreadCount;
  bool markAllCalled = false;
  String? markedReadId;

  _FakeSocialService({this.items = const [], this.unreadCount = 0});

  @override
  Future<({List<Map<String, dynamic>> items, int unreadCount})> fetchNotifications(
      {int limit = 50}) async => (items: items, unreadCount: unreadCount);

  @override
  Future<int> getUnreadNotificationCount() async => unreadCount;

  @override
  Future<bool> markNotificationAsRead(String id) async {
    markedReadId = id;
    return true;
  }

  @override
  Future<bool> markAllNotificationsRead() async {
    markAllCalled = true;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _n(String id, {bool read = false, String msg = 'msg'}) => {
      'id': id,
      'type': 'post_like',
      'message': msg,
      'read': read,
      'actor': {'name': 'Bob', 'photoURL': null},
      'createdAt': '2026-07-01T10:00:00.000',
    };

void main() {
  Widget wrap(_FakeSocialService svc) => ChangeNotifierProvider(
        create: (_) => NotificationsProvider(service: svc),
        child: const MaterialApp(home: NotificationsScreen()),
      );

  testWidgets('empty state when there are no notifications', (tester) async {
    await tester.pumpWidget(wrap(_FakeSocialService()));
    await tester.pumpAndSettle();
    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('renders notification messages', (tester) async {
    final svc = _FakeSocialService(
      items: [_n('a', msg: 'Bob liked your post')],
      unreadCount: 1,
    );
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();
    expect(find.text('Bob liked your post'), findsOneWidget);
  });

  testWidgets('tapping a notification marks it read', (tester) async {
    final svc = _FakeSocialService(items: [_n('a', msg: 'ping')], unreadCount: 1);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ping'));
    await tester.pumpAndSettle();

    expect(svc.markedReadId, 'a');
  });

  testWidgets('Mark all read action shows when unread and calls service', (tester) async {
    final svc = _FakeSocialService(items: [_n('a'), _n('b')], unreadCount: 2);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    expect(find.text('Mark all read'), findsOneWidget);
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(svc.markAllCalled, isTrue);
    expect(find.text('Mark all read'), findsNothing); // hidden once unread == 0
  });
}
