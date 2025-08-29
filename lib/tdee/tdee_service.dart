import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/api_client.dart';

class TDEEService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiClient _apiClient = ApiClient.instance;

  // Calculate TDEE using backend API
  Future<Map<String, dynamic>?> calculateTDEE({
    required int age,
    required String gender,
    required double weight,
    required double height,
    required String activityLevel,
    required String goal,
    String? weightUnit = 'kg',
    String? heightUnit = 'cm',
    String? macroTemplate = 'balanced',
  }) async {
    try {
      final response = await _apiClient.post('/api/tdee/calculate', data: {
        'age': age,
        'gender': gender,
        'weight': weight,
        'height': height,
        'activityLevel': activityLevel,
        'goal': goal,
        'weightUnit': weightUnit,
        'heightUnit': heightUnit,
        'macroTemplate': macroTemplate,
      });
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
    } catch (e) {
      print('TDEE calculation failed: $e');
    }
    
    return null;
  }

  // Track progress using backend API
  Future<bool> trackProgress({
    required double weight,
    double? bodyFat,
    Map<String, double>? measurements,
  }) async {
    try {
      final response = await _apiClient.post('/api/tdee/progress', data: {
        'weight': weight,
        'bodyFat': bodyFat,
        'measurements': measurements ?? {},
      });
      
      return response.data['success'] == true;
    } catch (e) {
      print('Progress tracking failed: $e');
      return false;
    }
  }

  // Calculate BMR using Mifflin-St Jeor Equation (local fallback)
  double calculateBMR({
    required double weight, // in kg
    required double height, // in cm
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // Calculate TDEE based on activity level (local fallback)
  double calculateTDEELocal({
    required double bmr,
    required String activityLevel,
  }) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return bmr * 1.2;
      case 'lightly_active':
        return bmr * 1.375;
      case 'moderately_active':
        return bmr * 1.55;
      case 'very_active':
        return bmr * 1.725;
      case 'extremely_active':
        return bmr * 1.9;
      default:
        return bmr * 1.2;
    }
  }

  // Save TDEE data to Firestore
  Future<void> saveTDEEData({
    required String userId,
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required double bmr,
    required double tdee,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('tdee').add({
        'weight': weight,
        'height': height,
        'age': age,
        'gender': gender,
        'activityLevel': activityLevel,
        'bmr': bmr,
        'tdee': tdee,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get latest TDEE data for a user
  Stream<QuerySnapshot> getTDEEData(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tdee')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots();
  }

  // Get TDEE history for a user
  Stream<QuerySnapshot> getTDEEDataHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tdee')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
} 