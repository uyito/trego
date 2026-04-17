import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static NotificationService? _instance;
  late FlutterLocalNotificationsPlugin _localNotifications;
  bool _isInitialized = false;
  
  // Notification channels
  static const String _workoutChannel = 'workout_notifications';
  static const String _socialChannel = 'social_notifications';
  static const String _achievementChannel = 'achievement_notifications';
  static const String _reminderChannel = 'reminder_notifications';
  static const String _aiChannel = 'ai_recommendations';

  NotificationService._();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    _localNotifications = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannels();
    await _requestPermissions();
    
    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('🔔 NotificationService initialized successfully');
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _workoutChannel,
          'Workout Notifications',
          description: 'Notifications for workout reminders and updates',
          importance: Importance.high,
          playSound: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _socialChannel,
          'Social Notifications',
          description: 'Notifications for friend activities and challenges',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _achievementChannel,
          'Achievement Notifications',
          description: 'Notifications for unlocked achievements and milestones',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _reminderChannel,
          'Reminder Notifications',
          description: 'Daily reminders for meals, hydration, and activities',
          importance: Importance.defaultImportance,
          playSound: false,
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _aiChannel,
          'AI Recommendations',
          description: 'Personalized AI recommendations and insights',
          importance: Importance.defaultImportance,
          playSound: false,
        ),
      );
    }
  }

  Future<bool> _requestPermissions() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }

    final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }

    return true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('🔔 Notification tapped: ${response.payload}');
    }

    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final route = data['route'] as String?;

    if (route != null) {
      // This would typically use a global navigator or routing service
      if (kDebugMode) {
        debugPrint('🧭 Would navigate to: $route');
      }
    }
  }

  // Workout Notifications
  Future<void> scheduleWorkoutReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? workoutId,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _workoutChannel,
          'Workout Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode({
        'type': 'workout_reminder',
        'workoutId': workoutId,
        'route': '/workouts',
      }),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    await _saveScheduledNotification(id, 'workout_reminder', scheduledTime);

    if (kDebugMode) {
      debugPrint('🏋️ Workout reminder scheduled for $scheduledTime');
    }
  }

  Future<void> showWorkoutComplete({
    required String workoutType,
    required int duration,
    required int calories,
  }) async {
    const id = 1001;

    await _localNotifications.show(
      id,
      '🎉 Workout Complete!',
      'Great job! You completed a $workoutType workout in ${duration}min and burned $calories calories.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _workoutChannel,
          'Workout Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(''),
          actions: [
            const AndroidNotificationAction(
              'view_summary',
              'View Summary',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'share',
              'Share',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode({
        'type': 'workout_complete',
        'workoutType': workoutType,
        'duration': duration,
        'calories': calories,
        'route': '/tracker/summary',
      }),
    );
  }

  // Achievement Notifications
  Future<void> showAchievementUnlocked({
    required String title,
    required String description,
    required String badgeIcon,
    String? achievementId,
  }) async {
    const id = 2001;

    await _localNotifications.show(
      id,
      '🏆 Achievement Unlocked!',
      '$title - $description',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _achievementChannel,
          'Achievement Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(''),
          enableVibration: true,
          actions: [
            const AndroidNotificationAction(
              'view_achievement',
              'View Achievement',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'share_achievement',
              'Share',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode({
        'type': 'achievement_unlocked',
        'achievementId': achievementId,
        'title': title,
        'route': '/achievements',
      }),
    );

    if (kDebugMode) {
      debugPrint('🏆 Achievement notification shown: $title');
    }
  }

  // Social Notifications
  Future<void> showFriendActivity({
    required String friendName,
    required String activity,
    String? friendId,
  }) async {
    final id = 3000 + DateTime.now().millisecondsSinceEpoch % 1000;

    await _localNotifications.show(
      id,
      '👥 Friend Activity',
      '$friendName $activity',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _socialChannel,
          'Social Notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          actions: [
            const AndroidNotificationAction(
              'view_profile',
              'View Profile',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'like',
              'Like',
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
      payload: jsonEncode({
        'type': 'friend_activity',
        'friendId': friendId,
        'friendName': friendName,
        'route': '/social',
      }),
    );
  }

  // Legacy method for backward compatibility
  Future<void> scheduleWaterReminders() async {
    await scheduleDailyReminders();
  }

  // Legacy method for backward compatibility
  Future<void> scheduleWorkoutReminderLegacy({
    required int hour,
    required int minute,
  }) async {
    await scheduleWorkoutReminder(
      title: 'Time to Work Out! 💪',
      body: 'Your scheduled workout time is here. Let\'s get moving!',
      scheduledTime: _getNextInstanceOfTime(hour, minute),
    );
  }

  // Daily Reminders
  Future<void> scheduleDailyReminders() async {
    // Clear existing reminders
    await _cancelReminderNotifications();

    // Hydration reminder - every 2 hours from 8 AM to 8 PM
    for (int hour = 8; hour <= 20; hour += 2) {
      await _scheduleRepeatingNotification(
        id: 4000 + hour,
        title: '💧 Hydration Reminder',
        body: 'Time to drink some water! Stay hydrated throughout your day.',
        hour: hour,
        minute: 0,
        channelId: _reminderChannel,
        type: 'hydration_reminder',
      );
    }

    // Meal reminders
    await _scheduleRepeatingNotification(
      id: 4100,
      title: '🍳 Breakfast Time',
      body: 'Start your day with a healthy breakfast!',
      hour: 8,
      minute: 0,
      channelId: _reminderChannel,
      type: 'meal_reminder',
    );

    await _scheduleRepeatingNotification(
      id: 4101,
      title: '🥗 Lunch Time',
      body: 'Time for a nutritious lunch to fuel your afternoon!',
      hour: 12,
      minute: 30,
      channelId: _reminderChannel,
      type: 'meal_reminder',
    );

    await _scheduleRepeatingNotification(
      id: 4102,
      title: '🍽️ Dinner Time',
      body: 'Don\'t forget to log your dinner and track your nutrition!',
      hour: 18,
      minute: 30,
      channelId: _reminderChannel,
      type: 'meal_reminder',
    );

    // Daily workout reminder
    await _scheduleRepeatingNotification(
      id: 4200,
      title: '💪 Workout Time',
      body: 'Ready for today\'s workout? Let\'s achieve your fitness goals!',
      hour: 17,
      minute: 0,
      channelId: _workoutChannel,
      type: 'daily_workout',
    );

    if (kDebugMode) {
      debugPrint('📅 Daily reminders scheduled successfully');
    }
  }

  Future<void> _scheduleRepeatingNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String type,
  }) async {
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(_getNextInstanceOfTime(hour, minute), tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == _workoutChannel ? 'Workout Notifications' : 'Reminder Notifications',
          importance: channelId == _workoutChannel ? Importance.high : Importance.defaultImportance,
          priority: channelId == _workoutChannel ? Priority.high : Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      payload: jsonEncode({
        'type': type,
        'route': type.contains('workout') ? '/workouts' : '/tracker',
      }),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  DateTime _getNextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // AI Recommendation Notifications
  Future<void> showAIRecommendation({
    required String title,
    required String recommendation,
    String? category,
  }) async {
    final id = 5000 + DateTime.now().millisecondsSinceEpoch % 1000;

    await _localNotifications.show(
      id,
      '🤖 $title',
      recommendation,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _aiChannel,
          'AI Recommendations',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(''),
          actions: [
            const AndroidNotificationAction(
              'view_recommendations',
              'View All',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      payload: jsonEncode({
        'type': 'ai_recommendation',
        'category': category,
        'route': '/personalization/recommendations',
      }),
    );
  }

  // Notification Management
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> _cancelReminderNotifications() async {
    // Cancel hydration reminders
    for (int hour = 8; hour <= 20; hour += 2) {
      await _localNotifications.cancel(4000 + hour);
    }
    
    // Cancel meal reminders
    await _localNotifications.cancel(4100);
    await _localNotifications.cancel(4101);
    await _localNotifications.cancel(4102);
    
    // Cancel workout reminder
    await _localNotifications.cancel(4200);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Storage helpers for scheduled notifications
  Future<void> _saveScheduledNotification(int id, String type, DateTime scheduledTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('scheduled_notifications') ?? [];
      
      final notification = jsonEncode({
        'id': id,
        'type': type,
        'scheduledTime': scheduledTime.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      notifications.add(notification);
      await prefs.setStringList('scheduled_notifications', notifications);
    } catch (e) {
      debugPrint('Error saving scheduled notification: $e');
    }
  }

  Future<void> clearExpiredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('scheduled_notifications') ?? [];
      final now = DateTime.now();
      
      final activeNotifications = notifications.where((notificationStr) {
        try {
          final notification = jsonDecode(notificationStr);
          final scheduledTime = DateTime.parse(notification['scheduledTime']);
          return scheduledTime.isAfter(now);
        } catch (e) {
          return false;
        }
      }).toList();
      
      await prefs.setStringList('scheduled_notifications', activeNotifications);
    } catch (e) {
      debugPrint('Error clearing expired notifications: $e');
    }
  }

  // Settings
  Future<void> updateNotificationSettings({
    bool? workoutReminders,
    bool? socialNotifications,
    bool? achievementAlerts,
    bool? dailyReminders,
    bool? aiRecommendations,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (workoutReminders != null) {
        await prefs.setBool('notifications_workout', workoutReminders);
      }
      if (socialNotifications != null) {
        await prefs.setBool('notifications_social', socialNotifications);
      }
      if (achievementAlerts != null) {
        await prefs.setBool('notifications_achievements', achievementAlerts);
      }
      if (dailyReminders != null) {
        await prefs.setBool('notifications_reminders', dailyReminders);
        
        if (dailyReminders) {
          await scheduleDailyReminders();
        } else {
          await _cancelReminderNotifications();
        }
      }
      if (aiRecommendations != null) {
        await prefs.setBool('notifications_ai', aiRecommendations);
      }

      if (kDebugMode) {
        debugPrint('🔔 Notification settings updated');
      }
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
    }
  }

  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'workoutReminders': prefs.getBool('notifications_workout') ?? true,
        'socialNotifications': prefs.getBool('notifications_social') ?? true,
        'achievementAlerts': prefs.getBool('notifications_achievements') ?? true,
        'dailyReminders': prefs.getBool('notifications_reminders') ?? true,
        'aiRecommendations': prefs.getBool('notifications_ai') ?? true,
      };
    } catch (e) {
      debugPrint('Error getting notification settings: $e');
      return {
        'workoutReminders': true,
        'socialNotifications': true,
        'achievementAlerts': true,
        'dailyReminders': true,
        'aiRecommendations': true,
      };
    }
  }
}