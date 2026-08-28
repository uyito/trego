import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trego/auth/auth_service.dart';
import 'package:trego/workouts/workout_service.dart';
import 'package:trego/workouts/workout_screen.dart'; // Added import for WorkoutScreen
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';

/// Decorative accent colors for the plan-screen action buttons. These are
/// per-action hues with no matching semantic token role (Generate Plan
/// reuses tokens.brand since it's the primary action; the confetti
/// snackbar and hero banner reuse tokens.success since they're both
/// completion-themed greens already in the palette).
class _WorkoutPlanColors {
  static const resetWeek = Color(0xFF9C27B0); // ALLOW-HEX: action accent (purple), no token role fits a decorative per-action hue
  static const history = Color(0xFF2196F3); // ALLOW-HEX: action accent (blue), no token role fits a decorative per-action hue
  static const heroGradientEnd = Color(0xFF4CAF50); // ALLOW-HEX: decorative hero banner gradient end-stop (start uses tokens.success); no token role fits a second green stop
  _WorkoutPlanColors._();
}

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
    try {
      _userId = AuthService().currentUser?.uid;
    } catch (_) {
      // Auth unavailable (e.g. Firebase not configured in this context);
      // treat as signed-out.
      _userId = null;
    }

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
    final tokens = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.celebration, color: tokens.onSuccess),
            const SizedBox(width: Space.sm),
            Text(
              'Workout completed! Keep the streak alive! 💪',
              style: TextStyle(color: tokens.onSuccess),
            ),
          ],
        ),
        backgroundColor: tokens.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Space.md),
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
    final tokens = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Workout templates feature coming soon!',
          style: TextStyle(color: tokens.onSuccess),
        ),
        backgroundColor: tokens.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final typo = context.typo;
    return Scaffold(
      backgroundColor: tokens.canvas,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: tokens.brand,
              ),
            )
          : CustomScrollView(
              slivers: [
                // Hero Banner
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(Space.xl - Space.xs),
                    padding: const EdgeInsets.all(Space.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tokens.success,
                          _WorkoutPlanColors.heroGradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(Space.xl),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.success.withValues(alpha: 0.3),
                          blurRadius: Space.xl - Space.xs,
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
                                  padding: const EdgeInsets.all(Space.md),
                                  decoration: BoxDecoration(
                                    color: tokens.onSuccess.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(Space.md),
                                  ),
                                  child: Icon(
                                    Icons.fitness_center_rounded,
                                    color: tokens.onSuccess,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: Space.lg),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'This Week\'s Plan',
                                        style: typo.title.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: tokens.onSuccess,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        'Stay consistent, stay strong',
                                        style: typo.body.copyWith(
                                          color: tokens.onSuccess.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Space.xl),

                            // Hero Stats
                            Row(
                              children: [
                                Expanded(
                                  child: _buildHeroStat(
                                    icon: '🔥',
                                    value: '$_workoutStreak',
                                    label: 'Day Streak',
                                    color: tokens.onSuccess,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildHeroStat(
                                    icon: '✅',
                                    value: '${_workouts.where((w) => w['completed'] == true).length}',
                                    label: 'Completed',
                                    color: tokens.onSuccess,
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
                  padding: const EdgeInsets.symmetric(horizontal: Space.xl - Space.xs),
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
                                color: tokens.brand,
                              ),
                            ),
                            const SizedBox(width: Space.md),
                            Expanded(
                              child: _buildActionButton(
                                onPressed: _resetWeek,
                                icon: Icons.refresh_rounded,
                                label: 'Reset Week',
                                color: _WorkoutPlanColors.resetWeek,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.lg),

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
                                color: _WorkoutPlanColors.history,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                onPressed: _showWorkoutTemplates,
                                icon: Icons.list_alt_rounded,
                                label: 'Templates',
                                color: tokens.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.xl),

                      // Workout Days
                      ..._workouts.map((workout) => _buildWorkoutDay(workout)).toList(),
                      const SizedBox(height: Space.xxl + Space.sm),
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
        const SizedBox(height: Space.sm),
        Text(
          value,
          style: context.typo.statLarge.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -1.0,
          ),
        ),
        Text(
          label,
          style: context.typo.body.copyWith(
            color: color.withValues(alpha: 0.8),
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
    final tokens = context.tokens;
    return Container(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: tokens.onBrand,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Space.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPressed != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: Space.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: context.typo.button.copyWith(color: tokens.onBrand),
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
    final tokens = context.tokens;
    final typo = context.typo;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.lg),
      decoration: BoxDecoration(
        color: completed
            ? tokens.success.withValues(alpha: 0.1)
            : tokens.surface,
        borderRadius: BorderRadius.circular(Radii.screenWrapper),
        border: Border.all(
          color: completed
              ? tokens.success.withValues(alpha: 0.3)
              : tokens.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(Space.xl - Space.xs),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: completed
                        ? tokens.success
                        : tokens.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Space.md),
                  ),
                  child: Icon(
                    completed ? Icons.check_rounded : Icons.fitness_center_rounded,
                    color: completed ? tokens.onSuccess : tokens.brand,
                    size: 24,
                  ),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day,
                        style: typo.title.copyWith(
                          fontWeight: FontWeight.w700,
                          color: completed ? tokens.success : tokens.ink,
                        ),
                      ),
                      Text(
                        focus,
                        style: typo.body.copyWith(
                          color: completed ? tokens.success : tokens.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: completed,
                  onChanged: (value) => _toggleWorkoutCompletion(workoutId, value),
                  activeColor: tokens.success,
                ),
              ],
            ),
          ),

          // Exercises
          if (exercises.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Space.xl - Space.xs, vertical: Space.lg),
              decoration: BoxDecoration(
                color: tokens.surfaceSunken,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(Radii.screenWrapper),
                  bottomRight: Radius.circular(Radii.screenWrapper),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exercises:',
                    style: typo.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  ...exercises.map((exercise) => Padding(
                    padding: const EdgeInsets.only(bottom: Space.xs),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: tokens.brand,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Text(
                            exercise,
                            style: typo.body.copyWith(
                              color: tokens.inkMuted,
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
