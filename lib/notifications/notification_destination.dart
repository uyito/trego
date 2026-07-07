/// Where a tapped notification should navigate. Pure mapping from a
/// notification's `type`/`targetType`/`targetId` to a destination, decoupled
/// from navigation so it can be unit-tested.
sealed class NotificationDestination {
  const NotificationDestination();
}

/// Open the Friends screen on a specific tab (0 = Friends, 1 = Requests).
class FriendsDestination extends NotificationDestination {
  final int tab;
  const FriendsDestination(this.tab);
}

/// Open the comments sheet for a post.
class PostCommentsDestination extends NotificationDestination {
  final String postId;
  const PostCommentsDestination(this.postId);
}

/// Nothing to navigate to (e.g. unknown type, or a post target with no id).
class NoDestination extends NotificationDestination {
  const NoDestination();
}

/// Resolves the destination for [notification]. Both post events land on the
/// post's comments (the only post-scoped view reachable without a single-post
/// screen); friend events land on the matching Friends tab.
NotificationDestination notificationDestination(Map<String, dynamic> notification) {
  final type = notification['type'] as String?;
  final targetId = notification['targetId'] as String?;

  switch (type) {
    case 'friend_request':
      return const FriendsDestination(1); // Requests tab
    case 'friend_accept':
      return const FriendsDestination(0); // Friends tab
    case 'post_like':
    case 'post_comment':
      return (targetId != null && targetId.isNotEmpty)
          ? PostCommentsDestination(targetId)
          : const NoDestination();
    default:
      return const NoDestination();
  }
}
