import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/api_client.dart';

class TrackerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiClient _apiClient = ApiClient.instance;

  // Save daily log using backend API
  Future<bool> saveDailyLogToAPI({
    required String date,
    int? calories,
    double? water,
    double? weight,
    int? steps,
    double? sleep,
    int? mood,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post('/api/tracker/daily-log', data: {
        'date': date,
        'calories': calories,
        'water': water,
        'weight': weight,
        'steps': steps,
        'sleep': sleep,
        'mood': mood,
        'notes': notes,
      });
      
      return response.data['success'] == true;
    } catch (e) {
      print('Save daily log failed: $e');
      return false;
    }
  }

  // Track a run using backend API
  Future<bool> trackRun({
    required double distance,
    required int duration,
    int? calories,
    int? averagePace,
    List<Map<String, dynamic>>? route,
    Map<String, dynamic>? weather,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post('/api/tracker/runs', data: {
        'distance': distance,
        'duration': duration,
        'calories': calories,
        'averagePace': averagePace,
        'route': route ?? [],
        'weather': weather,
        'notes': notes,
      });
      
      return response.data['success'] == true;
    } catch (e) {
      print('Track run failed: $e');
      return false;
    }
  }

  // Get weekly summary from backend API
  Future<Map<String, dynamic>?> getWeeklySummaryFromAPI({String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) queryParams['date'] = date;
      
      final response = await _apiClient.get('/api/tracker/weekly-summary', 
          queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      print('Get weekly summary failed: $e');
    }
    
    return null;
  }

  // Get dashboard data from backend API
  Future<Map<String, dynamic>?> getDashboardFromAPI() async {
    try {
      final response = await _apiClient.get('/api/tracker/dashboard');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      print('Get dashboard failed: $e');
    }
    
    return null;
  }

  // Save daily log entry (local fallback)
  Future<void> saveDailyLog({
    required String userId,
    required String date,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(date)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // Get daily log for a specific date
  Future<Map<String, dynamic>?> getDailyLog(String userId, String date) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('logs')
          .doc(date)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get user's log history
  Stream<QuerySnapshot> getUserLogHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get logs for a date range
  Stream<QuerySnapshot> getLogsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endDateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('logs')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDateStr)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endDateStr)
        .orderBy(FieldPath.documentId)
        .snapshots();
  }

  // Get weekly summary
  Future<Map<String, dynamic>> getWeeklySummary(String userId, DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final logs = await getLogsByDateRange(userId, weekStart, weekEnd).first;
    
    int totalCalories = 0;
    int totalWater = 0;
    int workoutDays = 0;
    double? latestWeight;
    double totalDistance = 0;
    int daysWithData = 0;
    
    for (final doc in logs.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalCalories += (data['calories'] ?? 0) as int;
      totalWater += (data['water'] ?? 0) as int;
      if (data['workoutDone'] == true) workoutDays++;
      if (data['weight'] != null) latestWeight = data['weight'] as double;
      totalDistance += (data['distance'] ?? 0) as double;
      daysWithData++;
    }
    
    return {
      'totalCalories': totalCalories,
      'avgCalories': daysWithData > 0 ? totalCalories / daysWithData : 0,
      'totalWater': totalWater,
      'avgWater': daysWithData > 0 ? totalWater / daysWithData : 0,
      'workoutDays': workoutDays,
      'workoutRate': daysWithData > 0 ? workoutDays / daysWithData : 0,
      'latestWeight': latestWeight,
      'totalDistance': totalDistance,
      'avgDistance': daysWithData > 0 ? totalDistance / daysWithData : 0,
      'daysWithData': daysWithData,
    };
  }

  // Save weight entry
  Future<void> saveWeightEntry({
    required String userId,
    required double weight,
    required DateTime date,
    String? notes,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('weight').add({
        'weight': weight,
        'date': Timestamp.fromDate(date),
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get weight history
  Stream<QuerySnapshot> getWeightHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('weight')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Save body measurements
  Future<void> saveBodyMeasurements({
    required String userId,
    required Map<String, double> measurements,
    required DateTime date,
    String? notes,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('measurements').add({
        'measurements': measurements,
        'date': Timestamp.fromDate(date),
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get body measurements history
  Stream<QuerySnapshot> getBodyMeasurementsHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Save daily nutrition tracking
  Future<void> saveDailyNutrition({
    required String userId,
    required DateTime date,
    required Map<String, double> nutrition, // calories, protein, carbs, fat, fiber
    required List<Map<String, dynamic>> meals,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('nutrition').add({
        'date': Timestamp.fromDate(date),
        'nutrition': nutrition,
        'meals': meals,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get daily nutrition for a specific date
  Stream<QuerySnapshot> getDailyNutrition(String userId, DateTime date) {
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('nutrition')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots();
  }

  // Save goal
  Future<void> saveGoal({
    required String userId,
    required String type, // weight, measurements, nutrition, workout
    required String title,
    required String description,
    required DateTime targetDate,
    required Map<String, dynamic> targetValues,
    String? status, // active, completed, cancelled
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('goals').add({
        'type': type,
        'title': title,
        'description': description,
        'targetDate': Timestamp.fromDate(targetDate),
        'targetValues': targetValues,
        'status': status ?? 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user goals
  Stream<QuerySnapshot> getUserGoals(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .orderBy('targetDate')
        .snapshots();
  }

  // Update goal status
  Future<void> updateGoalStatus({
    required String userId,
    required String goalId,
    required String status,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goalId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Save progress photo
  Future<void> saveProgressPhoto({
    required String userId,
    required String imageUrl,
    required DateTime date,
    required String category, // front, back, side
    String? notes,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('progress_photos').add({
        'imageUrl': imageUrl,
        'date': Timestamp.fromDate(date),
        'category': category,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get progress photos
  Stream<QuerySnapshot> getProgressPhotos(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('progress_photos')
        .orderBy('date', descending: true)
        .snapshots();
  }
} 