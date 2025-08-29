import '../shared/api_client.dart';

class PersonalizationService {
  final ApiClient _apiClient = ApiClient.instance;

  // Get personalized workout recommendations
  Future<List<Map<String, dynamic>>> getPersonalizedWorkouts({
    int count = 5,
    bool refreshProfile = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'count': count.toString(),
        'refreshProfile': refreshProfile.toString(),
      };
      
      final response = await _apiClient.get('/api/personalization/workouts', 
          queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        return List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
      }
    } catch (e) {
      print('Get personalized workouts failed: $e');
    }
    
    return [];
  }

  // Get nutrition recommendations
  Future<Map<String, dynamic>?> getNutritionRecommendations() async {
    try {
      final response = await _apiClient.get('/api/personalization/nutrition');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      print('Get nutrition recommendations failed: $e');
    }
    
    return null;
  }

  // Get meal recommendations
  Future<List<Map<String, dynamic>>> getMealRecommendations({
    String? mealType,
    int? calories,
    List<String>? dietaryPreferences,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (mealType != null) queryParams['mealType'] = mealType;
      if (calories != null) queryParams['calories'] = calories.toString();
      if (dietaryPreferences != null) {
        queryParams['preferences'] = dietaryPreferences.join(',');
      }
      
      final response = await _apiClient.get('/api/personalization/meals', 
          queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['recommendations'] ?? []);
      }
    } catch (e) {
      print('Get meal recommendations failed: $e');
    }
    
    return [];
  }

  // Provide feedback on recommendations
  Future<bool> provideFeedback({
    required String recommendationId,
    required String feedback,
    int? rating,
    String? comments,
  }) async {
    try {
      final response = await _apiClient.post('/api/personalization/feedback', data: {
        'recommendationId': recommendationId,
        'feedback': feedback,
        'rating': rating,
        'comments': comments,
      });
      
      return response.data['success'] == true;
    } catch (e) {
      print('Provide feedback failed: $e');
      return false;
    }
  }

  // Get user insights and analytics
  Future<Map<String, dynamic>?> getUserInsights() async {
    try {
      final response = await _apiClient.get('/api/personalization/insights');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      print('Get user insights failed: $e');
    }
    
    return null;
  }

  // Update user preferences for better personalization
  Future<bool> updatePreferences({
    List<String>? workoutPreferences,
    List<String>? nutritionPreferences,
    Map<String, dynamic>? goals,
    Map<String, dynamic>? restrictions,
  }) async {
    try {
      final response = await _apiClient.put('/api/personalization/preferences', data: {
        'workoutPreferences': workoutPreferences,
        'nutritionPreferences': nutritionPreferences,
        'goals': goals,
        'restrictions': restrictions,
      });
      
      return response.data['success'] == true;
    } catch (e) {
      print('Update preferences failed: $e');
      return false;
    }
  }

  // Get personalization level and profile completeness
  Future<Map<String, dynamic>?> getPersonalizationStatus() async {
    try {
      final response = await _apiClient.get('/api/personalization/status');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      print('Get personalization status failed: $e');
    }
    
    return null;
  }

  // Reset personalization model (start fresh)
  Future<bool> resetPersonalization() async {
    try {
      final response = await _apiClient.post('/api/personalization/reset');
      
      return response.data['success'] == true;
    } catch (e) {
      print('Reset personalization failed: $e');
      return false;
    }
  }
}