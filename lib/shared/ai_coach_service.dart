import '../shared/api_client.dart';

class AICoachService {
  final ApiClient _apiClient = ApiClient.instance;

  // Get AI coach recommendations
  Future<Map<String, dynamic>?> getRecommendations({
    String? category, // fitness, nutrition, recovery, lifestyle
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{
        if (category != null) 'category': category,
        if (limit != null) 'limit': limit.toString(),
      };
      
      final response = await _apiClient.get('/ai-coach/recommendations', queryParameters: queryParams);
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to get AI recommendations: $e');
    }
    
    return null;
  }

  // Get progress analysis from AI coach
  Future<Map<String, dynamic>?> getProgressAnalysis({
    String period = 'week', // week, month, quarter
    List<String>? metrics, // weight, workouts, nutrition, sleep
  }) async {
    try {
      final queryParams = <String, String>{
        'period': period,
        if (metrics != null) 'metrics': metrics.join(','),
      };
      
      final response = await _apiClient.get('/ai-coach/progress-analysis', queryParameters: queryParams);
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to get progress analysis: $e');
    }
    
    return null;
  }

  // Chat with AI coach
  Future<Map<String, dynamic>?> askAICoach({
    required String question,
    String? context, // current_workout, meal_planning, goal_setting
    Map<String, dynamic>? userContext,
  }) async {
    try {
      final response = await _apiClient.post('/ai-coach/ask', data: {
        'question': question,
        if (context != null) 'context': context,
        if (userContext != null) 'userContext': userContext,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to ask AI coach: $e');
    }
    
    return null;
  }

  // Get personalized insights
  Future<List<Map<String, dynamic>>> getPersonalizedInsights({
    String? focusArea, // fitness, nutrition, recovery, motivation
    int limit = 5,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (focusArea != null) 'focusArea': focusArea,
      };
      
      final response = await _apiClient.get('/ai-coach/insights', queryParameters: queryParams);
      
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Failed to get personalized insights: $e');
    }
    
    return [];
  }

  // Get daily coaching tips
  Future<Map<String, dynamic>?> getDailyTip() async {
    try {
      final response = await _apiClient.get('/ai-coach/daily-tip');
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to get daily tip: $e');
    }
    
    return null;
  }

  // Rate coaching response
  Future<bool> rateResponse({
    required String responseId,
    required int rating, // 1-5
    String? feedback,
  }) async {
    try {
      final response = await _apiClient.post('/ai-coach/rate', data: {
        'responseId': responseId,
        'rating': rating,
        if (feedback != null) 'feedback': feedback,
      });
      
      return response.data?['success'] == true;
    } catch (e) {
      print('Failed to rate AI coach response: $e');
      return false;
    }
  }

  // Get coaching history
  Future<List<Map<String, dynamic>>> getCoachingHistory({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category,
      };
      
      final response = await _apiClient.get('/ai-coach/history', queryParameters: queryParams);
      
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Failed to get coaching history: $e');
    }
    
    return [];
  }

  // Set coaching preferences
  Future<bool> setCoachingPreferences({
    List<String>? focusAreas,
    String? coachingStyle, // motivational, analytical, supportive
    int? frequencyDays, // how often to receive tips
    bool? enablePushNotifications,
    Map<String, dynamic>? customPreferences,
  }) async {
    try {
      final response = await _apiClient.post('/ai-coach/preferences', data: {
        if (focusAreas != null) 'focusAreas': focusAreas,
        if (coachingStyle != null) 'coachingStyle': coachingStyle,
        if (frequencyDays != null) 'frequencyDays': frequencyDays,
        if (enablePushNotifications != null) 'enablePushNotifications': enablePushNotifications,
        if (customPreferences != null) 'customPreferences': customPreferences,
      });
      
      return response.data?['success'] == true;
    } catch (e) {
      print('Failed to set coaching preferences: $e');
      return false;
    }
  }

  // Get goal-specific coaching
  Future<Map<String, dynamic>?> getGoalCoaching({
    required String goalId,
    String? currentProgress,
    List<String>? challenges,
  }) async {
    try {
      final response = await _apiClient.post('/ai-coach/goal-coaching', data: {
        'goalId': goalId,
        if (currentProgress != null) 'currentProgress': currentProgress,
        if (challenges != null) 'challenges': challenges,
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to get goal-specific coaching: $e');
    }
    
    return null;
  }

  // Generate motivational content
  Future<Map<String, dynamic>?> getMotivationalContent({
    String? mood, // energetic, tired, stressed, motivated
    String? activityType, // pre_workout, post_workout, meal_prep
    String? timeOfDay, // morning, afternoon, evening
  }) async {
    try {
      final response = await _apiClient.post('/ai-coach/motivation', data: {
        if (mood != null) 'mood': mood,
        if (activityType != null) 'activityType': activityType,
        if (timeOfDay != null) 'timeOfDay': timeOfDay,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to get motivational content: $e');
    }
    
    return null;
  }
}