import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/auth/username_api.dart';
import 'package:trego/shared/api_client.dart';

/// Fake ApiClient: records the PUT and returns a canned envelope, or throws an
/// ApiException with a given message. Only put() is exercised.
class _FakeApiClient implements ApiClient {
  String? lastPath;
  dynamic lastData;
  Map<String, dynamic>? response;
  String? throwMessage;

  @override
  Future<Response<T>> put<T>(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    lastPath = path;
    lastData = data;
    if (throwMessage != null) {
      throw ApiException(message: throwMessage!, statusCode: 409);
    }
    return Response<T>(
      data: response as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('validateUsername', () {
    test('accepts a valid name', () => expect(validateUsername('runner_42'), isNull));
    test('accepts uppercase (normalized)', () => expect(validateUsername('Runner'), isNull));
    test('rejects empty', () => expect(validateUsername('  '), isNotNull));
    test('rejects too short', () => expect(validateUsername('ab'), isNotNull));
    test('rejects too long', () => expect(validateUsername('a' * 21), isNotNull));
    test('rejects leading digit', () => expect(validateUsername('1abc'), isNotNull));
    test('rejects leading underscore', () => expect(validateUsername('_abc'), isNotNull));
    test('rejects illegal chars', () => expect(validateUsername('ab-cd'), isNotNull));
    test('rejects reserved', () => expect(validateUsername('admin'), isNotNull));
    test('rejects reserved case-insensitively', () => expect(validateUsername('Trego'), isNotNull));
  });

  group('UsernameApi.setUsername', () {
    late _FakeApiClient api;
    late UsernameApi sut;

    setUp(() {
      api = _FakeApiClient();
      sut = UsernameApi(apiClient: api);
    });

    test('PUTs normalized username and returns null on success', () async {
      api.response = {'success': true, 'data': {'username': 'runner'}};

      final err = await sut.setUsername('Runner');

      expect(api.lastPath, '/auth/username');
      expect(api.lastData, {'username': 'runner'});
      expect(err, isNull);
    });

    test('returns server message on failure envelope', () async {
      api.response = {'success': false, 'message': 'nope'};
      expect(await sut.setUsername('runner'), 'nope');
    });

    test('returns server message when ApiException thrown (taken)', () async {
      api.throwMessage = 'That username is already taken';
      expect(await sut.setUsername('taken'), 'That username is already taken');
    });
  });
}
