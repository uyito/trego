import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/shared/api_client.dart';
import 'package:trego/social/social_service.dart';

/// Records the last call and returns a canned Response. Only the HTTP verbs
/// SocialService uses are overridden; everything else falls through noSuchMethod.
class _FakeApiClient implements ApiClient {
  String? lastMethod;
  String? lastPath;
  dynamic lastData;
  Map<String, dynamic>? response;
  bool throwError = false;

  Response<T> _resp<T>(String path) => Response<T>(
        data: response as T,
        statusCode: 200,
        requestOptions: RequestOptions(path: path),
      );

  @override
  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'GET';
    lastPath = path;
    if (throwError) throw const ApiException(message: 'boom', statusCode: 500);
    return _resp<T>(path);
  }

  @override
  Future<Response<T>> post<T>(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'POST';
    lastPath = path;
    lastData = data;
    if (throwError) throw const ApiException(message: 'boom', statusCode: 500);
    return _resp<T>(path);
  }

  @override
  Future<Response<T>> patch<T>(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'PATCH';
    lastPath = path;
    lastData = data;
    if (throwError) throw const ApiException(message: 'boom', statusCode: 500);
    return _resp<T>(path);
  }

  @override
  Future<Response<T>> put<T>(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'PUT';
    lastPath = path;
    lastData = data;
    if (throwError) throw const ApiException(message: 'boom', statusCode: 500);
    return _resp<T>(path);
  }

  @override
  Future<Response<T>> delete<T>(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'DELETE';
    lastPath = path;
    if (throwError) throw const ApiException(message: 'boom', statusCode: 500);
    return _resp<T>(path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeApiClient api;
  late SocialService service;

  setUp(() {
    api = _FakeApiClient();
    service = SocialService(apiClient: api);
  });

  group('getComments', () {
    test('GETs the comments endpoint and parses list', () async {
      api.response = {
        'success': true,
        'comments': [
          {'id': 'c1', 'content': 'nice'},
          {'id': 'c2', 'content': 'great'},
        ],
      };

      final comments = await service.getComments('p1');

      expect(api.lastMethod, 'GET');
      expect(api.lastPath, '/api/social/posts/p1/comments');
      expect(comments, hasLength(2));
      expect(comments.first['content'], 'nice');
    });

    test('returns empty list on failure', () async {
      api.response = {'success': false};
      expect(await service.getComments('p1'), isEmpty);
    });

    test('returns empty list on error', () async {
      api.throwError = true;
      expect(await service.getComments('p1'), isEmpty);
    });
  });

  group('reportPost', () {
    test('POSTs reason and returns true on success', () async {
      api.response = {'success': true};

      final ok = await service.reportPost('p1', 'spam');

      expect(api.lastMethod, 'POST');
      expect(api.lastPath, '/api/social/posts/p1/report');
      expect(api.lastData, {'reason': 'spam'});
      expect(ok, isTrue);
    });

    test('returns false on error', () async {
      api.throwError = true;
      expect(await service.reportPost('p1', 'spam'), isFalse);
    });
  });

  group('updatePost', () {
    test('PATCHes content and returns updated post', () async {
      api.response = {
        'success': true,
        'post': {'id': 'p1', 'content': 'edited'},
      };

      final post = await service.updatePost('p1', 'edited');

      expect(api.lastMethod, 'PATCH');
      expect(api.lastPath, '/api/social/posts/p1');
      expect(api.lastData, {'content': 'edited'});
      expect(post?['content'], 'edited');
    });

    test('returns null on failure', () async {
      api.response = {'success': false};
      expect(await service.updatePost('p1', 'edited'), isNull);
    });
  });

  group('deletePost', () {
    test('DELETEs the post and returns true', () async {
      api.response = {'success': true};

      final ok = await service.deletePost('p1');

      expect(api.lastMethod, 'DELETE');
      expect(api.lastPath, '/api/social/posts/p1');
      expect(ok, isTrue);
    });

    test('returns false on error', () async {
      api.throwError = true;
      expect(await service.deletePost('p1'), isFalse);
    });
  });

  group('sendFriendRequest', () {
    test('POSTs identifier + message and returns true', () async {
      api.response = {'success': true, 'status': 'pending'};

      final ok = await service.sendFriendRequest('bob@x.com', message: 'hi');

      expect(api.lastMethod, 'POST');
      expect(api.lastPath, '/api/social/friends/request');
      expect(api.lastData, {'identifier': 'bob@x.com', 'message': 'hi'});
      expect(ok, isTrue);
    });

    test('returns false on error', () async {
      api.throwError = true;
      expect(await service.sendFriendRequest('bob@x.com'), isFalse);
    });
  });

  group('cancelFriendRequest', () {
    test('DELETEs the request and returns true', () async {
      api.response = {'success': true};

      final ok = await service.cancelFriendRequest('r1');

      expect(api.lastMethod, 'DELETE');
      expect(api.lastPath, '/api/social/friends/request/r1');
      expect(ok, isTrue);
    });
  });

  group('unfriend', () {
    test('DELETEs the friendship and returns true', () async {
      api.response = {'success': true};

      final ok = await service.unfriend('bob-uid');

      expect(api.lastMethod, 'DELETE');
      expect(api.lastPath, '/api/social/friends/bob-uid');
      expect(ok, isTrue);
    });

    test('returns false on error', () async {
      api.throwError = true;
      expect(await service.unfriend('bob-uid'), isFalse);
    });
  });

  group('notifications', () {
    test('fetchNotifications parses items + unreadCount', () async {
      api.response = {
        'success': true,
        'notifications': [
          {'id': 'n1', 'message': 'Bob liked your post', 'read': false},
        ],
        'unreadCount': 1,
      };

      final result = await service.fetchNotifications();

      expect(api.lastMethod, 'GET');
      expect(api.lastPath, '/api/social/notifications');
      expect(result.items, hasLength(1));
      expect(result.unreadCount, 1);
    });

    test('fetchNotifications returns empty on failure', () async {
      api.throwError = true;
      final result = await service.fetchNotifications();
      expect(result.items, isEmpty);
      expect(result.unreadCount, 0);
    });

    test('getUnreadNotificationCount hits unread-count endpoint', () async {
      api.response = {'success': true, 'unreadCount': 4};
      final count = await service.getUnreadNotificationCount();
      expect(api.lastPath, '/api/social/notifications/unread-count');
      expect(count, 4);
    });

    test('markAllNotificationsRead PUTs read-all', () async {
      api.response = {'success': true};
      final ok = await service.markAllNotificationsRead();
      expect(api.lastMethod, 'PUT');
      expect(api.lastPath, '/api/social/notifications/read-all');
      expect(ok, isTrue);
    });

    test('deleteNotification DELETEs by id', () async {
      api.response = {'success': true};
      final ok = await service.deleteNotification('n1');
      expect(api.lastMethod, 'DELETE');
      expect(api.lastPath, '/api/social/notifications/n1');
      expect(ok, isTrue);
    });
  });
}
