import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/push/push_api.dart';
import 'package:trego/shared/api_client.dart';

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
  Future<Response<T>> post<T>(String path,
      {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'POST';
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
  late PushApi sut;

  setUp(() {
    api = _FakeApiClient();
    sut = PushApi(apiClient: api);
  });

  test('registerToken POSTs token + platform', () async {
    api.response = {'success': true};
    final ok = await sut.registerToken('tok-1', 'android');

    expect(api.lastMethod, 'POST');
    expect(api.lastPath, '/push/tokens');
    expect(api.lastData, {'token': 'tok-1', 'platform': 'android'});
    expect(ok, isTrue);
  });

  test('registerToken returns false on error', () async {
    api.throwError = true;
    expect(await sut.registerToken('tok-1', 'android'), isFalse);
  });

  test('unregisterToken DELETEs by token', () async {
    api.response = {'success': true};
    final ok = await sut.unregisterToken('tok-1');

    expect(api.lastMethod, 'DELETE');
    expect(api.lastPath, '/push/tokens/tok-1');
    expect(ok, isTrue);
  });

  test('unregisterToken returns false on error', () async {
    api.throwError = true;
    expect(await sut.unregisterToken('tok-1'), isFalse);
  });
}
