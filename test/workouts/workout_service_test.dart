import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/shared/api_client.dart';
import 'package:trego/workouts/activity/activity_models.dart';
import 'package:trego/workouts/activity/workout_service.dart';

class _FakeApiClient implements ApiClient {
  String? lastMethod, lastPath;
  dynamic lastData;
  Map<String, dynamic>? response;
  bool throwError = false;

  Response<T> _resp<T>(String path) =>
      Response<T>(data: response as T, statusCode: 200, requestOptions: RequestOptions(path: path));

  @override
  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'POST'; lastPath = path; lastData = data;
    if (throwError) throw const ApiException(message: 'boom', statusCode: 500);
    return _resp<T>(path);
  }

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    lastMethod = 'GET'; lastPath = path;
    if (throwError) throw const ApiException(message: 'boom', statusCode: 500);
    return _resp<T>(path);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _FakeApiClient api;
  late WorkoutService sut;
  setUp(() { api = _FakeApiClient(); sut = WorkoutService(apiClient: api); });

  test('logSession POSTs payload and returns parsed session', () async {
    api.response = {'success': true, 'session': {'id': 's1', 'activityType': 'hiking', 'logKind': 'distanceCardio'}};
    final out = await sut.logSession(ActivitySession(activityType: 'hiking', logKind: 'distanceCardio', distance: 12.5));
    expect(api.lastMethod, 'POST');
    expect(api.lastPath, '/workouts/sessions');
    expect((api.lastData as Map)['distance'], 12.5);
    expect(out!.id, 's1');
  });

  test('logSession returns null on error', () async {
    api.throwError = true;
    expect(await sut.logSession(ActivitySession(activityType: 'yoga', logKind: 'duration')), isNull);
  });

  test('getHistory maps sessions', () async {
    api.response = {'success': true, 'sessions': [{'id': 'a', 'activityType': 'running', 'logKind': 'distanceCardio'}]};
    final out = await sut.getHistory();
    expect(api.lastPath, '/workouts/sessions');
    expect(out.single.id, 'a');
  });

  test('getPRs returns list of maps', () async {
    api.response = {'success': true, 'prs': [{'activityType': 'running', 'bestDistance': 10.0}]};
    final prs = await sut.getPRs();
    expect(api.lastPath, '/workouts/prs');
    expect(prs.single['activityType'], 'running');
  });

  test('getHistory returns [] on error', () async {
    api.throwError = true;
    expect(await sut.getHistory(), isEmpty);
  });
}
