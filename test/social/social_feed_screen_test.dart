import 'package:flutter_test/flutter_test.dart';
import 'package:trego/social/screens/social_feed_screen.dart';
import 'package:trego/social/social_service.dart';

import '../helpers/test_app.dart';

/// Silent SocialService so the feed screen doesn't hit the network.
/// Mirrors test/push/push_navigation_test.dart's `_StubSocial` pattern.
class _StubSocial implements SocialService {
  @override
  Future<List<Map<String, dynamic>>> getFeed({int limit = 20, int? offset}) async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  initTestEnv();

  testWidgets('SocialFeedScreen builds and renders a stable element', (tester) async {
    await tester.pumpWidget(testApp(SocialFeedScreen(service: _StubSocial())));
    await tester.pumpAndSettle();

    expect(find.byType(SocialFeedScreen), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
  });
}
