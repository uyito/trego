import 'package:flutter/foundation.dart';
import 'enhanced_api_client.dart';

class SyncService {
  static SyncService? _instance;
  late EnhancedApiClient _apiClient;
  bool _isInitialized = false;

  SyncService._() {
    _apiClient = EnhancedApiClient.instance;
  }

  static SyncService get instance {
    _instance ??= SyncService._();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _apiClient.loadAuthToken();
    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('🔄 SyncService initialized with enhanced API client');
      debugPrint('📡 Online status: ${_apiClient.isOnline}');
    }
  }

  // Sync user profile data
  Future<ApiResponse<Map<String, dynamic>>> syncUserProfile(Map<String, dynamic> profileData) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Syncing user profile data...');
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/user/profile/sync',
        data: profileData,
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          debugPrint('✅ User profile synced successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to sync user profile: ${response.error}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 Exception during profile sync: $e');
      }
      return ApiResponse.failure('Profile sync failed: $e', ApiErrorType.unknown);
    }
  }

  // Sync workout data with enhanced offline support
  Future<ApiResponse<Map<String, dynamic>>> syncWorkoutData(Map<String, dynamic> workoutData) async {
    try {
      if (kDebugMode) {
        debugPrint('🏋️ Syncing workout data...');
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/workouts/sync',
        data: {
          'workout': workoutData,
          'timestamp': DateTime.now().toIso8601String(),
          'deviceId': await _getDeviceId(),
        },
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          debugPrint('✅ Workout data synced successfully');
        }
        await _updateLocalWorkoutSync(workoutData['id'] as String);
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to sync workout: ${response.error}');
          if (response.errorType == ApiErrorType.network) {
            debugPrint('📴 Workout queued for offline sync');
          }
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 Exception during workout sync: $e');
      }
      return ApiResponse.failure('Workout sync failed: $e', ApiErrorType.unknown);
    }
  }

  // Sync nutrition data
  Future<ApiResponse<Map<String, dynamic>>> syncNutritionData(Map<String, dynamic> nutritionData) async {
    try {
      if (kDebugMode) {
        debugPrint('🥗 Syncing nutrition data...');
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/nutrition/sync',
        data: {
          'nutrition': nutritionData,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          debugPrint('✅ Nutrition data synced successfully');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 Exception during nutrition sync: $e');
      }
      return ApiResponse.failure('Nutrition sync failed: $e', ApiErrorType.unknown);
    }
  }

  // Get user analytics with caching
  Future<ApiResponse<Map<String, dynamic>>> getUserAnalytics({String period = '30d'}) async {
    try {
      if (kDebugMode) {
        debugPrint('📊 Fetching user analytics for period: $period');
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/analytics/user',
        queryParameters: {'period': period},
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          debugPrint('✅ Analytics data retrieved successfully');
        }
      } else if (response.errorType == ApiErrorType.network) {
        if (kDebugMode) {
          debugPrint('📱 Using cached analytics data');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 Exception during analytics fetch: $e');
      }
      return ApiResponse.failure('Analytics fetch failed: $e', ApiErrorType.unknown);
    }
  }

  // Get AI recommendations with enhanced error handling
  Future<ApiResponse<List<Map<String, dynamic>>>> getAIRecommendations({
    String category = 'all',
    int limit = 10,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🤖 Fetching AI recommendations...');
      }

      final response = await _apiClient.get<List<Map<String, dynamic>>>(
        '/ai/recommendations',
        queryParameters: {
          'category': category,
          'limit': limit.toString(),
        },
      );

      if (response.isSuccess) {
        if (kDebugMode) {
          debugPrint('✅ AI recommendations retrieved successfully');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to get recommendations: ${response.error}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 Exception during recommendations fetch: $e');
      }
      return ApiResponse.failure('Recommendations fetch failed: $e', ApiErrorType.unknown);
    }
  }

  // Batch sync multiple data types
  Future<Map<String, ApiResponse<dynamic>>> batchSync({
    Map<String, dynamic>? profileData,
    List<Map<String, dynamic>>? workouts,
    List<Map<String, dynamic>>? nutrition,
  }) async {
    final results = <String, ApiResponse<dynamic>>{};

    if (kDebugMode) {
      debugPrint('🔄 Starting batch sync operation...');
    }

    // Execute all syncs in parallel for better performance
    final futures = <Future<void>>[];

    if (profileData != null) {
      futures.add(
        syncUserProfile(profileData).then((response) {
          results['profile'] = response;
        }),
      );
    }

    if (workouts != null) {
      for (final workout in workouts) {
        futures.add(
          syncWorkoutData(workout).then((response) {
            results['workout_${workout['id']}'] = response;
          }),
        );
      }
    }

    if (nutrition != null) {
      for (final meal in nutrition) {
        futures.add(
          syncNutritionData(meal).then((response) {
            results['nutrition_${meal['id']}'] = response;
          }),
        );
      }
    }

    await Future.wait(futures);

    if (kDebugMode) {
      final successCount = results.values.where((r) => r.isSuccess).length;
      final totalCount = results.length;
      debugPrint('🎯 Batch sync completed: $successCount/$totalCount operations successful');
    }

    return results;
  }

  // Check sync status and pending operations
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final isOnline = _apiClient.isOnline;
      final connectivityStatus = await _apiClient.checkConnectivity();

      return {
        'isOnline': isOnline,
        'connectivityStatus': connectivityStatus,
        'hasPendingSync': await _hasPendingSync(),
        'lastSyncTime': await _getLastSyncTime(),
        'queuedOperations': await _getQueuedOperationsCount(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting sync status: $e');
      }
      return {
        'isOnline': false,
        'connectivityStatus': false,
        'hasPendingSync': false,
        'lastSyncTime': null,
        'queuedOperations': 0,
        'error': e.toString(),
      };
    }
  }

  // Force sync all pending operations
  Future<void> forceSyncPending() async {
    if (kDebugMode) {
      debugPrint('🔄 Forcing sync of all pending operations...');
    }

    try {
      // This would typically check local storage for pending operations
      // and retry them when connectivity is restored
      final pendingOperations = await _getPendingOperations();
      
      for (final operation in pendingOperations) {
        await _retrySyncOperation(operation);
      }

      if (kDebugMode) {
        debugPrint('✅ Force sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Force sync failed: $e');
      }
    }
  }

  // Private helper methods
  Future<String> _getDeviceId() async {
    // In a real implementation, this would return a unique device identifier
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _updateLocalWorkoutSync(String workoutId) async {
    // Update local database to mark workout as synced
    // This would typically update Firestore or local SQLite
  }

  Future<bool> _hasPendingSync() async {
    // Check if there are any pending sync operations
    return false; // Placeholder
  }

  Future<DateTime?> _getLastSyncTime() async {
    // Get the timestamp of the last successful sync
    return DateTime.now().subtract(const Duration(minutes: 5)); // Placeholder
  }

  Future<int> _getQueuedOperationsCount() async {
    // Count queued operations waiting for connectivity
    return 0; // Placeholder
  }

  Future<List<Map<String, dynamic>>> _getPendingOperations() async {
    // Get all pending operations from local storage
    return []; // Placeholder
  }

  Future<void> _retrySyncOperation(Map<String, dynamic> operation) async {
    // Retry a specific sync operation
    if (kDebugMode) {
      debugPrint('🔄 Retrying sync operation: ${operation['type']}');
    }
  }

  // Clean up resources
  void dispose() {
    _isInitialized = false;
    if (kDebugMode) {
      debugPrint('🧹 SyncService disposed');
    }
  }
}