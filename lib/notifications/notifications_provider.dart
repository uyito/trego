import 'package:flutter/foundation.dart';
import '../social/social_service.dart';

/// In-app notification state: the feed list + unread count. Refreshed on
/// app-foreground and on screen-open (no background polling in v1).
class NotificationsProvider extends ChangeNotifier {
  final SocialService _service;

  NotificationsProvider({SocialService? service})
      : _service = service ?? SocialService();

  List<Map<String, dynamic>> _items = [];
  int _unreadCount = 0;
  bool _loading = false;

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  bool get hasUnread => _unreadCount > 0;

  /// Full load — list + authoritative unread count. Used on screen-open.
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final result = await _service.fetchNotifications();
      _items = result.items;
      _unreadCount = result.unreadCount;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Lightweight unread-count refresh — used on app-foreground for the badge.
  Future<void> refreshUnread() async {
    final count = await _service.getUnreadNotificationCount();
    if (count != _unreadCount) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  /// Mark one read (optimistic): flips the item and decrements the count.
  Future<void> markRead(String id) async {
    final index = _items.indexWhere((n) => n['id'] == id);
    if (index == -1 || _items[index]['read'] == true) return;

    _items[index] = {..._items[index], 'read': true};
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    final ok = await _service.markNotificationAsRead(id);
    if (!ok) {
      // Revert on failure.
      _items[index] = {..._items[index], 'read': false};
      _unreadCount++;
      notifyListeners();
    }
  }

  /// Mark all read (optimistic).
  Future<void> markAllRead() async {
    if (_unreadCount == 0) return;
    final prevItems = _items;
    final prevCount = _unreadCount;

    _items = [for (final n in _items) {...n, 'read': true}];
    _unreadCount = 0;
    notifyListeners();

    final ok = await _service.markAllNotificationsRead();
    if (!ok) {
      _items = prevItems;
      _unreadCount = prevCount;
      notifyListeners();
    }
  }

  /// Delete one (optimistic).
  Future<void> delete(String id) async {
    final index = _items.indexWhere((n) => n['id'] == id);
    if (index == -1) return;
    final removed = _items[index];
    final wasUnread = removed['read'] != true;

    _items = [..._items]..removeAt(index);
    if (wasUnread && _unreadCount > 0) _unreadCount--;
    notifyListeners();

    final ok = await _service.deleteNotification(id);
    if (!ok) {
      _items = [..._items]..insert(index, removed);
      if (wasUnread) _unreadCount++;
      notifyListeners();
    }
  }

  /// Drop state — call on sign-out.
  void clear() {
    _items = [];
    _unreadCount = 0;
    notifyListeners();
  }
}
