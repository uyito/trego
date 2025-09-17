import 'package:flutter/material.dart';
import '../shared/app_theme.dart';
import '../widgets/nike_components.dart';
import '../widgets/nike_dashboard.dart';
import '../widgets/nike_animations.dart';
import '../widgets/nike_run_tracker.dart';

class NikeShowcaseScreen extends StatefulWidget {
  const NikeShowcaseScreen({super.key});

  @override
  State<NikeShowcaseScreen> createState() => _NikeShowcaseScreenState();
}

class _NikeShowcaseScreenState extends State<NikeShowcaseScreen>
    with TickerProviderStateMixin {
  bool _isRunning = false;
  Duration _runDuration = const Duration(minutes: 15, seconds: 30);
  double _distance = 2.5;
  double _pace = 5.2;
  int _heartRate = 142;
  bool _showConfetti = false;

  // Mock data for dashboard
  final Map<String, dynamic> _todayStats = {
    'steps': 8432,
    'stepsGoal': 10000,
    'calories': 1250,
    'distance': 5.2,
    'activeMinutes': 45,
    'progress': 0.7,
  };

  final List<Map<String, dynamic>> _recentActivities = [
    {
      'type': 'Running',
      'title': 'Morning Run',
      'duration': '32:15',
      'distance': '5.2 km',
      'pace': '6:12/km',
      'image': '',
    },
    {
      'type': 'Walking',
      'title': 'Evening Walk',
      'duration': '45:00',
      'distance': '3.8 km',
      'pace': '11:50/km',
      'image': '',
    },
  ];

  final Map<String, dynamic> _weeklyProgress = {
    'steps': [5000.0, 7800.0, 6500.0, 8900.0, 4300.0, 9200.0, 8432.0],
    'totalSteps': 50132,
  };

  final List<Map<String, dynamic>> _achievements = [
    {
      'title': '10K Steps',
      'description': 'Walked 10,000 steps in a day',
      'type': 'steps',
      'unlocked': true,
      'unlockedDate': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'title': '5K Runner',
      'description': 'Completed a 5km run',
      'type': 'distance',
      'unlocked': true,
      'unlockedDate': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'title': 'Week Warrior',
      'description': 'Exercised 7 days in a row',
      'type': 'streak',
      'unlocked': false,
      'unlockedDate': null,
    },
    {
      'title': 'Time Champion',
      'description': 'Exercised for 60 minutes',
      'type': 'time',
      'unlocked': false,
      'unlockedDate': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Nike UI Showcase',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Dashboard Demo'),
            SizedBox(
              height: 600,
              child: NikeDashboard(
                userName: 'John Doe',
                todayStats: _todayStats,
                recentActivities: _recentActivities,
                weeklyProgress: _weeklyProgress,
                achievements: _achievements,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Metric Cards'),
            _buildMetricCardsDemo(),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Action Buttons'),
            _buildButtonsDemo(),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Activity Cards'),
            _buildActivityCardsDemo(),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Progress Animations'),
            _buildAnimationsDemo(),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Achievement Badges'),
            _buildAchievementsDemo(),
            const SizedBox(height: 32),
            
            _buildSectionHeader('Run Tracker Demo'),
            Container(
              height: 600,
              child: NikeRunTracker(
                isRunning: _isRunning,
                duration: _runDuration,
                distance: _distance,
                pace: _pace,
                heartRate: _heartRate,
                paceHistory: const [5.1, 5.3, 4.9, 5.2, 5.4, 5.0, 5.2],
                onStartStop: () {
                  setState(() {
                    _isRunning = !_isRunning;
                    if (!_isRunning) {
                      _showConfetti = true;
                      Future.delayed(const Duration(seconds: 3), () {
                        setState(() => _showConfetti = false);
                      });
                    }
                  });
                },
                onPause: () {
                  setState(() => _isRunning = false);
                },
                onReset: () {
                  setState(() {
                    _isRunning = false;
                    _runDuration = Duration.zero;
                    _distance = 0.0;
                  });
                },
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: const NikeFloatingActionButton(
        icon: Icons.add,
        tooltip: 'Add Activity',
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: AppTheme.textTertiary,
        ),
      ),
    );
  }

  Widget _buildMetricCardsDemo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: NikeMetricCard(
                  title: 'Steps',
                  value: '8,432',
                  unit: '',
                  subtitle: 'Daily goal: 10,000',
                  color: AppTheme.primaryRed,
                  icon: Icons.directions_walk,
                  progress: 0.84,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NikeMetricCard(
                  title: 'Calories',
                  value: '1,250',
                  unit: 'kcal',
                  subtitle: 'Burned today',
                  color: AppTheme.nikeOrange,
                  icon: Icons.local_fire_department,
                  progress: 0.62,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NikeMetricCard(
                  title: 'Distance',
                  value: '5.2',
                  unit: 'km',
                  subtitle: 'Total distance',
                  color: AppTheme.primaryGreen,
                  icon: Icons.place,
                  progress: 0.52,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NikeMetricCard(
                  title: 'Active',
                  value: '45',
                  unit: 'min',
                  subtitle: 'Active time',
                  color: AppTheme.primaryBlue,
                  icon: Icons.timer,
                  progress: 0.75,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsDemo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          NikeActionButton(
            text: 'Start Workout',
            icon: Icons.play_arrow,
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          NikeActionButton(
            text: 'View Progress',
            isOutlined: true,
            icon: Icons.trending_up,
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          NikeActionButton(
            text: 'Loading...',
            isLoading: true,
            onPressed: null,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCardsDemo() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SizedBox(
            width: 300,
            child: NikeActivityCard(
              title: 'Morning Run',
              subtitle: 'Central Park Loop',
              duration: '32:15',
              distance: '5.2 km',
              pace: '6:12/km',
              color: AppTheme.runningPurple,
              backgroundImage: '',
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 300,
            child: NikeActivityCard(
              title: 'HIIT Workout',
              subtitle: 'Full Body Blast',
              duration: '25:00',
              distance: '0.0 km',
              pace: '0:00/km',
              color: AppTheme.workoutYellow,
              backgroundImage: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationsDemo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Activity Rings
          const Text(
            'Activity Rings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const NikeActivityRings(
            moveProgress: 0.8,
            exerciseProgress: 0.6,
            standProgress: 0.9,
            size: 150,
          ),
          const SizedBox(height: 32),
          
          // Loading Animation
          const Text(
            'Loading Animation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const NikeLoadingAnimation(),
          const SizedBox(height: 32),
          
          // Progress Wave
          const Text(
            'Progress Wave',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const NikeProgressWave(
            progress: 0.7,
            color: AppTheme.primaryRed,
            height: 60,
          ),
          const SizedBox(height: 32),
          
          // Pulse Animation
          const Text(
            'Pulse Animation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          NikePulseAnimation(
            color: AppTheme.primaryRed,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: AppTheme.primaryWhite,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsDemo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          final achievement = _achievements[index];
          return NikeAchievementBadge(
            title: achievement['title'],
            description: achievement['description'],
            icon: _getAchievementIcon(achievement['type']),
            color: _getAchievementColor(achievement['type']),
            isUnlocked: achievement['unlocked'],
            unlockedDate: achievement['unlockedDate'],
          );
        },
      ),
    );
  }

  IconData _getAchievementIcon(String type) {
    switch (type.toLowerCase()) {
      case 'distance':
        return Icons.place;
      case 'time':
        return Icons.timer;
      case 'streak':
        return Icons.local_fire_department;
      case 'steps':
        return Icons.directions_walk;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getAchievementColor(String type) {
    switch (type.toLowerCase()) {
      case 'distance':
        return AppTheme.primaryGreen;
      case 'time':
        return AppTheme.primaryBlue;
      case 'streak':
        return AppTheme.nikeOrange;
      case 'steps':
        return AppTheme.primaryRed;
      default:
        return AppTheme.primaryPurple;
    }
  }
}