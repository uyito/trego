import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../shared/app_theme.dart';
import 'nike_components.dart';

class NikeDashboard extends StatefulWidget {
  final String userName;
  final Map<String, dynamic> todayStats;
  final List<Map<String, dynamic>> recentActivities;
  final Map<String, dynamic> weeklyProgress;
  final List<Map<String, dynamic>> achievements;

  const NikeDashboard({
    super.key,
    required this.userName,
    required this.todayStats,
    required this.recentActivities,
    required this.weeklyProgress,
    required this.achievements,
  });

  @override
  State<NikeDashboard> createState() => _NikeDashboardState();
}

class _NikeDashboardState extends State<NikeDashboard>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildQuickStats(),
              const SizedBox(height: 32),
              _buildWeeklyProgress(),
              const SizedBox(height: 32),
              _buildRecentActivities(),
              const SizedBox(height: 32),
              _buildAchievements(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.userName,
                      style: AppTheme.headlineLarge.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRed.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: AppTheme.primaryWhite,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryRed,
                  AppTheme.nikeOrange,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: AppTheme.primaryWhite,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keep the momentum going!',
                        style: TextStyle(
                          color: AppTheme.primaryWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You\'re ${(widget.todayStats['progress'] * 100).toInt()}% towards your daily goal',
                        style: TextStyle(
                          color: AppTheme.primaryWhite.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _currentPage = page),
        itemCount: 2,
        itemBuilder: (context, pageIndex) {
          if (pageIndex == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: NikeMetricCard(
                      title: 'Steps',
                      value: widget.todayStats['steps'].toString(),
                      unit: '',
                      subtitle: 'Goal: ${widget.todayStats['stepsGoal']}',
                      color: AppTheme.primaryRed,
                      icon: Icons.directions_walk,
                      progress: widget.todayStats['steps'] / widget.todayStats['stepsGoal'],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NikeMetricCard(
                      title: 'Calories',
                      value: widget.todayStats['calories'].toString(),
                      unit: 'kcal',
                      subtitle: 'Burned today',
                      color: AppTheme.nikeOrange,
                      icon: Icons.local_fire_department,
                      progress: widget.todayStats['calories'] / 2000,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: NikeMetricCard(
                      title: 'Distance',
                      value: widget.todayStats['distance'].toStringAsFixed(1),
                      unit: 'km',
                      subtitle: 'Total distance',
                      color: AppTheme.primaryGreen,
                      icon: Icons.place,
                      progress: widget.todayStats['distance'] / 10,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: NikeMetricCard(
                      title: 'Active',
                      value: widget.todayStats['activeMinutes'].toString(),
                      unit: 'min',
                      subtitle: 'Active time',
                      color: AppTheme.primaryBlue,
                      icon: Icons.timer,
                      progress: widget.todayStats['activeMinutes'] / 60,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'THIS WEEK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textTertiary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NikeWeeklySummary(
            weeklyData: List<double>.from(widget.weeklyProgress['steps']),
            color: AppTheme.primaryRed,
            title: 'Steps',
            totalValue: widget.weeklyProgress['totalSteps'].toString(),
            unit: '',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text(
                'RECENT ACTIVITIES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textTertiary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.recentActivities.length,
            itemBuilder: (context, index) {
              final activity = widget.recentActivities[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 300,
                  child: NikeActivityCard(
                    title: activity['type'],
                    subtitle: activity['title'],
                    duration: activity['duration'],
                    distance: activity['distance'],
                    pace: activity['pace'],
                    color: _getActivityColor(activity['type']),
                    backgroundImage: activity['image'] ?? '',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ACHIEVEMENTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textTertiary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: math.min(4, widget.achievements.length),
            itemBuilder: (context, index) {
              final achievement = widget.achievements[index];
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
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return AppTheme.runningPurple;
      case 'walking':
        return AppTheme.primaryGreen;
      case 'cycling':
        return AppTheme.primaryBlue;
      case 'workout':
        return AppTheme.workoutYellow;
      default:
        return AppTheme.primaryRed;
    }
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Nike Progress Ring Widget
class NikeProgressRing extends StatefulWidget {
  final double progress;
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const NikeProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 120,
    this.strokeWidth = 8,
    this.child,
  });

  @override
  State<NikeProgressRing> createState() => _NikeProgressRingState();
}

class _NikeProgressRingState extends State<NikeProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: NikeProgressRingPainter(
                  progress: widget.progress * _animation.value,
                  color: widget.color,
                ),
              );
            },
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Nike Floating Action Button
class NikeFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;

  const NikeFloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  @override
  State<NikeFloatingActionButton> createState() => _NikeFloatingActionButtonState();
}

class _NikeFloatingActionButtonState extends State<NikeFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryRed,
                      AppTheme.nikeOrange,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRed.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: AppTheme.primaryWhite,
                  size: 28,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}