import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trego/achievements/achievement_model.dart';
import '../shared/api_client.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiClient _apiClient = ApiClient.instance;

  // Get user achievements from backend API
  Future<Map<String, dynamic>?> getUserAchievementsFromAPI() async {
    try {
      final response = await _apiClient.get('/api/achievements');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      print('Get achievements from API failed: $e');
    }
    
    return null;
  }

  // Check for new achievements using backend API
  Future<List<Map<String, dynamic>>> checkAchievements(Map<String, dynamic> activityData) async {
    try {
      final response = await _apiClient.post('/api/achievements/check', data: {
        'activityData': activityData,
      });
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['newAchievements'] ?? []);
      }
    } catch (e) {
      print('Check achievements failed: $e');
    }
    
    return [];
  }

  // Get leaderboard from backend API
  Future<List<Map<String, dynamic>>> getLeaderboard({String? category, int limit = 20}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
      };
      if (category != null) queryParams['category'] = category;
      
      final response = await _apiClient.get('/api/achievements/leaderboard', 
          queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['leaderboard']);
      }
    } catch (e) {
      print('Get leaderboard failed: $e');
    }
    
    return [];
  }

  // Share achievement using backend API
  Future<bool> shareAchievement(String achievementId, {String? message}) async {
    try {
      final response = await _apiClient.post('/api/achievements/$achievementId/share', data: {
        'message': message,
      });
      
      return response.data['success'] == true;
    } catch (e) {
      print('Share achievement failed: $e');
      return false;
    }
  }

  // Get user achievements (local fallback)
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      final earnedAchievements = querySnapshot.docs
          .map((doc) => Achievement.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Merge with predefined achievements and update progress
      return await _mergeWithPredefinedAchievements(userId, earnedAchievements);
    } catch (e) {
      print('Error loading achievements: $e');
      return predefinedAchievements;
    }
  }

  // Merge earned achievements with predefined ones
  Future<List<Achievement>> _mergeWithPredefinedAchievements(
    String userId, 
    List<Achievement> earnedAchievements
  ) async {
    final Map<String, Achievement> earnedMap = {
      for (var achievement in earnedAchievements) achievement.id: achievement
    };

    final List<Achievement> allAchievements = [];
    
    for (final predefined in predefinedAchievements) {
      final earned = earnedMap[predefined.id];
      
      if (earned != null) {
        // Achievement is earned
        allAchievements.add(earned);
      } else {
        // Check progress for unearned achievements
        final progress = await _calculateProgress(userId, predefined);
        allAchievements.add(predefined.copyWith(
          progress: progress['progress'],
          currentValue: progress['currentValue'],
        ));
      }
    }

    return allAchievements;
  }

  // Calculate progress for an achievement
  Future<Map<String, dynamic>> _calculateProgress(String userId, Achievement achievement) async {
    try {
      switch (achievement.id) {
        case 'first_run':
          return await _checkFirstRun(userId);
        case '5k_runner':
        case '10k_runner':
        case 'marathon_ready':
          return await _checkDistanceAchievement(userId, achievement.requirement);
        case 'speed_demon':
          return await _checkSpeedAchievement(userId, achievement.requirement);
        case '3_day_streak':
        case '7_day_streak':
        case '30_day_streak':
          return await _checkStreakAchievement(userId, achievement.requirement);
        case 'first_workout':
        case '10_workouts':
        case '50_workouts':
          return await _checkWorkoutAchievement(userId, achievement.requirement);
        case 'water_champion':
          return await _checkWaterAchievement(userId, achievement.requirement);
        case 'calorie_tracker':
          return await _checkCalorieTrackingAchievement(userId, achievement.requirement);
        default:
          return {'progress': '0%', 'currentValue': 0};
      }
    } catch (e) {
      print('Error calculating progress for ${achievement.id}: $e');
      return {'progress': '0%', 'currentValue': 0};
    }
  }

  // Check first run achievement
  Future<Map<String, dynamic>> _checkFirstRun(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('runs')
        .limit(1)
        .get();

    final hasRun = querySnapshot.docs.isNotEmpty;
    return {
      'progress': hasRun ? '100%' : '0%',
      'currentValue': hasRun ? 1 : 0,
    };
  }

  // Check distance achievements
  Future<Map<String, dynamic>> _checkDistanceAchievement(String userId, int requiredDistance) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('runs')
        .get();

    final runs = querySnapshot.docs;
    double maxDistance = 0;

    for (final run in runs) {
      final data = run.data();
      final distance = data['distance'] ?? 0.0;
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }

    final progress = (maxDistance / requiredDistance * 100).clamp(0, 100);
    return {
      'progress': '${progress.toInt()}%',
      'currentValue': maxDistance.toInt(),
    };
  }

  // Check speed achievements
  Future<Map<String, dynamic>> _checkSpeedAchievement(String userId, int requiredMinutes) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('runs')
        .get();

    final runs = querySnapshot.docs;
    double bestPace = double.infinity;

    for (final run in runs) {
      final data = run.data();
      final distance = data['distance'] ?? 0.0;
      final duration = data['duration'] ?? 0.0;
      
      if (distance >= 5.0 && duration > 0) { // 5K runs only
        final paceMinutes = duration / 60; // Convert to minutes
        if (paceMinutes < bestPace) {
          bestPace = paceMinutes;
        }
      }
    }

    if (bestPace == double.infinity) {
      return {'progress': '0%', 'currentValue': 0};
    }

    final progress = (requiredMinutes / bestPace * 100).clamp(0, 100);
    return {
      'progress': '${progress.toInt()}%',
      'currentValue': bestPace.toInt(),
    };
  }

  // Check streak achievements
  Future<Map<String, dynamic>> _checkStreakAchievement(String userId, int requiredDays) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('streak')
        .doc('workout')
        .get();

    final currentStreak = doc.data()?['count'] ?? 0;
    final progress = (currentStreak / requiredDays * 100).clamp(0, 100);
    
    return {
      'progress': '${progress.toInt()}%',
      'currentValue': currentStreak,
    };
  }

  // Check workout achievements
  Future<Map<String, dynamic>> _checkWorkoutAchievement(String userId, int requiredWorkouts) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workoutPlan')
        .where('completed', isEqualTo: true)
        .get();

    final completedWorkouts = querySnapshot.docs.length;
    final progress = (completedWorkouts / requiredWorkouts * 100).clamp(0, 100);
    
    return {
      'progress': '${progress.toInt()}%',
      'currentValue': completedWorkouts,
    };
  }

  // Check water achievement
  Future<Map<String, dynamic>> _checkWaterAchievement(String userId, int requiredDays) async {
    final now = DateTime.now();
    int consecutiveDays = 0;
    
    for (int i = 0; i < 30; i++) { // Check last 30 days
      final date = now.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(dateString)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final waterCups = data['water'] ?? 0;
        if (waterCups >= 8) {
          consecutiveDays++;
        } else {
          break; // Break streak
        }
      } else {
        break; // No data for this day
      }
    }

    final progress = (consecutiveDays / requiredDays * 100).clamp(0, 100);
    return {
      'progress': '${progress.toInt()}%',
      'currentValue': consecutiveDays,
    };
  }

  // Check calorie tracking achievement
  Future<Map<String, dynamic>> _checkCalorieTrackingAchievement(String userId, int requiredDays) async {
    final now = DateTime.now();
    int trackedDays = 0;
    
    for (int i = 0; i < 30; i++) { // Check last 30 days
      final date = now.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(dateString)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final calories = data['calories'] ?? 0;
        if (calories > 0) {
          trackedDays++;
        }
      }
    }

    final progress = (trackedDays / requiredDays * 100).clamp(0, 100);
    return {
      'progress': '${progress.toInt()}%',
      'currentValue': trackedDays,
    };
  }

  // Award achievement
  Future<void> awardAchievement(String userId, Achievement achievement) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id)
          .set({
        ...achievement.toMap(),
        'earnedAt': DateTime.now().toIso8601String(),
        'isEarned': true,
      });
    } catch (e) {
      print('Error awarding achievement: $e');
    }
  }

  // Check and award achievements based on user activity
  Future<void> checkAndAwardAchievements(String userId) async {
    try {
      final userAchievements = await getUserAchievements(userId);
      
      for (final achievement in userAchievements) {
        if (!achievement.isEarned) {
          final progress = await _calculateProgress(userId, achievement);
          final currentValue = progress['currentValue'] ?? 0;
          
          if (currentValue >= achievement.requirement) {
            await awardAchievement(userId, achievement);
          }
        }
      }
    } catch (e) {
      print('Error checking achievements: $e');
    }
  }

  // Get achievements by category
  List<Achievement> getAchievementsByCategory(List<Achievement> achievements, String category) {
    return achievements.where((achievement) => achievement.category == category).toList();
  }

  // Get earned achievements count
  int getEarnedCount(List<Achievement> achievements) {
    return achievements.where((achievement) => achievement.isEarned).length;
  }

  // Get total achievements count
  int getTotalCount(List<Achievement> achievements) {
    return achievements.length;
  }
} 