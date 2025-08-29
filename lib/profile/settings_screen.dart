import 'package:flutter/material.dart';
import 'package:trego/shared/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  bool _waterRemindersEnabled = true;
  bool _workoutRemindersEnabled = false;
  TimeOfDay _workoutReminderTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // In a real app, you'd load these from shared preferences or Firestore
    setState(() {
      _waterRemindersEnabled = true;
      _workoutRemindersEnabled = false;
      _workoutReminderTime = const TimeOfDay(hour: 18, minute: 0);
    });
  }

  Future<void> _saveSettings() async {
    // In a real app, you'd save these to shared preferences or Firestore
    if (_waterRemindersEnabled) {
      await _notificationService.scheduleWaterReminders();
    } else {
      await _notificationService.cancelAllNotifications();
    }

    if (_workoutRemindersEnabled) {
      await _notificationService.scheduleWorkoutReminder(
        hour: _workoutReminderTime.hour,
        minute: _workoutReminderTime.minute,
      );
    } else {
      await _notificationService.cancelNotification(999);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _selectWorkoutTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workoutReminderTime,
    );
    
    if (picked != null && picked != _workoutReminderTime) {
      setState(() {
        _workoutReminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Settings',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Customize your fitness experience',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Notification Settings
                _buildSettingsCard(
                  title: 'Notifications',
                  subtitle: 'Manage your reminder preferences',
                  icon: Icons.notifications_rounded,
                  child: Column(
                    children: [
                      // Water Reminders
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.water_drop_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Water Reminders',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Get reminded to drink water every 2 hours',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _waterRemindersEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _waterRemindersEnabled = value;
                                });
                              },
                              activeColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Workout Reminders
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Workout Reminders',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Daily reminder to complete your workout',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _workoutRemindersEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _workoutRemindersEnabled = value;
                                    });
                                  },
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                            if (_workoutRemindersEnabled) ...[
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _selectWorkoutTime,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Reminder Time: ${_workoutReminderTime.format(context)}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.grey[400],
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Save Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // App Info
                _buildSettingsCard(
                  title: 'App Information',
                  subtitle: 'About Trego Fitness',
                  icon: Icons.info_rounded,
                  child: Column(
                    children: [
                      _buildInfoRow('Version', '1.0.0'),
                      _buildInfoRow('Build', '1'),
                      _buildInfoRow('Developer', 'Trego Team'),
                      _buildInfoRow('Support', 'support@trego.com'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 