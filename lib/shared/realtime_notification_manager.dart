import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'notification_service.dart';
import 'alert_service.dart';
import 'sync_service.dart';

class RealtimeNotificationManager {
  static RealtimeNotificationManager? _instance;
  
  late NotificationService _notificationService;
  late AlertService _alertService;
  late SyncService _syncService;
  late FirebaseFirestore _firestore;
  
  String? _userId;
  final Map<String, StreamSubscription> _listeners = {};
  bool _isInitialized = false;
  
  Timer? _achievementCheckTimer;
  Timer? _reminderTimer;
  
  RealtimeNotificationManager._();

  static RealtimeNotificationManager get instance {
    _instance ??= RealtimeNotificationManager._();
    return _instance!;
  }

  Future<void> initialize(String userId) async {
    if (_isInitialized && _userId == userId) return;

    _userId = userId;
    _notificationService = NotificationService.instance;
    _alertService = AlertService.instance;
    _syncService = SyncService.instance;
    _firestore = FirebaseFirestore.instance;

    await _notificationService.initialize();
    await _syncService.initialize();

    await _setupRealtimeListeners();
    _startPeriodicChecks();
    
    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('🔔 RealtimeNotificationManager initialized for user: $userId');
    }
  }

  Future<void> _setupRealtimeListeners() async {
    if (_userId == null) return;

    // Listen to user achievements
    _listeners['achievements'] = _firestore
        .collection('users')
        .doc(_userId)
        .collection('achievements')
        .where('isNew', isEqualTo: true)
        .snapshots()
        .listen(_handleNewAchievements);

    // Listen to social interactions
    _listeners['social'] = _firestore
        .collection('users')
        .doc(_userId)
        .collection('social_notifications')
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen(_handleSocialNotifications);

    // Listen to workout reminders
    _listeners['workouts'] = _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .where('reminderEnabled', isEqualTo: true)
        .snapshots()
        .listen(_handleWorkoutReminders);

    // Listen to AI recommendations
    _listeners['ai_recommendations'] = _firestore
        .collection('users')
        .doc(_userId)
        .collection('ai_recommendations')
        .where('delivered', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen(_handleAIRecommendations);

    // Listen to challenge invitations
    _listeners['challenges'] = _firestore
        .collection('challenges')
        .where('participants', arrayContains: _userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen(_handleChallengeUpdates);

    if (kDebugMode) {
      debugPrint('📡 Real-time listeners established');
    }
  }

  void _handleNewAchievements(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final data = change.doc.data() as Map<String, dynamic>;
        _processNewAchievement(data, change.doc.id);
      }
    }
  }

  Future<void> _processNewAchievement(Map<String, dynamic> data, String achievementId) async {
    final title = data['title'] as String? ?? 'Achievement Unlocked!';
    final description = data['description'] as String? ?? 'You\'ve reached a new milestone!';
    final badgeIcon = data['badgeIcon'] as String? ?? '🏆';
    
    // Show local notification
    await _notificationService.showAchievementUnlocked(
      title: title,
      description: description,
      badgeIcon: badgeIcon,
      achievementId: achievementId,
    );

    // Show in-app alert
    _alertService.showAchievement(
      title: '🏆 $title',
      message: description,
      onTap: () {
        // Navigate to achievements screen
        if (kDebugMode) {
          debugPrint('🧭 Navigate to achievements');
        }
      },
      data: {'achievementId': achievementId},
    );

    // Mark as processed
    await _markAchievementAsProcessed(achievementId);

    if (kDebugMode) {
      debugPrint('🏆 New achievement processed: $title');
    }
  }

  void _handleSocialNotifications(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final data = change.doc.data() as Map<String, dynamic>;
        _processSocialNotification(data, change.doc.id);
      }
    }
  }

  Future<void> _processSocialNotification(Map<String, dynamic> data, String notificationId) async {
    final type = data['type'] as String? ?? 'activity';
    final friendName = data['friendName'] as String? ?? 'A friend';
    final activity = data['activity'] as String? ?? 'completed an activity';
    final friendId = data['friendId'] as String?;

    // Show local notification for important social events
    if (type == 'challenge_invite' || type == 'workout_together') {
      await _notificationService.showFriendActivity(
        friendName: friendName,
        activity: activity,
        friendId: friendId,
      );
    }

    // Show in-app alert
    _alertService.showSocial(
      title: '👥 $friendName',
      message: activity,
      onTap: () {
        // Navigate to social screen
        if (kDebugMode) {
          debugPrint('🧭 Navigate to social');
        }
      },
      data: {
        'friendId': friendId,
        'type': type,
        'notificationId': notificationId,
      },
    );

    // Mark as read
    await _markSocialNotificationAsRead(notificationId);
  }

  void _handleWorkoutReminders(QuerySnapshot snapshot) {
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      _processWorkoutReminder(data, doc.id);
    }
  }

  Future<void> _processWorkoutReminder(Map<String, dynamic> data, String workoutId) async {
    final scheduledTime = (data['scheduledTime'] as Timestamp?)?.toDate();
    final workoutType = data['type'] as String? ?? 'Workout';
    final title = data['title'] as String? ?? 'Workout Reminder';
    
    if (scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
      await _notificationService.scheduleWorkoutReminder(
        title: title,
        body: 'Time for your $workoutType workout! Let\'s get moving.',
        scheduledTime: scheduledTime,
        workoutId: workoutId,
      );

      if (kDebugMode) {
        debugPrint('⏰ Workout reminder scheduled: $title at $scheduledTime');
      }
    }
  }

  void _handleAIRecommendations(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final data = change.doc.data() as Map<String, dynamic>;
        _processAIRecommendation(data, change.doc.id);
      }
    }
  }

  Future<void> _processAIRecommendation(Map<String, dynamic> data, String recommendationId) async {
    final title = data['title'] as String? ?? 'AI Recommendation';
    final recommendation = data['content'] as String? ?? 'Check out your new recommendation!';
    final category = data['category'] as String?;
    final priority = data['priority'] as String? ?? 'medium';

    // Only show high priority recommendations as notifications
    if (priority == 'high') {
      await _notificationService.showAIRecommendation(
        title: title,
        recommendation: recommendation,
        category: category,
      );
    }

    // Always show in-app alert
    _alertService.showAlert(AlertData(
      id: recommendationId,
      title: '🤖 $title',
      message: recommendation,
      type: AlertType.info,
      icon: Icons.auto_awesome,
      backgroundColor: Colors.purple[50],
      textColor: Colors.purple[800],
      duration: const Duration(seconds: 6),
      onTap: () {
        // Navigate to recommendations
        if (kDebugMode) {
          debugPrint('🧭 Navigate to recommendations');
        }
      },
      data: {'recommendationId': recommendationId, 'category': category},
    ));

    // Mark as delivered
    await _markRecommendationAsDelivered(recommendationId);
  }

  void _handleChallengeUpdates(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.modified) {
        final data = change.doc.data() as Map<String, dynamic>;
        _processChallengeUpdate(data, change.doc.id);
      }
    }
  }

  Future<void> _processChallengeUpdate(Map<String, dynamic> data, String challengeId) async {
    final challengeName = data['name'] as String? ?? 'Challenge';
    final lastUpdate = data['lastUpdate'] as String? ?? 'has been updated';
    final participants = List<String>.from(data['participants'] ?? []);

    // Don't notify about your own updates
    if (participants.length > 1) {
      _alertService.showSocial(
        title: '🏆 $challengeName',
        message: lastUpdate,
        onTap: () {
          // Navigate to challenge details
          if (kDebugMode) {
            debugPrint('🧭 Navigate to challenge: $challengeId');
          }
        },
        data: {'challengeId': challengeId},
      );
    }
  }

  void _startPeriodicChecks() {
    // Check for achievements every 5 minutes
    _achievementCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkForNewAchievements();
    });

    // Check for reminders every minute
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkUpcomingReminders();
    });
  }

  Future<void> _checkForNewAchievements() async {
    if (_userId == null) return;

    try {
      // Check user's recent activity for potential achievements
      final recentWorkouts = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('workouts')
          .where('completedAt', isGreaterThan: 
              Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))))
          .get();

      if (recentWorkouts.docs.isNotEmpty) {
        await _evaluateWorkoutAchievements(recentWorkouts.docs);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking achievements: $e');
      }
    }
  }

  Future<void> _evaluateWorkoutAchievements(List<QueryDocumentSnapshot> workouts) async {
    // This would typically contain complex achievement logic
    // For now, we'll simulate some basic achievements
    
    final totalWorkouts = workouts.length;
    
    if (totalWorkouts >= 3) {
      // Trigger "Workout Warrior" achievement
      await _createAchievement(
        'Workout Warrior',
        'Completed 3 workouts in one hour!',
        '💪',
        'workout_warrior_hour',
      );
    }
  }

  Future<void> _createAchievement(String title, String description, String badge, String achievementKey) async {
    if (_userId == null) return;

    try {
      // Check if achievement already exists
      final existing = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('achievements')
          .doc(achievementKey)
          .get();

      if (!existing.exists) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('achievements')
            .doc(achievementKey)
            .set({
          'title': title,
          'description': description,
          'badgeIcon': badge,
          'unlockedAt': FieldValue.serverTimestamp(),
          'isNew': true,
          'key': achievementKey,
        });

        if (kDebugMode) {
          debugPrint('🏆 Created new achievement: $title');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating achievement: $e');
      }
    }
  }

  Future<void> _checkUpcomingReminders() async {
    // Check for hydration reminders, meal reminders, etc.
    final now = DateTime.now();
    
    // Example: Hydration reminder every 2 hours during day
    if (now.hour >= 8 && now.hour <= 20 && now.minute == 0 && now.hour % 2 == 0) {
      _alertService.showAlert(AlertData(
        id: 'hydration_${now.millisecondsSinceEpoch}',
        title: '💧 Stay Hydrated',
        message: 'Time to drink some water! Your body needs it.',
        type: AlertType.info,
        icon: Icons.water_drop,
        backgroundColor: Colors.blue[50],
        textColor: Colors.blue[800],
        duration: const Duration(seconds: 4),
      ));
    }
  }

  // Helper methods to mark notifications as processed
  Future<void> _markAchievementAsProcessed(String achievementId) async {
    if (_userId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('achievements')
          .doc(achievementId)
          .update({'isNew': false});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking achievement as processed: $e');
      }
    }
  }

  Future<void> _markSocialNotificationAsRead(String notificationId) async {
    if (_userId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('social_notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking social notification as read: $e');
      }
    }
  }

  Future<void> _markRecommendationAsDelivered(String recommendationId) async {
    if (_userId == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('ai_recommendations')
          .doc(recommendationId)
          .update({'delivered': true});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking recommendation as delivered: $e');
      }
    }
  }

  // Manual trigger methods for testing
  Future<void> triggerTestAchievement() async {
    await _createAchievement(
      'Test Achievement',
      'This is a test achievement triggered manually',
      '🎯',
      'test_achievement_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> triggerTestWorkoutComplete() async {
    await _notificationService.showWorkoutComplete(
      workoutType: 'Cardio',
      duration: 30,
      calories: 250,
    );

    _alertService.showWorkout(
      title: '🎉 Workout Complete!',
      message: 'Great job! You completed a 30-minute cardio workout and burned 250 calories.',
      onTap: () {
        if (kDebugMode) {
          debugPrint('🧭 Navigate to workout summary');
        }
      },
    );
  }

  Future<void> triggerTestSocialNotification() async {
    _alertService.showSocial(
      title: '👥 Sarah completed a workout',
      message: 'Sarah just finished a 45-minute yoga session. Give her some encouragement!',
      onTap: () {
        if (kDebugMode) {
          debugPrint('🧭 Navigate to Sarah\'s profile');
        }
      },
    );
  }

  // Clean up resources
  void dispose() {
    for (final subscription in _listeners.values) {
      subscription.cancel();
    }
    _listeners.clear();
    
    _achievementCheckTimer?.cancel();
    _reminderTimer?.cancel();
    
    _isInitialized = false;
    
    if (kDebugMode) {
      debugPrint('🧹 RealtimeNotificationManager disposed');
    }
  }
}