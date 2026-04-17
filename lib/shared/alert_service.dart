import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

enum AlertType {
  success,
  error,
  warning,
  info,
  achievement,
  social,
  workout,
}

class AlertData {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration? duration;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  AlertData({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.duration,
    this.onTap,
    this.onDismiss,
    DateTime? timestamp,
    this.data,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AlertData.success({
    required String title,
    required String message,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    Map<String, dynamic>? data,
  }) {
    return AlertData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: AlertType.success,
      icon: Icons.check_circle,
      backgroundColor: Colors.green[50],
      textColor: Colors.green[800],
      duration: const Duration(seconds: 4),
      onTap: onTap,
      onDismiss: onDismiss,
      data: data,
    );
  }

  factory AlertData.error({
    required String title,
    required String message,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    Map<String, dynamic>? data,
  }) {
    return AlertData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: AlertType.error,
      icon: Icons.error,
      backgroundColor: Colors.red[50],
      textColor: Colors.red[800],
      duration: const Duration(seconds: 6),
      onTap: onTap,
      onDismiss: onDismiss,
      data: data,
    );
  }

  factory AlertData.warning({
    required String title,
    required String message,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    Map<String, dynamic>? data,
  }) {
    return AlertData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: AlertType.warning,
      icon: Icons.warning,
      backgroundColor: Colors.orange[50],
      textColor: Colors.orange[800],
      duration: const Duration(seconds: 5),
      onTap: onTap,
      onDismiss: onDismiss,
      data: data,
    );
  }

  factory AlertData.achievement({
    required String title,
    required String message,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    Map<String, dynamic>? data,
  }) {
    return AlertData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: AlertType.achievement,
      icon: Icons.emoji_events,
      backgroundColor: Colors.amber[50],
      textColor: Colors.amber[800],
      duration: const Duration(seconds: 8),
      onTap: onTap,
      onDismiss: onDismiss,
      data: data,
    );
  }

  factory AlertData.social({
    required String title,
    required String message,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    Map<String, dynamic>? data,
  }) {
    return AlertData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: AlertType.social,
      icon: Icons.people,
      backgroundColor: Colors.blue[50],
      textColor: Colors.blue[800],
      duration: const Duration(seconds: 5),
      onTap: onTap,
      onDismiss: onDismiss,
      data: data,
    );
  }

  factory AlertData.workout({
    required String title,
    required String message,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    Map<String, dynamic>? data,
  }) {
    return AlertData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: AlertType.workout,
      icon: Icons.fitness_center,
      backgroundColor: Colors.purple[50],
      textColor: Colors.purple[800],
      duration: const Duration(seconds: 6),
      onTap: onTap,
      onDismiss: onDismiss,
      data: data,
    );
  }
}

class AlertService {
  static AlertService? _instance;
  
  final StreamController<AlertData> _alertController = StreamController<AlertData>.broadcast();
  final List<AlertData> _alertHistory = [];
  Timer? _cleanupTimer;

  AlertService._() {
    _startCleanupTimer();
  }

  static AlertService get instance {
    _instance ??= AlertService._();
    return _instance!;
  }

