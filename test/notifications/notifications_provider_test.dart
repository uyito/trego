import 'package:flutter_test/flutter_test.dart';
import 'package:trego/notifications/notifications_provider.dart';
import 'package:trego/social/social_service.dart';

/// Fake SocialService: canned notification data + recorded action results.
class _FakeSocialService implements SocialService {
  List<Map<String, dynamic>> items;
  int unreadCount;
  bool markReadResult = true;
  bool markAllResult = true;
  bool deleteResult = true;

  String? markedReadId;
  bool markAllCalled = false;
  String? deletedId;

  _FakeSocialService({this.items = const [], this.unreadCount = 0});

  @override
  Future<({List<Map<String, dynamic>> items, int unreadCount})> fetchNotifications(
      {int limit = 50}) async {
    return (items: items, unreadCount: unreadCount);
  }

  @override
  Future<int> getUnreadNotificationCount() async => unreadCount;

  @override
  Future<bool> markNotificationAsRead(String id) async {
    markedReadId = id;
    return markReadResult;
  }

  @override
  Future<bool> markAllNotificationsRead() async {
    markAllCalled = true;
    return markAllResult;
  }

  @override
  Future<bool> deleteNotification(String id) async {
    deletedId = id;
    return deleteResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _n(String id, {bool read = false}) =>
    {'id': id, 'message': 'msg $id', 'read': read, 'type': 'post_like'};

void main() {
  test('load populates items and unread count', () async {
    final svc = _FakeSocialService(items: [_n('a'), _n('b', read: true)], unreadCount: 1);
    final p = NotificationsProvider(service: svc);

    await p.load();

    expect(p.items, hasLength(2));
    expect(p.unreadCount, 1);
    expect(p.hasUnread, isTrue);
  });

  test('markRead flips item and decrements count optimistically', () async {
    final svc = _FakeSocialService(items: [_n('a')], unreadCount: 1);
    final p = NotificationsProvider(service: svc);
    await p.load();

    await p.markRead('a');

    expect(svc.markedReadId, 'a');
    expect(p.items.first['read'], true);
    expect(p.unreadCount, 0);
  });

  test('markRead reverts when backend fails', () async {
    final svc = _FakeSocialService(items: [_n('a')], unreadCount: 1)..markReadResult = false;
    final p = NotificationsProvider(service: svc);
    await p.load();

    await p.markRead('a');

    expect(p.items.first['read'], false);
    expect(p.unreadCount, 1);
  });

  test('markAllRead zeroes unread', () async {
    final svc = _FakeSocialService(items: [_n('a'), _n('b')], unreadCount: 2);
    final p = NotificationsProvider(service: svc);
    await p.load();

    await p.markAllRead();

    expect(svc.markAllCalled, isTrue);
    expect(p.unreadCount, 0);
    expect(p.items.every((n) => n['read'] == true), isTrue);
  });

  test('delete removes item and decrements unread', () async {
    final svc = _FakeSocialService(items: [_n('a')], unreadCount: 1);
    final p = NotificationsProvider(service: svc);
    await p.load();

    await p.delete('a');

    expect(svc.deletedId, 'a');
    expect(p.items, isEmpty);
    expect(p.unreadCount, 0);
  });

  test('delete reverts when backend fails', () async {
    final svc = _FakeSocialService(items: [_n('a')], unreadCount: 1)..deleteResult = false;
    final p = NotificationsProvider(service: svc);
    await p.load();

    await p.delete('a');

    expect(p.items, hasLength(1));
    expect(p.unreadCount, 1);
  });

  test('refreshUnread updates only the count', () async {
    final svc = _FakeSocialService(unreadCount: 5);
    final p = NotificationsProvider(service: svc);

    await p.refreshUnread();

    expect(p.unreadCount, 5);
    expect(p.items, isEmpty);
  });

  test('clear resets state', () async {
    final svc = _FakeSocialService(items: [_n('a')], unreadCount: 1);
    final p = NotificationsProvider(service: svc);
    await p.load();

    p.clear();

    expect(p.items, isEmpty);
    expect(p.unreadCount, 0);
  });
}
