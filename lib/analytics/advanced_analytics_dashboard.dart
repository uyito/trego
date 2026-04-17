import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

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

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
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
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view analytics')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header with period selector
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedPeriod,
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
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
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
                ? const Center(child: CircularProgressIndicator())
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Workouts', '${_workoutAnalytics['totalWorkouts'] ?? 0}', Icons.fitness_center, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Total Duration', '${_workoutAnalytics['totalDuration'] ?? 0}m', Icons.timer, Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Avg Duration', '${_workoutAnalytics['averageDuration'] ?? 0}m', Icons.analytics, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Per Week', '${(_workoutAnalytics['workoutsPerWeek'] ?? 0).toStringAsFixed(1)}', Icons.calendar_today, Colors.purple)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Workout Types Chart
          _buildWorkoutTypesChart(),
          
          const SizedBox(height: 24),
          
          // Weekly Trend
          _buildWeeklyTrendChart(),
        ],
      ),
    );
  }

  Widget _buildNutritionAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Nutrition Summary
          Row(
            children: [
              Expanded(child: _buildStatCard('Avg Calories', '${_nutritionAnalytics['averageCalories']}', Icons.local_fire_department, Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Nutrition Score', '${_nutritionAnalytics['nutritionScore']}%', Icons.star, Colors.amber)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Macronutrients Breakdown
          _buildMacronutrientsChart(),
          
          const SizedBox(height: 24),
          
          // Hydration Tracking
          _buildHydrationCard(),
        ],
      ),
    );
  }

  Widget _buildProgressAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Progress Overview
          _buildProgressOverviewCard(),
          
          const SizedBox(height: 24),
          
          // Progress Metrics
          _buildProgressMetricsCards(),
          
          const SizedBox(height: 24),
          
          // Progress Chart
          _buildProgressChart(),
        ],
      ),
    );
  }

  Widget _buildStreakAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Current Streak
          _buildCurrentStreakCard(),
          
          const SizedBox(height: 24),
          
          // Streak Statistics
          Row(
            children: [
              Expanded(child: _buildStatCard('Current', '${_streakAnalytics['currentStreak']} days', Icons.local_fire_department, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Longest', '${_streakAnalytics['longestStreak']} days', Icons.emoji_events, Colors.amber)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Weekly Goal Progress
          _buildWeeklyGoalCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _chartAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimationController.value,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(icon, size: 32, color: color),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
    final workoutTypes = _workoutAnalytics['workoutTypes'] as Map<String, int>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Types Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...workoutTypes.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(entry.key),
                  ),
                  Expanded(
                    flex: 3,
                    child: LinearProgressIndicator(
                      value: entry.value / (workoutTypes.values.isNotEmpty ? workoutTypes.values.reduce(math.max) : 1),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${entry.value}'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
    return AnimatedBuilder(
      animation: _chartAnimationController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 200),
          painter: SimpleLineChartPainter(
            data: _weeklyData,
            animationValue: _chartAnimationController.value,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  Widget _buildMacronutrientsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Macronutrients Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMacroBar('Protein', _nutritionAnalytics['proteinIntake'] ?? 0, 150, Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _buildMacroBar('Carbs', _nutritionAnalytics['carbIntake'] ?? 0, 300, Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildMacroBar('Fat', _nutritionAnalytics['fatIntake'] ?? 0, 100, Colors.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBar(String label, int current, int target, Color color) {
    final percentage = current / target;
    
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          height: 100,
          width: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[300],
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
        const SizedBox(height: 8),
        Text('${current}g', style: const TextStyle(fontSize: 12)),
        Text('/${target}g', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHydrationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hydration Tracking',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.water_drop, size: 48, color: Colors.blue[300]),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_nutritionAnalytics['waterIntake']} L', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('Daily average', style: TextStyle(color: Colors.grey[600])),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${_progressAnalytics['overallProgress']}%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            Expanded(child: _buildProgressMetricCard('Weight Change', '${_progressAnalytics['weightChange']}kg', Icons.monitor_weight, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildProgressMetricCard('Strength Gain', '+${_progressAnalytics['strengthGain']}%', Icons.fitness_center, Colors.red)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildProgressMetricCard('Endurance', '+${_progressAnalytics['enduranceImprovement']}%', Icons.directions_run, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildProgressMetricCard('Flexibility', '+${_progressAnalytics['flexibilityGain']}%', Icons.self_improvement, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Over Time',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              height: 200,
              child: Center(child: Text('Progress chart coming soon')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStreakCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange[400]!, Colors.deepOrange[600]!],
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.local_fire_department, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              '${_streakAnalytics['currentStreak']} Days',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'Current Streak',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGoalCard() {
    final completed = _streakAnalytics['weeklyCompleted'] ?? 0;
    final goal = _streakAnalytics['weeklyGoal'] ?? 5;
    final percentage = completed / goal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Goal Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _chartAnimationController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: percentage * _chartAnimationController.value,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 8,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Text('$completed / $goal'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(percentage * 100).round()}% completed',
              style: TextStyle(color: Colors.grey[600]),
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