  Stream<AlertData> get alertStream => _alertController.stream;
  List<AlertData> get alertHistory => List.unmodifiable(_alertHistory);

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupOldAlerts();
    });
  }

  void _cleanupOldAlerts() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _alertHistory.removeWhere((alert) => alert.timestamp.isBefore(cutoff));
  }

  void showAlert(AlertData alert) {
    _alertHistory.insert(0, alert);
    _alertController.add(alert);

    if (kDebugMode) {
      debugPrint('🚨 Alert: ${alert.title} - ${alert.message}');
    }
  }

  void showSuccess({
    required String title,
    required String message,
    VoidCallback? onTap,
    Map<String, dynamic>? data,
  }) {
    showAlert(AlertData.success(
      title: title,
      message: message,
      onTap: onTap,
      data: data,
    ));
  }

  void showError({
    required String title,
    required String message,
    VoidCallback? onTap,
    Map<String, dynamic>? data,
  }) {
    showAlert(AlertData.error(
      title: title,
      message: message,
      onTap: onTap,
      data: data,
    ));
  }

  void showWarning({
    required String title,
    required String message,
    VoidCallback? onTap,
    Map<String, dynamic>? data,
  }) {
    showAlert(AlertData.warning(
      title: title,
      message: message,
      onTap: onTap,
      data: data,
    ));
  }

  void showAchievement({
    required String title,
    required String message,
    VoidCallback? onTap,
    Map<String, dynamic>? data,
  }) {
    showAlert(AlertData.achievement(
      title: title,
      message: message,
      onTap: onTap,
      data: data,
    ));
  }

  void showSocial({
    required String title,
    required String message,
    VoidCallback? onTap,
    Map<String, dynamic>? data,
  }) {
    showAlert(AlertData.social(
      title: title,
      message: message,
      onTap: onTap,
      data: data,
    ));
  }

  void showWorkout({
    required String title,
    required String message,
    VoidCallback? onTap,
    Map<String, dynamic>? data,
  }) {
    showAlert(AlertData.workout(
      title: title,
      message: message,
      onTap: onTap,
      data: data,
    ));
  }

  void clearHistory() {
    _alertHistory.clear();
  }

  List<AlertData> getAlertsByType(AlertType type) {
    return _alertHistory.where((alert) => alert.type == type).toList();
  }

  List<AlertData> getUnreadAlerts() {
    // In a real implementation, this would track read/unread status
    return _alertHistory.take(10).toList();
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _alertController.close();
  }
}

class InAppAlertWidget extends StatefulWidget {
  final Widget child;

  const InAppAlertWidget({super.key, required this.child});

  @override
  State<InAppAlertWidget> createState() => _InAppAlertWidgetState();
}

class _InAppAlertWidgetState extends State<InAppAlertWidget>
    with TickerProviderStateMixin {
  late StreamSubscription<AlertData> _alertSubscription;
  final List<_AlertDisplay> _activeAlerts = [];

  @override
  void initState() {
    super.initState();
    _alertSubscription = AlertService.instance.alertStream.listen(_showAlert);
  }

  @override
  void dispose() {
    _alertSubscription.cancel();
    for (final alert in _activeAlerts) {
      alert.controller.dispose();
    }
    super.dispose();
  }

  void _showAlert(AlertData alert) {
    if (!mounted) return;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    final alertDisplay = _AlertDisplay(
      alert: alert,
      controller: controller,
      onDismiss: () => _dismissAlert(alert.id),
    );

    setState(() {
      _activeAlerts.add(alertDisplay);
    });

    controller.forward();

    // Auto dismiss
    if (alert.duration != null) {
      Timer(alert.duration!, () {
        _dismissAlert(alert.id);
      });
    }
  }

  void _dismissAlert(String alertId) {
    if (!mounted) return;

    final alertIndex = _activeAlerts.indexWhere((a) => a.alert.id == alertId);
    if (alertIndex == -1) return;

    final alertDisplay = _activeAlerts[alertIndex];
    
    alertDisplay.controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _activeAlerts.removeAt(alertIndex);
        });
        alertDisplay.controller.dispose();
        alertDisplay.alert.onDismiss?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: _activeAlerts.map((alertDisplay) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: alertDisplay.controller,
                      curve: Curves.elasticOut,
                    )),
                    child: FadeTransition(
                      opacity: alertDisplay.controller,
                      child: _AlertCard(
                        alert: alertDisplay.alert,
                        onDismiss: alertDisplay.onDismiss,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertDisplay {
  final AlertData alert;
  final AnimationController controller;
  final VoidCallback onDismiss;

  _AlertDisplay({
    required this.alert,
    required this.controller,
    required this.onDismiss,
  });
}

class _AlertCard extends StatelessWidget {
  final AlertData alert;
  final VoidCallback onDismiss;

  const _AlertCard({
    required this.alert,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: alert.backgroundColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.textColor?.withValues(alpha: 0.2) ?? Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          alert.onTap?.call();
          onDismiss();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (alert.icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: alert.textColor?.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alert.icon,
                    color: alert.textColor,
                    size: 20,
                  ),
                ),
              if (alert.icon != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(
                        color: alert.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: TextStyle(
                        color: alert.textColor?.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  Icons.close,
                  color: alert.textColor?.withValues(alpha: 0.6),
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}