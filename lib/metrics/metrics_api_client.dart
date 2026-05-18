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
}
