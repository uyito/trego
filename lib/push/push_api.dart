import '../shared/api_client.dart';

/// Thin, injectable wrapper over [ApiClient] for FCM device-token registration.
/// Kept separate from [PushService] (which touches the FirebaseMessaging plugin
/// and can't be unit-tested) so the register/unregister calls stay testable.
class PushApi {
  final ApiClient _apiClient;

  PushApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient.instance;

  /// POST /push/tokens — register (upsert) this device's token. Returns true on
  /// success.
  Future<bool> registerToken(String token, String platform) async {
    try {
      final response = await _apiClient.post('/push/tokens', data: {
        'token': token,
        'platform': platform,
      });
      return response.data['success'] == true;
    } catch (e) {
      print('Register push token failed: $e');
      return false;
    }
  }

  /// DELETE /push/tokens/{token} — unregister this device's token.
  Future<bool> unregisterToken(String token) async {
    try {
      final response = await _apiClient.delete('/push/tokens/$token');
      return response.data['success'] == true;
    } catch (e) {
      print('Unregister push token failed: $e');
      return false;
    }
  }
}
