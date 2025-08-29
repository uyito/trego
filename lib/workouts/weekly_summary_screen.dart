import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trego/auth/auth_service.dart';
import 'package:trego/shared/app_theme.dart';

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen>
    with TickerProviderStateMixin {
  String? _userId;
  bool _isLoading = true;
  
  // Weekly stats
  int _completedWorkouts = 0;
  int _totalWorkouts = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  double _completionRate = 0.0;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

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
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _loadWeeklyData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyData() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartString = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      // Load current week workouts
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('workoutPlan')
          .where('weekStart', isEqualTo: weekStartString)
          .get();

      int completed = 0;
      int total = workoutSnapshot.docs.length;
      
      for (final doc in workoutSnapshot.docs) {
        if (doc.data()['completed'] == true) {
          completed++;
        }
      }

      // Load streak data
      final streakDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('streak')
          .doc('workout')
          .get();

      int currentStreak = 0;
      int longestStreak = 0;
      
      if (streakDoc.exists) {
        currentStreak = streakDoc.data()?['count'] ?? 0;
        longestStreak = streakDoc.data()?['longest'] ?? 0;
      }

      if (mounted) {
        setState(() {
          _completedWorkouts = completed;
          _totalWorkouts = total;
          _currentStreak = currentStreak;
          _longestStreak = longestStreak;
          _completionRate = total > 0 ? completed / total : 0.0;
          _isLoading = false;
        });
        
        // Start animations
        _fadeController.forward();
        _slideController.forward();
        _progressController.forward();
      }
    } catch (e) {
      print('Error loading weekly data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Weekly Summary',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryRed,
              ),
            )
          : CustomScrollView(
              slivers: [
                // Hero Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(AppTheme.spacingM),
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      boxShadow: AppTheme.buttonShadow,
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
                                  padding: const EdgeInsets.all(AppTheme.spacingM),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'This Week',
                                        style: AppTheme.headlineSmall.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Your fitness journey continues',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            
                            // Progress Circle
                            Center(
                              child: AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Background circle
                                        Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                        ),
                                        // Progress circle
                                        SizedBox(
                                          width: 120,
                                          height: 120,
                                          child: CircularProgressIndicator(
                                            value: _completionRate * _progressAnimation.value,
                                            strokeWidth: 8,
                                            backgroundColor: Colors.white.withOpacity(0.3),
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        // Center text
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${(_completionRate * 100).round()}%',
                                              style: AppTheme.headlineMedium.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            Text(
                                              'Complete',
                                              style: AppTheme.bodySmall.copyWith(
                                                color: Colors.white.withOpacity(0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Stats Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: AppTheme.spacingM,
                      mainAxisSpacing: AppTheme.spacingM,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildStatCard(
                        icon: '💪',
                        title: 'Completed',
                        value: '$_completedWorkouts',
                        subtitle: 'of $_totalWorkouts',
                        color: AppTheme.primaryGreen,
                      ),
                      _buildStatCard(
                        icon: '🔥',
                        title: 'Current Streak',
                        value: '$_currentStreak',
                        subtitle: 'days',
                        color: AppTheme.primaryOrange,
                      ),
                      _buildStatCard(
                        icon: '🏆',
                        title: 'Longest Streak',
                        value: '$_longestStreak',
                        subtitle: 'days',
                        color: AppTheme.primaryBlue,
                      ),
                      _buildStatCard(
                        icon: '📈',
                        title: 'Progress',
                        value: '${(_completionRate * 100).round()}%',
                        subtitle: 'this week',
                        color: AppTheme.primaryPurple,
                      ),
                    ]),
                  ),
                ),

                // Weekly Calendar
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(AppTheme.spacingM),
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Progress',
                          style: AppTheme.titleLarge,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        _buildWeeklyCalendar(),
                      ],
                    ),
                  ),
                ),

                // Achievements Section
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(AppTheme.spacingM),
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Week\'s Achievements',
                          style: AppTheme.titleLarge,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        _buildAchievementsList(),
                      ],
                    ),
                  ),
                ),

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spacingXXL),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: AppTheme.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: AppTheme.titleSmall.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        final date = weekStart.add(Duration(days: index));
        final isToday = date.day == now.day && date.month == now.month;
        final isCompleted = _completedWorkouts > index; // Simplified logic
        
        return Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted 
                    ? AppTheme.primaryGreen
                    : isToday 
                        ? AppTheme.primaryRed.withOpacity(0.1)
                        : AppTheme.divider,
                border: isToday 
                    ? Border.all(color: AppTheme.primaryRed, width: 2)
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        date.day.toString(),
                        style: AppTheme.bodyMedium.copyWith(
                          color: isToday ? AppTheme.primaryRed : AppTheme.textSecondary,
                          fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              day,
              style: AppTheme.caption.copyWith(
                color: isToday ? AppTheme.primaryRed : AppTheme.textTertiary,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAchievementsList() {
    final achievements = <Map<String, dynamic>>[];
    
    if (_completedWorkouts >= 3) {
      achievements.add({
        'icon': '🎯',
        'title': 'Consistency King',
        'description': 'Completed 3+ workouts this week',
        'color': AppTheme.primaryGreen,
      });
    }
    
    if (_currentStreak >= 5) {
      achievements.add({
        'icon': '🔥',
        'title': 'Streak Master',
        'description': '5+ day workout streak',
        'color': AppTheme.primaryOrange,
      });
    }
    
    if (_completionRate >= 0.8) {
      achievements.add({
        'icon': '⭐',
        'title': 'High Achiever',
        'description': '80%+ weekly completion rate',
        'color': AppTheme.primaryBlue,
      });
    }
    
    if (achievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Keep pushing! Complete more workouts to unlock achievements.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: achievements.map((achievement) => Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              achievement['color'].withOpacity(0.1),
              achievement['color'].withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: achievement['color'].withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              achievement['icon'],
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement['title'],
                    style: AppTheme.titleMedium.copyWith(
                      color: achievement['color'],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    achievement['description'],
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
} 