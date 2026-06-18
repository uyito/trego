import 'package:trego/shared/api_client.dart';
import 'metrics_models.dart';

/// Thin wrapper over [ApiClient] for the metrics endpoints.
class MetricsApiClient {
  final ApiClient _http;

  MetricsApiClient({required ApiClient http}) : _http = http;

  /// GET /metrics/me — returns the materialized snapshot.
  Future<MetricsSnapshot> fetchSnapshot() async {
    final response = await _http.get<Map<String, dynamic>>('/metrics/me');
    return MetricsSnapshot.fromJson(response.data!);
  }

  /// POST /metrics/me/recompute — triggers a backend recompute.
  /// Returns the `recomputedAt` timestamp.
  Future<DateTime> recompute() async {
    final response = await _http.post<Map<String, dynamic>>('/metrics/me/recompute');
    return DateTime.parse(response.data!['recomputedAt'] as String);
  }

  /// GET /metrics/me/goal — the user's weekly goal (all-null when unset).
  Future<WeeklyGoal> fetchGoal() async {
    final response = await _http.get<Map<String, dynamic>>('/metrics/me/goal');
    return WeeklyGoal.fromJson(response.data ?? const {});
  }

  /// PUT /metrics/me/goal — set targets (either may be null). Returns the stored goal.
  Future<WeeklyGoal> updateGoal({double? targetKm, int? targetRuns}) async {
    final response = await _http.put<Map<String, dynamic>>(
      '/metrics/me/goal',
      data: {
        if (targetKm != null) 'targetKm': targetKm,
        if (targetRuns != null) 'targetRuns': targetRuns,
      },
    );
    return WeeklyGoal.fromJson(response.data ?? const {});
  }
}
