import '../shared/api_client.dart';

/// Client-side username validation mirroring the backend rules, for instant
/// feedback. Returns an error message, or null when [raw] is well-formed.
/// The server remains authoritative for uniqueness.
String? validateUsername(String raw) {
  final username = raw.trim().toLowerCase();
  if (username.isEmpty) return 'Username is required';
  if (!RegExp(r'^[a-z][a-z0-9_]{2,19}$').hasMatch(username)) {
    return 'Use 3–20 characters: start with a letter, then letters, numbers, or _';
  }
  const reserved = {'admin', 'root', 'trego', 'support'};
  if (reserved.contains(username)) return 'That username is not available';
  return null;
}

/// Thin, injectable wrapper over [ApiClient] for the username endpoint.
///
/// Kept separate from [AuthService] (which eagerly touches Firebase singletons
/// and can't be constructed in unit tests) so this stays testable with a fake
/// [ApiClient].
class UsernameApi {
  final ApiClient _apiClient;

  UsernameApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient.instance;

  /// PUT /auth/username. Returns null on success, or a human-readable error
  /// message (e.g. "That username is already taken") on failure.
  Future<String?> setUsername(String username) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/auth/username',
        data: {'username': username.trim().toLowerCase()},
      );
      if (response.data?['success'] == true) return null;
      return (response.data?['message'] as String?) ?? 'Could not set username';
    } on ApiException catch (e) {
      // The enhanced client surfaces the server's message here (e.g. taken).
      return e.message;
    } catch (_) {
      return 'Could not set username. Please try again.';
    }
  }
}
