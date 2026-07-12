import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../shared/notification_service.dart';
import '../social/social_service.dart';
import 'push_api.dart';
import 'push_navigation.dart';

/// Orchestrates FCM: permission, token registration, foreground display, and
/// tap deep-linking. The testable parts (register/unregister, destination
/// mapping) live in [PushApi] and [handlePushDestination]; this class is the
/// thin plugin-facing glue and is exercised via manual/integration testing.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  /// Root navigator key — wired to the app's MaterialApp so a tapped push can
  /// navigate from any state (including cold start).
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final PushApi _api = PushApi();
  bool _started = false;
  String? _token;

  String get _platform => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// Idempotent: request permission, register this device's token, and wire the
  /// FCM listeners. Safe to call on every authenticated build.
  Future<void> onLogin() async {
    if (_started) return;
    _started = true;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(); // Android 13+ runtime prompt / iOS

    NotificationService.pushTapHandler = _handleData;

    final token = await messaging.getToken();
    if (token != null) {
      _token = token;
      await _api.registerToken(token, _platform);
    }
    messaging.onTokenRefresh.listen((refreshed) async {
      _token = refreshed;
      await _api.registerToken(refreshed, _platform);
    });

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleData(m.data));
    final initial = await messaging.getInitialMessage(); // cold-start tap
    if (initial != null) _handleData(initial.data);
  }

  /// Unregister this device's token and reset so a later login re-registers.
  Future<void> onLogout() async {
    if (_token != null) {
      await _api.unregisterToken(_token!);
      _token = null;
    }
    _started = false;
  }

  /// Foreground FCM message → show a local notification (OS won't display it
  /// while the app is foregrounded).
  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    NotificationService.instance.showPush(
      n?.title ?? 'Trego',
      n?.body ?? '',
      message.data.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  void _handleData(Map<String, dynamic> data) {
    handlePushDestination(data, navigatorKey: navigatorKey, social: SocialService());
  }
}
