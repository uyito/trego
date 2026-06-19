import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/social/screens/social_feed_screen.dart';
import 'package:trego/social/social_service.dart';

/// Fake SocialService: serves a fixed feed and records action calls. Methods not
/// overridden fall through noSuchMethod (unused by these tests).
class _FakeSocialService implements SocialService {
  List<Map<String, dynamic>> feed;
  bool deleteResult = true;
  bool reportResult = true;
  Map<String, dynamic>? updateResult;

  String? reportedId;
  String? reportedReason;
  String? deletedId;
  String? updatedId;

  _FakeSocialService(this.feed);

  @override
  Future<List<Map<String, dynamic>>> getFeed({int limit = 20, int? offset}) async {
    // Only the first page returns posts; pagination calls return empty.
    return (offset == null || offset == 0) ? feed : <Map<String, dynamic>>[];
  }

  @override
  Future<bool> deletePost(String postId) async {
    deletedId = postId;
    return deleteResult;
  }

  @override
  Future<bool> reportPost(String postId, String reason) async {
    reportedId = postId;
    reportedReason = reason;
    return reportResult;
  }

  @override
  Future<Map<String, dynamic>?> updatePost(String postId, String content) async {
    updatedId = postId;
    return updateResult ?? {'id': postId, 'content': content};
  }

  @override
  Future<List<Map<String, dynamic>>> getComments(String postId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _post({
  required String id,
  required String content,
  required bool isOwn,
}) =>
    {
      'id': id,
      'content': content,
      'isOwn': isOwn,
      'userLiked': false,
      'likesCount': 0,
      'commentsCount': 0,
      'attachments': <String>[],
      'author': {'name': 'Tester', 'photoURL': null},
      'createdAt': '2026-06-15T10:00:00.000',
    };

void main() {
  Widget wrap(SocialService service) => MaterialApp(
        home: SocialFeedScreen(service: service),
      );

  testWidgets('own post menu shows Edit + Delete, not Report', (tester) async {
    final svc = _FakeSocialService([_post(id: 'p1', content: 'mine', isOwn: true)]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Report'), findsNothing);
  });

  testWidgets('other-user post menu shows Report only', (tester) async {
    final svc = _FakeSocialService([_post(id: 'p2', content: 'theirs', isOwn: false)]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('delete removes the post optimistically on success', (tester) async {
    final svc = _FakeSocialService([_post(id: 'p1', content: 'doomed', isOwn: true)]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    // Confirm dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(svc.deletedId, 'p1');
    expect(find.text('doomed'), findsNothing);
  });

  testWidgets('delete restores the post when the backend fails', (tester) async {
    final svc = _FakeSocialService([_post(id: 'p1', content: 'sticky', isOwn: true)])
      ..deleteResult = false;
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(svc.deletedId, 'p1');
    expect(find.text('sticky'), findsOneWidget); // restored
  });

  testWidgets('report sends the chosen reason', (tester) async {
    final svc = _FakeSocialService([_post(id: 'p2', content: 'bad', isOwn: false)]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    // Pick "Harassment" then submit.
    await tester.tap(find.text('Harassment'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Report'));
    await tester.pumpAndSettle();

    expect(svc.reportedId, 'p2');
    expect(svc.reportedReason, 'harassment');
  });

  testWidgets('edit updates the post content', (tester) async {
    final svc = _FakeSocialService([_post(id: 'p1', content: 'old text', isOwn: true)]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'new text');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(svc.updatedId, 'p1');
    expect(find.text('new text'), findsOneWidget);
    expect(find.text('old text'), findsNothing);
  });

  testWidgets('share invokes the OS share sheet', (tester) async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final svc = _FakeSocialService([_post(id: 'p1', content: 'shareable', isOwn: false)]);
    await tester.pumpWidget(wrap(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pump();

    expect(calls, isNotEmpty);
    expect((calls.first.arguments as Map)['text'], contains('shareable'));
  });
}
