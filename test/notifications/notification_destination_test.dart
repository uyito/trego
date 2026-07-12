import 'package:flutter_test/flutter_test.dart';
import 'package:trego/notifications/notification_destination.dart';

Map<String, dynamic> _n(String type, {String? targetId}) =>
    {'type': type, 'targetId': targetId};

void main() {
  test('friend_request → Requests tab', () {
    final d = notificationDestination(_n('friend_request', targetId: 'r1'));
    expect(d, isA<FriendsDestination>());
    expect((d as FriendsDestination).tab, 1);
  });

  test('friend_accept → Friends tab', () {
    final d = notificationDestination(_n('friend_accept'));
    expect(d, isA<FriendsDestination>());
    expect((d as FriendsDestination).tab, 0);
  });

  test('post_comment → post comments', () {
    final d = notificationDestination(_n('post_comment', targetId: 'p1'));
    expect(d, isA<PostCommentsDestination>());
    expect((d as PostCommentsDestination).postId, 'p1');
  });

  test('post_like → post comments', () {
    final d = notificationDestination(_n('post_like', targetId: 'p9'));
    expect(d, isA<PostCommentsDestination>());
    expect((d as PostCommentsDestination).postId, 'p9');
  });

  test('mention → post comments', () {
    final d = notificationDestination(_n('mention', targetId: 'p3'));
    expect(d, isA<PostCommentsDestination>());
    expect((d as PostCommentsDestination).postId, 'p3');
  });

  test('post event with no targetId → none', () {
    expect(notificationDestination(_n('post_like')), isA<NoDestination>());
    expect(notificationDestination(_n('post_comment', targetId: '')), isA<NoDestination>());
  });

  test('unknown type → none', () {
    expect(notificationDestination(_n('mystery')), isA<NoDestination>());
    expect(notificationDestination(_n('')), isA<NoDestination>());
  });
}
