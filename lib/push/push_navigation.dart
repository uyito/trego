import 'package:flutter/material.dart';
import '../notifications/notification_destination.dart';
import '../social/screens/friends_screen.dart';
import '../social/social_service.dart';
import '../social/widgets/comments_sheet.dart';

/// Routes a tapped push (its FCM `data` map, carrying {type, targetType,
/// targetId}) to the right destination, reusing the same [notificationDestination]
/// mapping the in-app notifications use. No-op if the navigator isn't mounted.
void handlePushDestination(
  Map<String, dynamic> data, {
  required GlobalKey<NavigatorState> navigatorKey,
  required SocialService social,
}) {
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;

  final destination = notificationDestination(data);
  switch (destination) {
    case FriendsDestination(:final tab):
      navigator.push(
        MaterialPageRoute(builder: (_) => FriendsScreen(initialTab: tab)),
      );
    case PostCommentsDestination(:final postId):
      CommentsSheet.show(navigator.context, postId: postId, service: social);
    case NoDestination():
      break;
  }
}
