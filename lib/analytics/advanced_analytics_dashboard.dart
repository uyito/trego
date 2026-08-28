import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';

/// Decorative accent colors for KPI stat-card icons and multi-series charts
/// (workout type distribution, macronutrient bars). These are category
/// accents with no matching semantic token role — centralized here and
/// reused so raw hex isn't scattered per chart/card.
const List<Color> _chartPalette = [
  Color(0xFF2196F3), // ALLOW-HEX: chart palette 0 (blue) — category accent, no token role fits
  Color(0xFFFF9800), // ALLOW-HEX: chart palette 1 (orange) — category accent, no token role fits
  Color(0xFF9C27B0), // ALLOW-HEX: chart palette 2 (purple) — category accent, no token role fits
  Color(0xFFF44336), // ALLOW-HEX: chart palette 3 (red) — category accent, no token role fits
  Color(0xFFFFC107), // ALLOW-HEX: chart palette 4 (amber) — category accent, no token role fits
];

/// Decorative "streak fire" gradient for the current-streak card. A
/// distinct warm hue from the brand palette (fire/streak motif, not a
/// brand surface) — no matching semantic token role.
class _StreakColors {
  static const fireStart = Color(0xFFFFA726); // ALLOW-HEX: streak fire gradient start (orange 400), decorative motif
  static const fireEnd = Color(0xFFE64A19); // ALLOW-HEX: streak fire gradient end (deep orange 600), decorative motif
  _StreakColors._();
}

class AdvancedAnalyticsDashboard extends StatefulWidget {
  const AdvancedAnalyticsDashboard({super.key});

  @override
  State<AdvancedAnalyticsDashboard> createState() => _AdvancedAnalyticsDashboardState();
}

