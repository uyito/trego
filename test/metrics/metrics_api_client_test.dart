import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:trego/metrics/metrics_api_client.dart';
import 'package:trego/metrics/metrics_models.dart';
import 'package:trego/shared/api_client.dart';

class _FakeApiClient implements ApiClient {
  final Map<String, dynamic> nextResponse;
  String? lastGetPath;
  String? lastPostPath;

  _FakeApiClient(this.nextResponse);

  @override
  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    lastGetPath = path;
    return Response<T>(
      data: nextResponse as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> post<T>(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    lastPostPath = path;
    return Response<T>(
      data: nextResponse as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  // The following members exist on ApiClient but aren't exercised by these
  // tests. Dart's static analyzer requires concrete implementations because
  // _FakeApiClient `implements ApiClient`.
  @override
  Future<void> setAuthToken(String token) async {}
  @override
  Future<void> clearAuthToken() async {}
  @override
  Future<void> loadAuthToken() async {}
  @override
  Future<Response<T>> put<T>(String path,
          {dynamic data,
          Map<String, dynamic>? queryParameters,
          Options? options}) async =>
      throw UnimplementedError();
  @override
  Future<Response<T>> delete<T>(String path,
          {Map<String, dynamic>? queryParameters, Options? options}) async =>
      throw UnimplementedError();
  @override
  Future<Response<T>> uploadFile<T>(String path, File file,
          {String fieldName = 'file',
          Map<String, dynamic>? additionalData}) async =>
      throw UnimplementedError();
  @override
  Future<bool> checkConnectivity() async => true;
  @override
  bool get isOnline => true;
}

Map<String, dynamic> _validSnapshotJson() => {
      'computedAt': '2026-04-27T18:34:12Z',
      'thisWeek': {
        'isoYearWeek': '2026-W17',
        'weekStart': '2026-04-20T00:00:00Z',
        'weekEnd': '2026-04-26T23:59:59Z',
        'totalKm': 23.4,
        'totalRuns': 4,
        'totalTimeMs': 5418000,
        'avgPaceSecPerKm': 308,
        'longestKm': 8.2,
        'streakDays': 6,
      },
      'prs': {
        'fastest1k': null,
        'fastest5k': null,
        'fastest10k': null,
        'longestDistance': null,
        'longestDuration': null,
      },
      'totals': {'totalKm': 0, 'totalRuns': 0, 'totalTimeMs': 0},
      'history': [],
    };

void main() {
  test('fetchSnapshot calls /metrics/me and parses response', () async {
    final fake = _FakeApiClient(_validSnapshotJson());
    final client = MetricsApiClient(http: fake);

    final snap = await client.fetchSnapshot();

    expect(fake.lastGetPath, '/metrics/me');
    expect(snap.thisWeek.isoYearWeek, '2026-W17');
  });

  test('recompute calls POST /metrics/me/recompute and parses recomputedAt', () async {
    final fake = _FakeApiClient({
      'recomputedAt': '2026-04-27T18:34:12Z',
      'runCount': 42,
      'durationMs': 87,
    });
    final client = MetricsApiClient(http: fake);

    final at = await client.recompute();

    expect(fake.lastPostPath, '/metrics/me/recompute');
    expect(at, DateTime.parse('2026-04-27T18:34:12Z'));
  });
}
