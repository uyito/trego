import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'realtime_notification_manager.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  final RealtimeNotificationManager _realtimeManager = RealtimeNotificationManager.instance;
  
  Map<String, bool> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _notificationService.getNotificationSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    setState(() {
      _settings[key] = value;
    });

    try {
      await _notificationService.updateNotificationSettings(
        workoutReminders: key == 'workoutReminders' ? value : null,
        socialNotifications: key == 'socialNotifications' ? value : null,
        achievementAlerts: key == 'achievementAlerts' ? value : null,
        dailyReminders: key == 'dailyReminders' ? value : null,
        aiRecommendations: key == 'aiRecommendations' ? value : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getSettingTitle(key)} ${value ? 'enabled' : 'disabled'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Revert the change
      setState(() {
        _settings[key] = !value;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating setting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSettingTitle(String key) {
    switch (key) {
      case 'workoutReminders':
        return 'Workout Reminders';
      case 'socialNotifications':
        return 'Social Notifications';
      case 'achievementAlerts':
        return 'Achievement Alerts';
      case 'dailyReminders':
        return 'Daily Reminders';
      case 'aiRecommendations':
        return 'AI Recommendations';
      default:
        return key;
    }
  }

  String _getSettingDescription(String key) {
    switch (key) {
      case 'workoutReminders':
        return 'Get notified about scheduled workouts and exercise suggestions';
      case 'socialNotifications':
        return 'Receive updates about friend activities and challenges';
      case 'achievementAlerts':
        return 'Celebrate your milestones with achievement notifications';
      case 'dailyReminders':
        return 'Daily reminders for meals, hydration, and activities';
      case 'aiRecommendations':
        return 'Personalized suggestions powered by AI';
      default:
        return '';
    }
  }

  IconData _getSettingIcon(String key) {
    switch (key) {
      case 'workoutReminders':
        return Icons.fitness_center;
      case 'socialNotifications':
        return Icons.people;
      case 'achievementAlerts':
        return Icons.emoji_events;
      case 'dailyReminders':
        return Icons.schedule;
      case 'aiRecommendations':
        return Icons.auto_awesome;
      default:
        return Icons.notifications;
    }
  }

  Color _getSettingColor(String key) {
    switch (key) {
      case 'workoutReminders':
        return Colors.purple;
      case 'socialNotifications':
        return Colors.blue;
      case 'achievementAlerts':
        return Colors.amber;
      case 'dailyReminders':
        return Colors.orange;
      case 'aiRecommendations':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSettingsContent(),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildNotificationSettings(),
          const SizedBox(height: 32),
          _buildTestSection(),
          const SizedBox(height: 32),
          _buildAdvancedSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay Connected',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Customize your notification preferences to stay motivated and connected.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Types',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._settings.keys.map((key) => _buildSettingTile(key)),
      ],
    );
  }

  Widget _buildSettingTile(String key) {
    final isEnabled = _settings[key] ?? false;
    final color = _getSettingColor(key);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        value: isEnabled,
        onChanged: (value) => _updateSetting(key, value),
        title: Text(
          _getSettingTitle(key),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          _getSettingDescription(key),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getSettingIcon(key),
            color: color,
            size: 24,
          ),
        ),
        activeColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Test Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Test your notification settings with sample notifications.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTestButton(
                  'Achievement',
                  Icons.emoji_events,
                  Colors.amber,
                  () => _realtimeManager.triggerTestAchievement(),
                ),
                _buildTestButton(
                  'Workout Complete',
                  Icons.fitness_center,
                  Colors.purple,
                  () => _realtimeManager.triggerTestWorkoutComplete(),
                ),
                _buildTestButton(
                  'Social Activity',
                  Icons.people,
                  Colors.blue,
                  () => _realtimeManager.triggerTestSocialNotification(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Advanced Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Schedule Daily Reminders'),
              subtitle: const Text('Set up your daily notification schedule'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _scheduleDailyReminders,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear All Notifications'),
              subtitle: const Text('Remove all pending notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _clearAllNotifications,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Pending Notifications'),
              subtitle: const Text('See what notifications are scheduled'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _viewPendingNotifications,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleDailyReminders() async {
    try {
      await _notificationService.scheduleDailyReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily reminders scheduled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all pending notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.cancelAllNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing notifications: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _viewPendingNotifications() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Pending Notifications (${pending.length})'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: pending.isEmpty
                  ? const Center(child: Text('No pending notifications'))
                  : ListView.builder(
                      itemCount: pending.length,
                      itemBuilder: (context, index) {
                        final notification = pending[index];
                        return ListTile(
                          leading: const Icon(Icons.schedule),
                          title: Text(notification.title ?? 'Notification'),
                          subtitle: Text(notification.body ?? ''),
                          trailing: Text('ID: ${notification.id}'),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings Help'),
        content: const SingleChildScrollView(
          child: Text(
            '• Workout Reminders: Get notified about scheduled workouts and exercise suggestions\n\n'
            '• Social Notifications: Receive updates about friend activities and challenges\n\n'
            '• Achievement Alerts: Celebrate your milestones with achievement notifications\n\n'
            '• Daily Reminders: Regular reminders for meals, hydration, and activities\n\n'
            '• AI Recommendations: Personalized suggestions powered by AI\n\n'
            'You can test each notification type to see how they appear on your device.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}