class _AdvancedAnalyticsDashboardState extends State<AdvancedAnalyticsDashboard> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _chartAnimationController;
  
  String _selectedPeriod = 'month';
  bool _isLoading = true;
  
  Map<String, dynamic> _workoutAnalytics = {};
  Map<String, dynamic> _nutritionAnalytics = {};
  Map<String, dynamic> _progressAnalytics = {};
  Map<String, dynamic> _streakAnalytics = {};
  List<Map<String, dynamic>> _weeklyData = [];

  final List<String> _periods = ['week', 'month', 'quarter', 'year'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  /// [FirebaseAuth.instance] throws if Firebase hasn't been initialized in
  /// the current context (e.g. widget test hosts). Treat that the same as
  /// a signed-out user rather than crashing the build.
  User? _safeCurrentUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final user = _safeCurrentUser();
    if (user == null) return;

    try {
      await Future.wait([
        _loadWorkoutAnalytics(user.uid),
        _loadNutritionAnalytics(user.uid),
        _loadProgressAnalytics(user.uid),
        _loadStreakAnalytics(user.uid),
        _loadWeeklyData(user.uid),
      ]);

      _chartAnimationController.forward();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWorkoutAnalytics(String userId) async {
    final DateTime endDate = DateTime.now();
    final DateTime startDate = _getStartDateForPeriod(endDate);

    final workoutQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
        .get();

    final workouts = workoutQuery.docs;
    final totalWorkouts = workouts.length;
    final totalDuration = workouts.fold<int>(0, (sum, doc) {
      final data = doc.data();
      return sum + ((data['duration'] as int?) ?? 0);
    });

    final workoutTypes = <String, int>{};
    for (final doc in workouts) {
      final type = doc.data()['type'] as String? ?? 'Unknown';
      workoutTypes[type] = (workoutTypes[type] ?? 0) + 1;
    }

    setState(() {
      _workoutAnalytics = {
        'totalWorkouts': totalWorkouts,
        'totalDuration': totalDuration,
        'averageDuration': totalWorkouts > 0 ? (totalDuration / totalWorkouts).round() : 0,
        'workoutTypes': workoutTypes,
        'workoutsPerWeek': totalWorkouts / _getWeeksInPeriod(),
      };
    });
  }

  Future<void> _loadNutritionAnalytics(String userId) async {
    // Mock nutrition analytics - replace with actual data
    setState(() {
      _nutritionAnalytics = {
        'averageCalories': 2100,
        'proteinIntake': 120,
        'carbIntake': 250,
        'fatIntake': 80,
        'waterIntake': 2.5,
        'mealsLogged': 42,
        'nutritionScore': 85,
      };
    });
  }

  Future<void> _loadProgressAnalytics(String userId) async {
    // Mock progress analytics - replace with actual data
    setState(() {
      _progressAnalytics = {
        'weightChange': -2.3,
        'strengthGain': 15.5,
        'enduranceImprovement': 22.0,
        'flexibilityGain': 8.5,
        'overallProgress': 78,
      };
    });
  }

  Future<void> _loadStreakAnalytics(String userId) async {
    // Mock streak analytics - replace with actual data
    setState(() {
      _streakAnalytics = {
        'currentStreak': 12,
        'longestStreak': 28,
        'weeklyGoal': 5,
        'weeklyCompleted': 4,
        'streakPercentage': 85.7,
      };
    });
  }

  Future<void> _loadWeeklyData(String userId) async {
    // Generate mock weekly data - replace with actual data
    final weeks = <Map<String, dynamic>>[];
    for (int i = 7; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i * 7));
      weeks.add({
        'week': 'Week ${8 - i}',
        'workouts': math.Random().nextInt(8) + 2,
        'duration': math.Random().nextInt(300) + 100,
        'calories': math.Random().nextInt(1000) + 1500,
        'date': date,
      });
    }
    
    setState(() {
      _weeklyData = weeks;
    });
  }

  DateTime _getStartDateForPeriod(DateTime endDate) {
    switch (_selectedPeriod) {
      case 'week': return endDate.subtract(const Duration(days: 7));
      case 'month': return endDate.subtract(const Duration(days: 30));
      case 'quarter': return endDate.subtract(const Duration(days: 90));
      case 'year': return endDate.subtract(const Duration(days: 365));
      default: return endDate.subtract(const Duration(days: 30));
    }
  }

  double _getWeeksInPeriod() {
    switch (_selectedPeriod) {
      case 'week': return 1;
      case 'month': return 4.3;
      case 'quarter': return 13;
      case 'year': return 52;
      default: return 4.3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final user = _safeCurrentUser();

    if (user == null) {
      return Scaffold(
        backgroundColor: tokens.canvas,
        body: Center(
          child: Text(
            'Please sign in to view analytics',
            style: context.typo.body,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: Column(
        children: [
          // Header with period selector
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Radii.standardCard)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Analytics Dashboard',
                      style: context.typo.title,
                    ),
                    DropdownButton<String>(
                      value: _selectedPeriod,
                      dropdownColor: tokens.surface,
                      style: context.typo.body,
                      items: _periods.map((period) => DropdownMenuItem(
                        value: period,
                        child: Text(period.toUpperCase()),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPeriod = value!);
                        _loadAnalytics();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: tokens.brand,
            unselectedLabelColor: tokens.inkMuted,
            indicatorColor: tokens.brand,
            tabs: const [
              Tab(icon: Icon(Icons.fitness_center), text: 'Workouts'),
              Tab(icon: Icon(Icons.restaurant), text: 'Nutrition'),
              Tab(icon: Icon(Icons.trending_up), text: 'Progress'),
              Tab(icon: Icon(Icons.local_fire_department), text: 'Streaks'),
            ],
          ),

          // Tab Views
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: tokens.brand))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildWorkoutAnalyticsTab(),
                      _buildNutritionAnalyticsTab(),
                      _buildProgressAnalyticsTab(),
                      _buildStreakAnalyticsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Workouts', '${_workoutAnalytics['totalWorkouts'] ?? 0}', Icons.fitness_center, _chartPalette[0])),
              const SizedBox(width: Space.md),
              Expanded(child: _buildStatCard('Total Duration', '${_workoutAnalytics['totalDuration'] ?? 0}m', Icons.timer, context.tokens.success)),
            ],
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(child: _buildStatCard('Avg Duration', '${_workoutAnalytics['averageDuration'] ?? 0}m', Icons.analytics, _chartPalette[1])),
              const SizedBox(width: Space.md),
              Expanded(child: _buildStatCard('Per Week', '${(_workoutAnalytics['workoutsPerWeek'] ?? 0).toStringAsFixed(1)}', Icons.calendar_today, _chartPalette[2])),
            ],
          ),
          
          const SizedBox(height: Space.xl),
          
          // Workout Types Chart
          _buildWorkoutTypesChart(),
          
          const SizedBox(height: Space.xl),
          
          // Weekly Trend
          _buildWeeklyTrendChart(),
        ],
      ),
    );
  }

  Widget _buildNutritionAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        children: [
          // Nutrition Summary
          Row(
            children: [
              Expanded(child: _buildStatCard('Avg Calories', '${_nutritionAnalytics['averageCalories']}', Icons.local_fire_department, _chartPalette[3])),
              const SizedBox(width: Space.md),
              Expanded(child: _buildStatCard('Nutrition Score', '${_nutritionAnalytics['nutritionScore']}%', Icons.star, _chartPalette[4])),
            ],
          ),
          
          const SizedBox(height: Space.xl),
          
          // Macronutrients Breakdown
          _buildMacronutrientsChart(),
          
          const SizedBox(height: Space.xl),
          
          // Hydration Tracking
          _buildHydrationCard(),
        ],
      ),
    );
  }

  Widget _buildProgressAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        children: [
          // Progress Overview
          _buildProgressOverviewCard(),
          
          const SizedBox(height: Space.xl),
          
          // Progress Metrics
          _buildProgressMetricsCards(),
          
          const SizedBox(height: Space.xl),
          
          // Progress Chart
          _buildProgressChart(),
        ],
      ),
    );
  }

  Widget _buildStreakAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        children: [
          // Current Streak
          _buildCurrentStreakCard(),
          
          const SizedBox(height: Space.xl),
          
          // Streak Statistics
          Row(
            children: [
              Expanded(child: _buildStatCard('Current', '${_streakAnalytics['currentStreak']} days', Icons.local_fire_department, _chartPalette[1])),
              const SizedBox(width: Space.md),
              Expanded(child: _buildStatCard('Longest', '${_streakAnalytics['longestStreak']} days', Icons.emoji_events, _chartPalette[4])),
            ],
          ),
          
          const SizedBox(height: Space.xl),
          
          // Weekly Goal Progress
          _buildWeeklyGoalCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final tokens = context.tokens;
    return AnimatedBuilder(
      animation: _chartAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimationController.value,
          child: Card(
            color: tokens.surface,
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                children: [
                  Icon(icon, size: 32, color: color),
                  const SizedBox(height: Space.sm),
                  Text(
                    value,
                    style: context.typo.title,
                  ),
                  Text(
                    title,
                    style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutTypesChart() {
    final tokens = context.tokens;
    final workoutTypes = _workoutAnalytics['workoutTypes'] as Map<String, int>? ?? {};

    return Card(
      color: tokens.surface,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Types Distribution',
              style: context.typo.title,
            ),
            const SizedBox(height: Space.lg),
            ...workoutTypes.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key, style: context.typo.body),
                  ),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: entry.value / (workoutTypes.values.isNotEmpty ? workoutTypes.values.reduce(math.max) : 1),
                      backgroundColor: tokens.border,
                      valueColor: AlwaysStoppedAnimation<Color>(tokens.brand),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Text('${entry.value}', style: context.typo.body),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart() {
    final tokens = context.tokens;
    return Card(
      color: tokens.surface,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Trend',
              style: context.typo.title,
            ),
            const SizedBox(height: Space.lg),
            SizedBox(
              height: 200,
              child: _buildSimpleLineChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleLineChart() {
    // Primary (and only) series on this chart → brand token.
    return AnimatedBuilder(
      animation: _chartAnimationController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 200),
          painter: SimpleLineChartPainter(
            data: _weeklyData,
            animationValue: _chartAnimationController.value,
            color: context.tokens.brand,
          ),
        );
      },
    );
  }

  Widget _buildMacronutrientsChart() {
    final tokens = context.tokens;
    return Card(
      color: tokens.surface,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Macronutrients Breakdown',
              style: context.typo.title,
            ),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(child: _buildMacroBar('Protein', _nutritionAnalytics['proteinIntake'] ?? 0, 150, _chartPalette[3])),
                const SizedBox(width: Space.sm),
                Expanded(child: _buildMacroBar('Carbs', _nutritionAnalytics['carbIntake'] ?? 0, 300, _chartPalette[0])),
                const SizedBox(width: Space.sm),
                Expanded(child: _buildMacroBar('Fat', _nutritionAnalytics['fatIntake'] ?? 0, 100, _chartPalette[1])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBar(String label, int current, int target, Color color) {
    final tokens = context.tokens;
    final percentage = current / target;

    return Column(
      children: [
        Text(label, style: context.typo.body.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: Space.sm),
        Container(
          height: 100,
          width: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: tokens.border,
          ),
          child: AnimatedBuilder(
            animation: _chartAnimationController,
            builder: (context, child) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 100 * percentage * _chartAnimationController.value,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: color,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: Space.sm),
        Text('${current}g', style: context.typo.bodySmall),
        Text('/${target}g', style: context.typo.label.copyWith(color: tokens.inkMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildHydrationCard() {
    final tokens = context.tokens;
    return Card(
      color: tokens.surface,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hydration Tracking',
              style: context.typo.title,
            ),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Icon(Icons.water_drop, size: 48, color: _chartPalette[0]),
                const SizedBox(width: Space.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_nutritionAnalytics['waterIntake']} L', style: context.typo.title),
                    Text('Daily average', style: context.typo.body.copyWith(color: tokens.inkMuted)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverviewCard() {
    final tokens = context.tokens;
    return Card(
      color: tokens.surface,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress',
              style: context.typo.title,
            ),
            const SizedBox(height: Space.lg),
            Center(
              child: AnimatedBuilder(
                animation: _chartAnimationController,
                builder: (context, child) {
                  return SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: (_progressAnalytics['overallProgress'] ?? 0) / 100 * _chartAnimationController.value,
                      strokeWidth: 12,
                      backgroundColor: tokens.border,
                      valueColor: AlwaysStoppedAnimation<Color>(tokens.brand),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: Space.lg),
            Center(
              child: Text(
                '${_progressAnalytics['overallProgress']}%',
                style: context.typo.title,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressMetricsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildProgressMetricCard('Weight Change', '${_progressAnalytics['weightChange']}kg', Icons.monitor_weight, context.tokens.success)),
            const SizedBox(width: Space.md),
            Expanded(child: _buildProgressMetricCard('Strength Gain', '+${_progressAnalytics['strengthGain']}%', Icons.fitness_center, _chartPalette[3])),
          ],
        ),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Expanded(child: _buildProgressMetricCard('Endurance', '+${_progressAnalytics['enduranceImprovement']}%', Icons.directions_run, _chartPalette[0])),
            const SizedBox(width: Space.md),
            Expanded(child: _buildProgressMetricCard('Flexibility', '+${_progressAnalytics['flexibilityGain']}%', Icons.self_improvement, _chartPalette[2])),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressMetricCard(String title, String value, IconData icon, Color color) {
    final tokens = context.tokens;
    return Card(
      color: tokens.surface,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: Space.sm),
            Text(value, style: context.typo.titleSmall),
            Text(title, style: context.typo.bodySmall.copyWith(color: tokens.inkMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    final tokens = context.tokens;
    return Card(
      color: tokens.surface,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Over Time',
              style: context.typo.title,
            ),
            const SizedBox(height: Space.lg),
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Progress chart coming soon',
                  style: context.typo.body.copyWith(color: tokens.inkMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStreakCard() {
    final tokens = context.tokens;
    return Card(
      color: tokens.surface,
      child: Container(
        padding: const EdgeInsets.all(Space.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.statTile),
          // Decorative "streak fire" gradient — see _StreakColors above.
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_StreakColors.fireStart, _StreakColors.fireEnd],
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.local_fire_department, size: 64, color: tokens.onBrand),
            const SizedBox(height: Space.lg),
            Text(
              '${_streakAnalytics['currentStreak']} Days',
              style: context.typo.title.copyWith(fontSize: 32, color: tokens.onBrand),
            ),
            Text(
              'Current Streak',
              style: context.typo.body.copyWith(color: tokens.onBrand.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGoalCard() {
    final tokens = context.tokens;
    final completed = _streakAnalytics['weeklyCompleted'] ?? 0;
    final goal = _streakAnalytics['weeklyGoal'] ?? 5;
    final percentage = completed / goal;

    return Card(
      color: tokens.surface,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Goal Progress',
              style: context.typo.title,
            ),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _chartAnimationController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: percentage * _chartAnimationController.value,
                        backgroundColor: tokens.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 1.0 ? tokens.success : tokens.brand,
                        ),
                        minHeight: 8,
                      );
                    },
                  ),
                ),
                const SizedBox(width: Space.lg),
                Text('$completed / $goal', style: context.typo.body),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              '${(percentage * 100).round()}% completed',
              style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double animationValue;
  final Color color;

  SimpleLineChartPainter({
    required this.data,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxValue = data.map((d) => d['workouts'] as int).reduce(math.max).toDouble();
    
    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final y = size.height - ((data[i]['workouts'] as int) / maxValue) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final animatedX = x * animationValue;
        path.lineTo(animatedX, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}