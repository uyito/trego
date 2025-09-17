import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trego/auth/auth_service.dart';
import 'package:trego/tracker/tracker_service.dart';
import 'package:trego/tracker/weekly_summary_screen.dart';
import 'package:trego/achievements/achievement_service.dart';
import 'package:trego/tracker/weekly_recap_widget.dart';
import 'package:trego/tracker/live_run_tracker_screen.dart';
import 'package:trego/tracker/run_service.dart';
import 'dart:async';

class TrackerDashboardScreen extends StatefulWidget {
  const TrackerDashboardScreen({super.key});

  @override
  State<TrackerDashboardScreen> createState() => _TrackerDashboardScreenState();
}

class _TrackerDashboardScreenState extends State<TrackerDashboardScreen>
    with TickerProviderStateMixin {
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  
  String _currentDate = '';
  String? _userId;
  bool _isLoading = true;
  int _waterCups = 0;
  bool _workoutCompleted = false;
  double _calorieGoal = 2000.0;
  int _workoutStreak = 0;
  
  // Animation controllers
  late AnimationController _caloriesAnimationController;
  late AnimationController _waterAnimationController;
  late AnimationController _distanceAnimationController;
  late AnimationController _streakAnimationController;
  late Animation<double> _caloriesAnimation;
  late Animation<double> _waterAnimation;
  late Animation<double> _distanceAnimation;
  late Animation<double> _streakAnimation;

  @override
  void initState() {
    super.initState();
    _currentDate = _getCurrentDate();
    _userId = AuthService().currentUser?.uid;
    
    // Initialize animations
    _caloriesAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _waterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _distanceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _streakAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _caloriesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _caloriesAnimationController, curve: Curves.easeOutCubic),
    );
    _waterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waterAnimationController, curve: Curves.easeOutCubic),
    );
    _distanceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _distanceAnimationController, curve: Curves.easeOutCubic),
    );
    _streakAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _streakAnimationController, curve: Curves.easeOutCubic),
    );
    
    _loadData();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _weightController.dispose();
    _distanceController.dispose();
    _caloriesAnimationController.dispose();
    _waterAnimationController.dispose();
    _distanceAnimationController.dispose();
    _streakAnimationController.dispose();
    super.dispose();
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTodayData(),
      _loadUserTDEE(),
      _loadWorkoutStreak(),
    ]);
  }

  Future<void> _loadTodayData() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('logs')
          .doc(_currentDate)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _caloriesController.text = (data['calories'] ?? 0).toString();
          _waterCups = data['water'] ?? 0;
          _workoutCompleted = data['workoutDone'] ?? false;
          _weightController.text = (data['weight'] ?? '').toString();
          _distanceController.text = (data['distance'] ?? '').toString();
        });
      } else {
        // Initialize with default values
        setState(() {
          _caloriesController.text = '0';
          _waterCups = 0;
          _workoutCompleted = false;
          _weightController.text = '';
          _distanceController.text = '';
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      // Start animations after data loads
      _startAnimations();
    }
  }

  Future<void> _loadUserTDEE() async {
    if (_userId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('tdee')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final tdeeData = querySnapshot.docs.first.data();
        setState(() {
          _calorieGoal = (tdeeData['suggestedCalories'] ?? 2000.0).toDouble();
        });
      } else {
        // Default calorie goal if no TDEE data
        setState(() {
          _calorieGoal = 2000.0;
        });
      }
    } catch (e) {
      print('Error loading TDEE data: $e');
      // Default calorie goal on error
      setState(() {
        _calorieGoal = 2000.0;
      });
    }
  }

  Future<void> _loadWorkoutStreak() async {
    if (_userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('streak')
          .doc('workout')
          .get();

      if (doc.exists) {
        setState(() {
          _workoutStreak = doc.data()?['count'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading workout streak: $e');
    }
  }

  void _startAnimations() {
    _caloriesAnimationController.forward();
    _waterAnimationController.forward();
    _distanceAnimationController.forward();
    _streakAnimationController.forward();
  }

  Future<void> _saveData() async {
    if (_userId == null) return;

    try {
      final calories = int.tryParse(_caloriesController.text) ?? 0;
      final weight = double.tryParse(_weightController.text);
      final distance = double.tryParse(_distanceController.text) ?? 0.0;

      await TrackerService().saveDailyLog(
        userId: _userId!,
        date: _currentDate,
        data: {
          'calories': calories,
          'water': _waterCups,
          'workoutDone': _workoutCompleted,
          'weight': weight,
          'distance': distance,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data saved successfully!'),
          backgroundColor: Color(0xFF00C851),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: const Color(0xFFE31E24),
        ),
      );
    }
  }

  Future<void> _resetWeek() async {
    if (_userId == null) return;

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Clear current week data
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .where('date', isEqualTo: weekStartString)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Reset local state
      setState(() {
        _caloriesController.clear();
        _weightController.clear();
        _distanceController.clear();
        _waterCups = 0;
        _workoutCompleted = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Week reset successfully!'),
          backgroundColor: Color(0xFF00C851),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting week: $e'),
          backgroundColor: const Color(0xFFE31E24),
        ),
      );
    }
  }

  Future<List<dynamic>> _loadAchievementProgress() async {
    if (_userId == null) return [];

    try {
      final achievementService = AchievementService();
      final achievements = await achievementService.getUserAchievements(_userId!);
      
      return achievements.take(3).map((achievement) => {
        'title': achievement.title,
        'description': achievement.description,
        'progress': achievement.progress,
        'earned': achievement.earnedAt != null,
      }).toList();
    } catch (e) {
      print('Error loading achievements: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final runService = RunService.instance;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: StreamBuilder<bool>(
        stream: runService.isRunningStream,
        initialData: runService.isRunning,
        builder: (context, snapshot) {
          final isRunActive = snapshot.data ?? false;
          return Column(
            children: [
              if (isRunActive) _ActiveRunBanner(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE31E24),
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          // Hero Section
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFE31E24),
                                    Color(0xFFC62828),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE31E24).withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _workoutStreak > 0 
                                                  ? '🔥 $_workoutStreak-Day Streak'
                                                  : '🔥 Start Your Streak',
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _workoutStreak > 0 
                                                  ? 'Keep the momentum going!'
                                                  : 'Begin your fitness journey today',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Colors.white.withValues(alpha: 0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildHeroStat(
                                          icon: '📅',
                                          value: _getCurrentDate().split('-').last,
                                          label: 'Today',
                                          color: Colors.white,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildHeroStat(
                                          icon: '🎯',
                                          value: _workoutCompleted ? '✓' : '○',
                                          label: 'Workout',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Weekly Recap Widget
                          SliverToBoxAdapter(
                            child: const WeeklyRecapWidget(),
                          ),

                          // Stats Cards
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                const SizedBox(height: 8),
                                
                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LiveRunTrackerScreen(),
                                          ),
                                        ),
                                        icon: const Icon(Icons.play_arrow_rounded),
                                        label: const Text('Live Run'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00C851),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const WeeklySummaryScreen(),
                                          ),
                                        ),
                                        icon: const Icon(Icons.insights_rounded),
                                        label: const Text('Weekly'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1A1A1A),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Calories Card
                                FadeTransition(
                                  opacity: _caloriesAnimation,
                                  child: _buildStatCard(
                                    icon: Icons.local_fire_department_rounded,
                                    title: 'Calories',
                                    subtitle: 'Daily Goal',
                                    value: _caloriesController.text.isEmpty ? '0' : _caloriesController.text,
                                    goal: _calorieGoal.toInt().toString(),
                                    progress: _caloriesController.text.isEmpty 
                                        ? 0.0 
                                        : (int.tryParse(_caloriesController.text) ?? 0) / _calorieGoal,
                                    color: const Color(0xFFFF9800),
                                    onTap: () => _showCaloriesDialog(),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Water Card
                                FadeTransition(
                                  opacity: _waterAnimation,
                                  child: _buildStatCard(
                                    icon: Icons.water_drop_rounded,
                                    title: 'Water Intake',
                                    subtitle: 'Cups Today',
                                    value: _waterCups.toString(),
                                    goal: '8',
                                    progress: _waterCups / 8.0,
                                    color: const Color(0xFF2196F3),
                                    onTap: () => _showWaterDialog(),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Distance Card
                                FadeTransition(
                                  opacity: _distanceAnimation,
                                  child: _buildStatCard(
                                    icon: Icons.directions_run_rounded,
                                    title: 'Distance',
                                    subtitle: 'Kilometers',
                                    value: _distanceController.text.isEmpty ? '0.0' : _distanceController.text,
                                    goal: '5.0',
                                    progress: _distanceController.text.isEmpty 
                                        ? 0.0 
                                        : (double.tryParse(_distanceController.text) ?? 0.0) / 5.0,
                                    color: const Color(0xFF00C851),
                                    onTap: () => _showDistanceDialog(),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Achievement Progress Section
                                Card(
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
                                                color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.emoji_events_rounded,
                                                color: Color(0xFFFFD700),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Achievements',
                                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Track your progress',
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: const Color(0xFF666666),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        FutureBuilder<List<dynamic>>(
                                          future: _loadAchievementProgress(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                              return Column(
                                                children: snapshot.data!.take(3).map((achievement) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 12),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          achievement['earned'] ? Icons.emoji_events_rounded : Icons.lock_rounded,
                                                          color: achievement['earned'] ? const Color(0xFFFFD700) : Colors.grey,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                achievement['title'],
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.w600,
                                                                  color: achievement['earned'] ? Colors.black : Colors.grey,
                                                                ),
                                                              ),
                                                              if (!achievement['earned'])
                                                                Text(
                                                                  '${achievement['progress']} - ${achievement['description']}',
                                                                  style: const TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.grey,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            } else {
                                              return const Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Text(
                                                  'Loading achievements...',
                                                  style: TextStyle(color: Colors.grey),
                                                  textAlign: TextAlign.center,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 40),
                              ]),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroStat({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String goal,
    required double progress,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
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
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      Text(
                        'of $goal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF1A1A1A),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCaloriesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Calories'),
        content: TextField(
          controller: _caloriesController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Calories consumed today',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWaterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Water Intake'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: $_waterCups cups'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    if (_waterCups > 0) {
                      setState(() => _waterCups--);
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '$_waterCups',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _waterCups++);
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDistanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Distance'),
        content: TextField(
          controller: _distanceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Distance in kilometers',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Weight'),
        content: TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weight in kg',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleWorkout() {
    setState(() {
      _workoutCompleted = !_workoutCompleted;
    });
    _saveData();
  }
} 

class _ActiveRunBanner extends StatefulWidget {
  @override
  State<_ActiveRunBanner> createState() => _ActiveRunBannerState();
}

class _ActiveRunBannerState extends State<_ActiveRunBanner> {
  late final RunService _runService;
  late StreamSubscription<Duration> _durationSub;
  late StreamSubscription<double> _distanceSub;
  late StreamSubscription<bool> _isPausedSub;
  Duration _duration = Duration.zero;
  double _distance = 0.0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _runService = RunService.instance;
    _duration = _runService.currentDuration;
    _distance = _runService.currentDistance;
    _isPaused = _runService.isPaused;
    
    // Use a microtask to ensure the widget is properly mounted before setting up streams
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _durationSub = _runService.durationStream.listen((d) {
          if (mounted) setState(() => _duration = d);
        });
        _distanceSub = _runService.distanceStream.listen((d) {
          if (mounted) setState(() => _distance = d);
        });
        _isPausedSub = _runService.isPausedStream.listen((paused) {
          if (mounted) setState(() => _isPaused = paused);
        });
      }
    });
  }

  @override
  void dispose() {
    try {
      _durationSub.cancel();
    } catch (e) {
      // Stream might already be cancelled
    }
    try {
      _distanceSub.cancel();
    } catch (e) {
      // Stream might already be cancelled
    }
    try {
      _isPausedSub.cancel();
    } catch (e) {
      // Stream might already be cancelled
    }
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } else {
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE31E24),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LiveRunTrackerScreen(),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.directions_run_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Run', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(
                      '${_formatDuration(_duration)}   |   ${_distance.toStringAsFixed(2)} km',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (_isPaused)
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  onPressed: () => _runService.resumeRun(),
                  tooltip: 'Resume',
                )
              else
                IconButton(
                  icon: const Icon(Icons.pause_rounded, color: Colors.white),
                  onPressed: () => _runService.pauseRun(),
                  tooltip: 'Pause',
                ),
              IconButton(
                icon: const Icon(Icons.stop_rounded, color: Colors.white),
                onPressed: () async {
                  await _runService.stopRun();
                },
                tooltip: 'Stop',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 