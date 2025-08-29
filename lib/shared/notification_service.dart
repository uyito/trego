import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

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

    await _notifications.initialize(initSettings);
  }

  Future<void> requestPermissions() async {
    await _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> scheduleWaterReminders() async {
    // Cancel existing water reminders
    await _notifications.cancelAll();

    // Schedule water reminders every 2 hours from 8 AM to 8 PM
    for (int hour = 8; hour <= 20; hour += 2) {
      await _scheduleNotification(
        id: hour,
        title: 'Stay Hydrated! 💧',
        body: 'Time to drink some water. Your body needs it!',
        scheduledDate: _getNextInstanceOfTime(hour, 0),
        repeatInterval: RepeatInterval.daily,
      );
    }
  }

  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
  }) async {
    // Cancel existing workout reminder
    await _notifications.cancel(999);

    await _scheduleNotification(
      id: 999,
      title: 'Time to Work Out! 💪',
      body: 'Your scheduled workout time is here. Let\'s get moving!',
      scheduledDate: _getNextInstanceOfTime(hour, minute),
      repeatInterval: RepeatInterval.daily,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required RepeatInterval repeatInterval,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'fitness_reminders',
      'Fitness Reminders',
      channelDescription: 'Reminders for water intake and workouts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  DateTime _getNextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
} 