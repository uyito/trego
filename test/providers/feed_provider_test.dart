import 'package:flutter_test/flutter_test.dart';
import 'package:trego/providers/feed_provider.dart';

void main() {
  test('friendsRecent returns empty list', () {
    final p = FeedProvider();
    expect(p.friendsRecent(limit: 3), isEmpty);
  });
}
