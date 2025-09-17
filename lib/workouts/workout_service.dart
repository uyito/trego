import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/api_client.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiClient _apiClient = ApiClient.instance;

  // Get current week start date (Monday)
  String getCurrentWeekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  // Get next week start date
  String getNextWeekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    return '${nextMonday.year}-${nextMonday.month.toString().padLeft(2, '0')}-${nextMonday.day.toString().padLeft(2, '0')}';
  }

  // Parse date string to DateTime
  DateTime parseDateString(String dateString) {
    final parts = dateString.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  // Generate AI workout using backend API
  Future<Map<String, dynamic>?> generateAIWorkout({
    required String workoutType,
    List<String>? targetMuscleGroups,
    int? duration,
    List<String>? equipment,
    String? difficulty,
    String? focus,
    int? timeAvailable,
    List<String>? injuryConsiderations,
    String? energyLevel,
    String? location,
  }) async {
    try {
      final response = await _apiClient.post('/workouts/generate-ai', data: {
        'preferences': {
          'workoutType': workoutType,
          if (targetMuscleGroups != null) 'targetMuscleGroups': targetMuscleGroups,
          if (duration != null) 'duration': duration,
          if (equipment != null) 'equipment': equipment,
          if (difficulty != null) 'difficulty': difficulty,
          if (focus != null) 'focus': focus,
        },
        'constraints': {
          if (timeAvailable != null) 'timeAvailable': timeAvailable,
          if (injuryConsiderations != null) 'injuryConsiderations': injuryConsiderations,
          if (energyLevel != null) 'energyLevel': energyLevel,
          if (location != null) 'location': location,
        }
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('AI workout generation failed: $e');
    }
    
    return null;
  }

  // Start workout session
  Future<Map<String, dynamic>?> startWorkoutSession({
    required String workoutPlanId,
    String? sessionName,
    Map<String, dynamic>? location,
    bool enableGPS = false,
    bool enableHeartRate = false,
  }) async {
    try {
      final response = await _apiClient.post('/workouts/sessions/start', data: {
        'workoutPlanId': workoutPlanId,
        if (sessionName != null) 'sessionName': sessionName,
        if (location != null) 'location': location,
        'enableGPS': enableGPS,
        'enableHeartRateTracking': enableHeartRate,
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to start workout session: $e');
    }
    
    return null;
  }

  // Log exercise set
  Future<bool> logExerciseSet({
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    int? reps,
    double? weight,
    int? duration,
    double? distance,
    int? restTime,
    int? rpe,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post('/workouts/sessions/$sessionId/exercises/$exerciseId/sets', data: {
        'setNumber': setNumber,
        if (reps != null) 'reps': reps,
        if (weight != null) 'weight': weight,
        if (duration != null) 'duration': duration,
        if (distance != null) 'distance': distance,
        if (restTime != null) 'restTime': restTime,
        if (rpe != null) 'rpe': rpe,
        if (notes != null) 'notes': notes,
      });
      
      return response.data?['success'] == true;
    } catch (e) {
      print('Failed to log exercise set: $e');
      return false;
    }
  }

  // End workout session
  Future<Map<String, dynamic>?> endWorkoutSession({
    required String sessionId,
    String? mood,
    int? perceivedExertion,
    String? notes,
    int? actualDuration,
    List<String>? photos,
  }) async {
    try {
      final response = await _apiClient.post('/workouts/sessions/$sessionId/end', data: {
        if (mood != null) 'mood': mood,
        if (perceivedExertion != null) 'perceivedExertion': perceivedExertion,
        if (notes != null) 'notes': notes,
        if (actualDuration != null) 'actualDuration': actualDuration,
        if (photos != null) 'photos': photos,
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to end workout session: $e');
    }
    
    return null;
  }

  // Get user workout history
  Future<List<Map<String, dynamic>>> getWorkoutHistory({
    int page = 1,
    int limit = 20,
    String? workoutType,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (workoutType != null) 'workoutType': workoutType,
      };
      
      final response = await _apiClient.get('/workouts/history', queryParameters: queryParams);
      
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Failed to get workout history: $e');
    }
    
    return [];
  }

  // Get workout statistics
  Future<Map<String, dynamic>?> getWorkoutStats({
    String period = 'month', // week, month, year
  }) async {
    try {
      final response = await _apiClient.get('/workouts/stats', queryParameters: {
        'period': period,
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to get workout stats: $e');
    }
    
    return null;
  }

  // Generate workout plan (fallback method)
  Future<List<Map<String, dynamic>>> generateWorkoutPlan({
    required String fitnessGoal,
    required String experienceLevel,
    required int workoutDays,
    required bool hasGymAccess,
  }) async {
    // Fallback to mock data for workout plans
    return _generateMockWorkoutPlan(
      fitnessGoal: fitnessGoal,
      experienceLevel: experienceLevel,
      workoutDays: workoutDays,
      hasGymAccess: hasGymAccess,
    );
  }


  List<Map<String, dynamic>> _generateMockWorkoutPlan({
    required String fitnessGoal,
    required String experienceLevel,
    required int workoutDays,
    required bool hasGymAccess,
  }) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final plan = <Map<String, dynamic>>[];
    
    // Adjust exercises based on fitness goal and gym access
    final isStrengthFocused = fitnessGoal == 'Gain Muscle';
    final isCardioFocused = fitnessGoal == 'Lose Fat';
    
    for (int i = 0; i < workoutDays; i++) {
      String focus;
      List<String> exercises;
      
      if (isStrengthFocused) {
        // Strength-focused plan
        switch (i % 4) {
          case 0:
            focus = 'Upper Body Push';
            exercises = _getUpperBodyPushExercises(experienceLevel, hasGymAccess);
            break;
          case 1:
            focus = 'Lower Body';
            exercises = _getLowerBodyExercises(experienceLevel, hasGymAccess);
            break;
          case 2:
            focus = 'Upper Body Pull';
            exercises = _getUpperBodyPullExercises(experienceLevel, hasGymAccess);
            break;
          case 3:
            focus = 'Full Body';
            exercises = _getFullBodyExercises(experienceLevel, hasGymAccess);
            break;
          default:
            focus = 'Rest Day';
            exercises = ['Light stretching', 'Walking', 'Yoga'];
        }
      } else if (isCardioFocused) {
        // Cardio-focused plan
        switch (i % 3) {
          case 0:
            focus = 'Cardio & HIIT';
            exercises = _getCardioExercises(experienceLevel, hasGymAccess);
            break;
          case 1:
            focus = 'Strength Training';
            exercises = _getStrengthExercises(experienceLevel, hasGymAccess);
            break;
          case 2:
            focus = 'Core & Flexibility';
            exercises = _getCoreExercises(experienceLevel);
            break;
          default:
            focus = 'Rest Day';
            exercises = ['Light stretching', 'Walking', 'Yoga'];
        }
      } else {
        // Maintenance plan
        switch (i % 3) {
          case 0:
            focus = 'Upper Body';
            exercises = _getUpperBodyExercises(experienceLevel, hasGymAccess);
            break;
          case 1:
            focus = 'Lower Body';
            exercises = _getLowerBodyExercises(experienceLevel, hasGymAccess);
            break;
          case 2:
            focus = 'Cardio & Core';
            exercises = _getCardioCoreExercises(experienceLevel, hasGymAccess);
            break;
          default:
            focus = 'Rest Day';
            exercises = ['Light stretching', 'Walking', 'Yoga'];
        }
      }
      
      plan.add({
        'day': days[i],
        'focus': focus,
        'exercises': exercises,
      });
    }
    
    return plan;
  }

  // Save workout plan to Firestore with new structure
  Future<void> saveWorkoutPlan({
    required String userId,
    required String fitnessGoal,
    required String experienceLevel,
    required int workoutDays,
    required bool hasGymAccess,
    required List<Map<String, dynamic>> workoutPlan,
  }) async {
    try {
      final weekStart = getCurrentWeekStart();
      
      // Save each workout day as a separate document
      for (final workout in workoutPlan) {
        await _firestore.collection('users').doc(userId).collection('workoutPlan').add({
          'day': workout['day'],
          'focus': workout['focus'],
          'exercises': workout['exercises'],
          'completed': false,
          'weekStart': weekStart,
          'fitnessGoal': fitnessGoal,
          'experienceLevel': experienceLevel,
          'workoutDays': workoutDays,
          'hasGymAccess': hasGymAccess,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Load workouts for current week
  Future<List<Map<String, dynamic>>> getCurrentWeekWorkouts(String userId) async {
    try {
      final weekStart = getCurrentWeekStart();
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutPlan')
          .where('weekStart', isEqualTo: weekStart)
          .orderBy('day')
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error loading current week workouts: $e');
      return [];
    }
  }

  // Mark workout as completed
  Future<void> markWorkoutCompleted({
    required String userId,
    required String workoutId,
    required bool completed,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutPlan')
          .doc(workoutId)
          .update({
        'completed': completed,
        'completedAt': completed ? FieldValue.serverTimestamp() : null,
      });
      
      // Update streak if workout is completed
      if (completed) {
        await _updateWorkoutStreak(userId);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get workout streak
  Future<int> getWorkoutStreak(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('streak')
          .doc('workoutStreak')
          .get();
      
      if (doc.exists) {
        return doc.data()?['streak'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting workout streak: $e');
      return 0;
    }
  }

  // Update workout streak
  Future<void> _updateWorkoutStreak(String userId) async {
    try {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      
      // Check if user worked out yesterday
      final yesterdayWorkouts = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutPlan')
          .where('completed', isEqualTo: true)
          .where('completedAt', isGreaterThan: Timestamp.fromDate(yesterday))
          .where('completedAt', isLessThan: Timestamp.fromDate(today))
          .get();
      
      final currentStreak = await getWorkoutStreak(userId);
      
      if (yesterdayWorkouts.docs.isNotEmpty || currentStreak == 0) {
        // Continue or start streak
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('streak')
            .doc('workoutStreak')
            .set({
          'streak': currentStreak + 1,
          'lastWorkoutDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Reset streak
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('streak')
            .doc('workoutStreak')
            .set({
          'streak': 1,
          'lastWorkoutDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating workout streak: $e');
    }
  }

  // Weekly reset - copy previous week's plan to new week
  Future<void> resetWeeklyWorkouts(String userId) async {
    try {
      final currentWeekStart = getCurrentWeekStart();
      final nextWeekStart = getNextWeekStart();
      
      // Check if current week already exists
      final currentWeekWorkouts = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutPlan')
          .where('weekStart', isEqualTo: currentWeekStart)
          .get();
      
      if (currentWeekWorkouts.docs.isNotEmpty) {
        // Copy current week to next week with completed = false
        for (final doc in currentWeekWorkouts.docs) {
          final data = doc.data();
          await _firestore.collection('users').doc(userId).collection('workoutPlan').add({
            'day': data['day'],
            'focus': data['focus'],
            'exercises': data['exercises'],
            'completed': false,
            'weekStart': nextWeekStart,
            'fitnessGoal': data['fitnessGoal'],
            'experienceLevel': data['experienceLevel'],
            'workoutDays': data['workoutDays'],
            'hasGymAccess': data['hasGymAccess'],
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error resetting weekly workouts: $e');
    }
  }

  // Check if weekly reset is needed
  Future<bool> isWeeklyResetNeeded(String userId) async {
    try {
      final currentWeekStart = getCurrentWeekStart();
      
      // Check if we have workouts for current week
      final currentWeekWorkouts = await _firestore
          .collection('users')
          .doc(userId)
          .collection('workoutPlan')
          .where('weekStart', isEqualTo: currentWeekStart)
          .limit(1)
          .get();
      
      return currentWeekWorkouts.docs.isEmpty;
    } catch (e) {
      print('Error checking weekly reset: $e');
      return false;
    }
  }

  // Get user's workout plans history
  Stream<QuerySnapshot> getUserWorkoutPlans(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('workoutPlan')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Helper methods for exercise generation (unchanged)
  List<String> _getUpperBodyPushExercises(String level, bool hasGym) {
    final reps = level == 'Beginner' ? '8-10' : level == 'Intermediate' ? '10-12' : '12-15';
    final sets = level == 'Beginner' ? '2-3' : '3-4';
    
    if (hasGym) {
      return [
        'Bench Press - $sets sets of $reps',
        'Overhead Press - $sets sets of $reps',
        'Dumbbell Flyes - $sets sets of $reps',
        'Tricep Dips - $sets sets of $reps',
      ];
    } else {
      return [
        'Push-Ups - $sets sets of ${level == 'Beginner' ? '5-10' : level == 'Intermediate' ? '10-15' : '15-20'}',
        'Pike Push-Ups - $sets sets of $reps',
        'Diamond Push-Ups - $sets sets of $reps',
        'Tricep Dips (Chair) - $sets sets of $reps',
      ];
    }
  }

  List<String> _getUpperBodyPullExercises(String level, bool hasGym) {
    final reps = level == 'Beginner' ? '8-10' : level == 'Intermediate' ? '10-12' : '12-15';
    final sets = level == 'Beginner' ? '2-3' : '3-4';
    
    if (hasGym) {
      return [
        'Pull-Ups - $sets sets of $reps',
        'Barbell Rows - $sets sets of $reps',
        'Lat Pulldowns - $sets sets of $reps',
        'Bicep Curls - $sets sets of $reps',
      ];
    } else {
      return [
        'Pull-Ups - $sets sets of ${level == 'Beginner' ? '3-5' : level == 'Intermediate' ? '5-8' : '8-12'}',
        'Inverted Rows - $sets sets of $reps',
        'Resistance Band Rows - $sets sets of $reps',
        'Bicep Curls (Water Bottles) - $sets sets of $reps',
      ];
    }
  }

  List<String> _getLowerBodyExercises(String level, bool hasGym) {
    final reps = level == 'Beginner' ? '8-10' : level == 'Intermediate' ? '10-12' : '12-15';
    final sets = level == 'Beginner' ? '2-3' : '3-4';
    
    if (hasGym) {
      return [
        'Squats - $sets sets of $reps',
        'Deadlifts - $sets sets of $reps',
        'Lunges - $sets sets of $reps each leg',
        'Calf Raises - $sets sets of 15-20',
      ];
    } else {
      return [
        'Bodyweight Squats - $sets sets of ${level == 'Beginner' ? '10-15' : level == 'Intermediate' ? '15-20' : '20-25'}',
        'Walking Lunges - $sets sets of $reps each leg',
        'Single-Leg Deadlifts - $sets sets of $reps each leg',
        'Calf Raises - $sets sets of 15-20',
      ];
    }
  }

  List<String> _getCardioExercises(String level, bool hasGym) {
    final duration = level == 'Beginner' ? '20-30' : level == 'Intermediate' ? '30-45' : '45-60';
    
    if (hasGym) {
      return [
        'Treadmill Running - $duration minutes',
        'Rowing Machine - $duration minutes',
        'Stationary Bike - $duration minutes',
        'Elliptical - $duration minutes',
      ];
    } else {
      return [
        'Running - $duration minutes',
        'Cycling - $duration minutes',
        'Jump Rope - ${level == 'Beginner' ? '10-15' : level == 'Intermediate' ? '15-20' : '20-30'} minutes',
        'High Knees - 3 sets of ${level == 'Beginner' ? '30' : '60'} seconds',
      ];
    }
  }

  List<String> _getCoreExercises(String level) {
    final duration = level == 'Beginner' ? '30' : level == 'Intermediate' ? '45' : '60';
    final reps = level == 'Beginner' ? '10-15' : level == 'Intermediate' ? '15-20' : '20-25';
    
    return [
      'Planks - 3 sets of $duration seconds',
      'Crunches - 3 sets of $reps',
      'Mountain Climbers - 3 sets of $duration seconds',
      'Russian Twists - 3 sets of $reps each side',
    ];
  }

  List<String> _getUpperBodyExercises(String level, bool hasGym) {
    return [
      ..._getUpperBodyPushExercises(level, hasGym).take(2),
      ..._getUpperBodyPullExercises(level, hasGym).take(2),
    ];
  }

  List<String> _getStrengthExercises(String level, bool hasGym) {
    return [
      ..._getUpperBodyExercises(level, hasGym).take(2),
      ..._getLowerBodyExercises(level, hasGym).take(2),
    ];
  }

  List<String> _getCardioCoreExercises(String level, bool hasGym) {
    return [
      ..._getCardioExercises(level, hasGym).take(2),
      ..._getCoreExercises(level).take(2),
    ];
  }

  List<String> _getFullBodyExercises(String level, bool hasGym) {
    return [
      ..._getUpperBodyExercises(level, hasGym).take(2),
      ..._getLowerBodyExercises(level, hasGym).take(2),
    ];
  }
} 