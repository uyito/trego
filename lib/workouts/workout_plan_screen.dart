import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trego/auth/auth_service.dart';
import 'package:trego/workouts/workout_service.dart';
import 'package:trego/workouts/workout_screen.dart'; // Added import for WorkoutScreen

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _userId;
  List<Map<String, dynamic>> _workouts = [];
  int _workoutStreak = 0;
  bool _isGenerating = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _userId = AuthService().currentUser?.uid;
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadCurrentWeekWorkouts();
    _loadWorkoutStreak();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentWeekWorkouts() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartString = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('workoutPlan')
          .where('weekStart', isEqualTo: weekStartString)
          .orderBy('day')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final workouts = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'day': data['day'] ?? '',
            'focus': data['focus'] ?? '',
            'exercises': List<String>.from(data['exercises'] ?? []),
            'completed': data['completed'] ?? false,
            'weekStart': data['weekStart'] ?? '',
          };
        }).toList();

        setState(() {
          _workouts = workouts;
          _isLoading = false;
        });
      } else {
        // No workouts for this week, generate new plan
        await _generateWorkoutPlan();
      }
      
      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      print('Error loading current week workouts: $e');
      setState(() {
        _isLoading = false;
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

  Future<void> _generateWorkoutPlan() async {
    if (_userId == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final workoutService = WorkoutService();
      final workouts = await workoutService.generateWorkoutPlan(
        fitnessGoal: 'Lose Fat',
        experienceLevel: 'Beginner',
        workoutDays: 3,
        hasGymAccess: true,
      );

      // Save to Firestore
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartString = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      final batch = FirebaseFirestore.instance.batch();

      for (final workout in workouts) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('workoutPlan')
            .doc();

        batch.set(docRef, {
          'day': workout['day'],
          'focus': workout['focus'],
          'exercises': workout['exercises'],
          'completed': false,
          'weekStart': weekStartString,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      setState(() {
        _workouts = workouts;
        _isGenerating = false;
      });
    } catch (e) {
      print('Error generating workout plan: $e');
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _toggleWorkoutCompletion(String workoutId, bool completed) async {
    if (_userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('workoutPlan')
          .doc(workoutId)
          .update({'completed': completed});

      // Update local state
      setState(() {
        final index = _workouts.indexWhere((w) => w['id'] == workoutId);
        if (index != -1) {
          _workouts[index] = {
            ..._workouts[index],
            'completed': completed,
          };
        }
      });

      // Update streak
      await _updateWorkoutStreak(completed);
      
      if (completed) {
        _showConfetti();
      }
    } catch (e) {
      print('Error updating workout completion: $e');
    }
  }

  Future<void> _updateWorkoutStreak(bool completed) async {
    if (_userId == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('streak')
          .doc('workout');

      if (completed) {
        // Increment streak
        await docRef.set({
          'count': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        setState(() {
          _workoutStreak++;
        });
      } else {
        // Reset streak
        await docRef.set({
          'count': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        setState(() {
          _workoutStreak = 0;
        });
      }
    } catch (e) {
      print('Error updating workout streak: $e');
    }
  }

  Future<void> _resetWeek() async {
    if (_userId == null) return;

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartString = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      // Copy previous week's plan
      final previousWeekStart = weekStart.subtract(const Duration(days: 7));
      final previousWeekStartString = '${previousWeekStart.year}-${previousWeekStart.month.toString().padLeft(2, '0')}-${previousWeekStart.day.toString().padLeft(2, '0')}';

      final previousWorkouts = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('workoutPlan')
          .where('weekStart', isEqualTo: previousWeekStartString)
          .get();

      if (previousWorkouts.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();

        for (final doc in previousWorkouts.docs) {
          final data = doc.data();
          final newDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .collection('workoutPlan')
              .doc();

          batch.set(newDocRef, {
            'day': data['day'],
            'focus': data['focus'],
            'exercises': data['exercises'],
            'completed': false,
            'weekStart': weekStartString,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
        await _loadCurrentWeekWorkouts();
      } else {
        // No previous week data, generate new plan
        await _generateWorkoutPlan();
      }
    } catch (e) {
      print('Error resetting week: $e');
    }
  }

  void _showConfetti() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Workout completed! Keep the streak alive! 💪'),
          ],
        ),
        backgroundColor: const Color(0xFF00C851),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showWorkoutHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WorkoutScreen(),
      ),
    );
  }

  void _showWorkoutTemplates() {
    // TODO: Implement workout templates screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout templates feature coming soon!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE31E24),
              ),
            )
          : CustomScrollView(
              slivers: [
                // Hero Banner
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF00C851),
                          Color(0xFF4CAF50),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C851).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'This Week\'s Plan',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        'Stay consistent, stay strong',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Hero Stats
                            Row(
                              children: [
                                Expanded(
                                  child: _buildHeroStat(
                                    icon: '🔥',
                                    value: '$_workoutStreak',
                                    label: 'Day Streak',
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildHeroStat(
                                    icon: '✅',
                                    value: '${_workouts.where((w) => w['completed'] == true).length}',
                                    label: 'Completed',
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Main Content
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Action Buttons
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                onPressed: _isGenerating ? null : _generateWorkoutPlan,
                                icon: Icons.auto_awesome_rounded,
                                label: _isGenerating ? 'Generating...' : 'Generate Plan',
                                color: const Color(0xFFE31E24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                onPressed: _resetWeek,
                                icon: Icons.refresh_rounded,
                                label: 'Reset Week',
                                color: const Color(0xFF9C27B0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Additional Action Buttons
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                onPressed: _showWorkoutHistory,
                                icon: Icons.history_rounded,
                                label: 'History',
                                color: const Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                onPressed: _showWorkoutTemplates,
                                icon: Icons.list_alt_rounded,
                                label: 'Templates',
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Workout Days
                      ..._workouts.map((workout) => _buildWorkoutDay(workout)).toList(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
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
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -1.0,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPressed != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutDay(Map<String, dynamic> workout) {
    final day = workout['day'] as String? ?? '';
    final focus = workout['focus'] as String? ?? '';
    final exercises = List<String>.from(workout['exercises'] ?? []);
    final completed = workout['completed'] as bool? ?? false;
    final workoutId = workout['id'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: completed 
            ? const Color(0xFF00C851).withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: completed 
              ? const Color(0xFF00C851).withOpacity(0.3)
              : const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: completed 
                        ? const Color(0xFF00C851)
                        : const Color(0xFFE31E24).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    completed ? Icons.check_rounded : Icons.fitness_center_rounded,
                    color: completed ? Colors.white : const Color(0xFFE31E24),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: completed 
                              ? const Color(0xFF00C851)
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        focus,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: completed 
                              ? const Color(0xFF00C851)
                              : const Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: completed,
                  onChanged: (value) => _toggleWorkoutCompletion(workoutId, value),
                  activeColor: const Color(0xFF00C851),
                ),
              ],
            ),
          ),
          
          // Exercises
          if (exercises.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exercises:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...exercises.map((exercise) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE31E24),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            exercise,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
