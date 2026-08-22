import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../social/screens/social_hub_screen.dart';
import '../social/social_service.dart';
import '../social/widgets/comments_sheet.dart';
import 'notification_destination.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.hasUnread)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.load(),
        child: _buildBody(provider),
      ),
    );
  }

  /// Mark read, then navigate to the notification's target.
  void _handleTap(Map<String, dynamic> n) {
    context.read<NotificationsProvider>().markRead(n['id'] as String);

    final destination = notificationDestination(n);
    switch (destination) {
      case FriendsDestination(:final tab):
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SocialHubScreen(
              initialTab: 1,
              friendsInitialTab: tab,
              service: context.read<SocialService>(),
            ),
          ),
        );
      case PostCommentsDestination(:final postId):
        CommentsSheet.show(
          context,
          postId: postId,
          service: context.read<SocialService>(),
        );
      case NoDestination():
        break;
    }
  }

  Widget _buildBody(NotificationsProvider provider) {
    if (provider.items.isEmpty && provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Center(
            child: Text('No notifications yet',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Likes, comments, and friend requests will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      itemCount: provider.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final n = provider.items[index];
        return _NotificationTile(
          notification: n,
          onTap: () => _handleTap(n),
          onDelete: () => provider.delete(n['id'] as String),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  IconData _iconFor(String? type) {
    switch (type) {
      case 'post_like':
        return Icons.favorite;
      case 'post_comment':
        return Icons.mode_comment_outlined;
      case 'friend_request':
        return Icons.person_add_alt_1;
      case 'friend_accept':
        return Icons.people_alt_outlined;
      case 'mention':
        return Icons.alternate_email;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = notification['read'] != true;
    final author = notification['actor'] as Map<String, dynamic>?;
    final photo = author?['photoURL'] as String?;

    return Dismissible(
      key: ValueKey(notification['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        color: unread ? const Color(0xFFF0F7FF) : null,
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null ? const Icon(Icons.person) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: Colors.white,
                  child: Icon(_iconFor(notification['type'] as String?),
                      size: 12, color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
          title: Text(
            notification['message'] as String? ?? '',
            style: TextStyle(fontWeight: unread ? FontWeight.w600 : FontWeight.w400),
          ),
          subtitle: Text(_formatTimestamp(notification['createdAt'] as String?)),
          trailing: unread
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE31E24),
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.tryParse(timestamp);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
