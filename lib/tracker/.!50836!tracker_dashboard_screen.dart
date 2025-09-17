import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:trego/auth/auth_service.dart';
import 'package:trego/tracker/tracker_service.dart';
import 'package:trego/tracker/weekly_summary_screen.dart';
import 'package:trego/tracker/run_tracker_screen.dart';
import 'package:trego/achievements/achievement_service.dart';
import 'package:trego/workouts/workout_screen.dart';
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
