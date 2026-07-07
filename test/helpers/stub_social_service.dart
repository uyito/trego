import 'package:trego/social/social_service.dart';

/// Silent [SocialService] for widget harnesses that render a
/// [NotificationsProvider] but don't exercise notifications: returns no
/// notifications and a zero unread count without any network.
class StubSocialService implements SocialService {
  @override
  Future<({List<Map<String, dynamic>> items, int unreadCount})> fetchNotifications(
      {int limit = 50}) async => (items: const <Map<String, dynamic>>[], unreadCount: 0);

  @override
  Future<int> getUnreadNotificationCount() async => 0;

  @override
  Future<List<Map<String, dynamic>>> getFeed({int limit = 20, int? offset}) async => const [];

  @override
  Future<List<Map<String, dynamic>>> getFriends() async => const [];

  @override
  Future<List<Map<String, dynamic>>> getFriendRequests() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
