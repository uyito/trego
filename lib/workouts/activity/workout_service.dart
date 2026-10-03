import '../../shared/api_client.dart';
import 'activity_models.dart';

/// Injectable wrapper over [ApiClient] for the /workouts activity endpoints.
class WorkoutService {
  final ApiClient _apiClient;
  WorkoutService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient.instance;

  Future<ActivitySession?> logSession(ActivitySession session) async {
    try {
      final r = await _apiClient.post('/workouts/sessions', data: session.toLogPayload());
      if (r.data['success'] == true && r.data['session'] != null) {
        return ActivitySession.fromJson(Map<String, dynamic>.from(r.data['session']));
      }
      return null;
    } catch (e) {
      print('logSession failed: $e');
      return null;
    }
  }

  Future<List<ActivitySession>> getHistory() async {
    try {
      final r = await _apiClient.get('/workouts/sessions');
      if (r.data['success'] == true) {
        return ((r.data['sessions'] as List?) ?? const [])
            .map((e) => ActivitySession.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      print('getHistory failed: $e');
      return [];
    }
  }

  Future<ActivitySession?> getSessionDetail(String id) async {
    try {
      final r = await _apiClient.get('/workouts/sessions/$id');
      if (r.data['success'] == true && r.data['session'] != null) {
        return ActivitySession.fromJson(Map<String, dynamic>.from(r.data['session']));
      }
      return null;
    } catch (e) {
      print('getSessionDetail failed: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPRs() async {
    try {
      final r = await _apiClient.get('/workouts/prs');
      if (r.data['success'] == true) {
        return List<Map<String, dynamic>>.from(r.data['prs'] ?? const []);
      }
      return [];
    } catch (e) {
      print('getPRs failed: $e');
      return [];
    }
  }
}
