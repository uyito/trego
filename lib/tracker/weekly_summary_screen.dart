import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trego/auth/auth_service.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';

/// Chart accent colors with no equivalent semantic role in [TregoTokens]
/// (calories = amber, water = blue). Kept as named consts per the
/// migration guide's no-role-color rule.
const Color _caloriesAccent = Color(0xFFFF9800); // ALLOW-HEX: calorie chart accent has no token role
const Color _waterAccent = Color(0xFF2196F3); // ALLOW-HEX: water chart accent has no token role

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _userId;
  
  // Weekly data
  int _totalWorkouts = 0;
  double _averageCalories = 0;
  double _averageWater = 0;
  double _totalDistance = 0;
  List<Map<String, dynamic>> _weightData = [];
  List<Map<String, dynamic>> _calorieData = [];
  List<Map<String, dynamic>> _waterData = [];
  List<Map<String, dynamic>> _distanceData = [];

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
      // treat as signed-out, mirroring the guard used elsewhere
      // (e.g. WorkoutPlanScreen, TrackerDashboardScreen).
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
    
    _loadWeeklyData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
      
      // Load data for the last 7 days
      final List<Map<String, dynamic>> weeklyData = [];
      
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('logs')
            .doc(dateString)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          weeklyData.add({
            'date': dateString,
            'dayName': _getDayName(date.weekday),
            'calories': data['calories'] ?? 0,
            'water': data['water'] ?? 0,
            'workoutDone': data['workoutDone'] ?? false,
            'weight': data['weight'],
            'distance': data['distance'] ?? 0,
          });
        } else {
          weeklyData.add({
            'date': dateString,
            'dayName': _getDayName(date.weekday),
            'calories': 0,
            'water': 0,
            'workoutDone': false,
            'weight': null,
            'distance': 0,
          });
        }
      }
      
      // Calculate averages and totals
      double totalCalories = 0;
      double totalWater = 0;
      int totalWorkouts = 0;
      double totalDistance = 0;
      int daysWithData = 0;
      
      for (final day in weeklyData) {
        if (day['calories'] > 0 || day['water'] > 0 || day['workoutDone'] || day['distance'] > 0) {
          daysWithData++;
        }
        totalCalories += (day['calories'] as num).toDouble();
        totalWater += (day['water'] as num).toDouble();
        totalDistance += (day['distance'] as num).toDouble();
        if (day['workoutDone']) totalWorkouts++;
      }
      
      // Prepare chart data
      final weightData = weeklyData
          .where((day) => day['weight'] != null)
          .map((day) => {
                'date': day['dayName'],
                'weight': (day['weight'] as num).toDouble(),
              })
          .toList();
      
      final calorieData = weeklyData
          .map((day) => {
                'date': day['dayName'],
                'calories': (day['calories'] as num).toDouble(),
              })
          .toList();
      
      final waterData = weeklyData
          .map((day) => {
                'date': day['dayName'],
                'water': (day['water'] as num).toDouble(),
              })
          .toList();
      
      final distanceData = weeklyData
          .map((day) => {
                'date': day['dayName'],
                'distance': (day['distance'] as num).toDouble(),
              })
          .toList();
      
      setState(() {
        _totalWorkouts = totalWorkouts;
        _averageCalories = daysWithData > 0 ? totalCalories / daysWithData : 0;
        _averageWater = daysWithData > 0 ? totalWater / daysWithData : 0;
        _totalDistance = totalDistance;
        _weightData = weightData;
        _calorieData = calorieData;
        _waterData = waterData;
        _distanceData = distanceData;
        _isLoading = false;
      });
      
      // Start animations
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      print('Error loading weekly data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        title: Text('Weekly Summary', style: context.typo.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                    margin: const EdgeInsets.all(Space.xl),
                    padding: const EdgeInsets.all(Space.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          tokens.brandContainerStart,
                          tokens.brandContainerEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.brand.withValues(alpha: 0.3),
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
                                  padding: const EdgeInsets.all(Space.md),
                                  decoration: BoxDecoration(
                                    color: tokens.onBrand.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.analytics_rounded,
                                    color: tokens.onBrand,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: Space.lg),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Weekly Summary',
                                        style: context.typo.title.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: tokens.onBrand,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        'Your progress this week',
                                        style: context.typo.body.copyWith(
                                          color: tokens.onBrand.withValues(alpha: 0.9),
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
                                    value: '$_totalWorkouts',
                                    label: 'Workouts',
                                    color: tokens.onBrand,
                                  ),
                                ),
                                const SizedBox(width: Space.xl),
                                Expanded(
                                  child: _buildHeroStat(
                                    icon: '🏃',
                                    value: '${_totalDistance.toStringAsFixed(1)}',
                                    label: 'km Total',
                                    color: tokens.onBrand,
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
                      // Summary Cards
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                icon: Icons.local_fire_department_rounded,
                                title: 'Avg Calories',
                                value: '${_averageCalories.toInt()}',
                                subtitle: 'Per day',
                                color: _caloriesAccent,
                              ),
                            ),
                            const SizedBox(width: Space.md),
                            Expanded(
                              child: _buildSummaryCard(
                                icon: Icons.water_drop_rounded,
                                title: 'Avg Water',
                                value: '${_averageWater.toInt()}',
                                subtitle: 'Cups per day',
                                color: _waterAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.xl),

                      // Charts
                      if (_weightData.isNotEmpty) ...[
                        _buildChartCard(
                          title: 'Weight Progress',
                          subtitle: 'Your weight changes this week',
                          icon: Icons.monitor_weight_rounded,
                          child: _buildWeightLineChart(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      _buildChartCard(
                        title: 'Daily Calories',
                        subtitle: 'Your calorie intake this week',
                        icon: Icons.local_fire_department_rounded,
                        child: _buildCaloriesBarChart(),
                      ),
                      const SizedBox(height: 20),

                      _buildChartCard(
                        title: 'Water Intake',
                        subtitle: 'Your hydration this week',
                        icon: Icons.water_drop_rounded,
                        child: _buildWaterBarChart(),
                      ),
                      const SizedBox(height: 20),

                      _buildChartCard(
                        title: 'Daily Distance',
                        subtitle: 'Your movement this week',
                        icon: Icons.directions_run_rounded,
                        child: _buildDistanceBarChart(),
                      ),
                      const SizedBox(height: 20),

                      _buildChartCard(
                        title: 'Daily Breakdown',
                        subtitle: 'Detailed view of your week',
                        icon: Icons.calendar_today_rounded,
                        child: _buildDailyBreakdown(),
                      ),
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
        const SizedBox(height: Space.sm),
        Text(
          value,
          style: context.typo.statLarge.copyWith(
            color: color,
          ),
        ),
        Text(
          label,
          style: context.typo.bodySmall.copyWith(
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tokens.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Space.md),
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
          const SizedBox(height: Space.md),
          Text(
            value,
            style: context.typo.stat.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            title,
            style: context.typo.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: tokens.ink,
            ),
          ),
          Text(
            subtitle,
            style: context.typo.bodySmall.copyWith(
              color: tokens.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tokens.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: tokens.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: tokens.brand,
                    size: 24,
                  ),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.typo.title.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: context.typo.body.copyWith(
                          color: tokens.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.xl),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildWeightLineChart() {
    final tokens = context.tokens;
    if (_weightData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No weight data available this week',
            style: context.typo.body.copyWith(color: tokens.inkMuted),
          ),
        ),
      );
    }

    // Calculate max and min weights
    final weights = _weightData.map((d) => d['weight'] as double).toList();
    double maxWeight = weights.isNotEmpty ? weights[0] : 0.0;
    double minWeight = weights.isNotEmpty ? weights[0] : 0.0;

    for (final weight in weights) {
      if (weight > maxWeight) maxWeight = weight;
      if (weight < minWeight) minWeight = weight;
    }

    return SizedBox(
      height: 200,
      child: CustomPaint(
        painter: WeightLineChartPainter(
          weightData: _weightData,
          maxWeight: maxWeight,
          minWeight: minWeight,
          lineColor: tokens.brand,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildCaloriesBarChart() {
    final tokens = context.tokens;
    // Calculate max calories
    final calories = _calorieData.map((d) => d['calories'] as double).toList();
    double maxCalories = calories.isNotEmpty ? calories[0] : 0.0;

    for (final calorie in calories) {
      if (calorie > maxCalories) maxCalories = calorie;
    }

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _calorieData.map((data) {
          final calories = data['calories'] as double;
          final height = (maxCalories > 0 ? calories / maxCalories : 0).toDouble();

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _caloriesAccent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  calories.toInt().toString(),
                  style: context.typo.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // fixed contrast text on the decorative calorie-accent badge, not a brand surface
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
              Container(
                width: 25,
                height: 120 * height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _caloriesAccent,
                      _caloriesAccent.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: _caloriesAccent.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                data['date'],
                style: context.typo.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: tokens.inkMuted,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWaterBarChart() {
    final tokens = context.tokens;
    // Calculate max water
    final waters = _waterData.map((d) => d['water'] as double).toList();
    double maxWater = waters.isNotEmpty ? waters[0] : 0.0;

    for (final water in waters) {
      if (water > maxWater) maxWater = water;
    }

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _waterData.map((data) {
          final water = data['water'] as double;
          final height = (maxWater > 0 ? water / maxWater : 0).toDouble();

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _waterAccent.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  water.toInt().toString(),
                  style: context.typo.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // fixed contrast text on the decorative water-accent badge, not a brand surface
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
              Container(
                width: 25,
                height: 120 * height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      _waterAccent,
                      _waterAccent.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: _waterAccent.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                data['date'],
                style: context.typo.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: tokens.inkMuted,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDistanceBarChart() {
    final tokens = context.tokens;
    // Calculate max distance
    final distances = _distanceData.map((d) => d['distance'] as double).toList();
    double maxDistance = distances.isNotEmpty ? distances[0] : 0.0;

    for (final distance in distances) {
      if (distance > maxDistance) maxDistance = distance;
    }

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _distanceData.map((data) {
          final distance = data['distance'] as double;
          final height = (maxDistance > 0 ? distance / maxDistance : 0).toDouble();

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.success.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  distance.toStringAsFixed(1),
                  style: context.typo.label.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: tokens.onSuccess,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(height: Space.sm),
              Container(
                width: 25,
                height: 120 * height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      tokens.success,
                      tokens.success.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: tokens.success.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                data['date'],
                style: context.typo.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: tokens.inkMuted,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailyBreakdown() {
    final tokens = context.tokens;
    final weekData = [
      ..._calorieData.asMap().entries.map((entry) {
        final index = entry.key;
        final calorieData = entry.value;
        final waterData = _waterData[index];
        final distanceData = _distanceData[index];
        final dayName = calorieData['date'];
        final calories = calorieData['calories'] as double;
        final water = waterData['water'] as double;
        final distance = distanceData['distance'] as double;
        final workoutDone = index < 7 && _totalWorkouts > 0; // Simplified logic

        return Container(
          margin: const EdgeInsets.only(bottom: Space.md),
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            color: tokens.surfaceSunken,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      dayName,
                      style: context.typo.titleSmall.copyWith(
                        color: tokens.ink,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: workoutDone ? tokens.success : tokens.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      workoutDone ? Icons.check : Icons.close,
                      color: workoutDone ? tokens.onSuccess : tokens.inkMuted,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildBreakdownItem(
                      icon: Icons.local_fire_department_rounded,
                      value: '${calories.toInt()}',
                      unit: 'cal',
                      color: calories > 0 ? _caloriesAccent : tokens.inkFaint,
                    ),
                  ),
                  Expanded(
                    child: _buildBreakdownItem(
                      icon: Icons.water_drop_rounded,
                      value: '${water.toInt()}',
                      unit: 'cups',
                      color: water > 0 ? _waterAccent : tokens.inkFaint,
                    ),
                  ),
                  Expanded(
                    child: _buildBreakdownItem(
                      icon: Icons.directions_run_rounded,
                      value: distance.toStringAsFixed(1),
                      unit: 'km',
                      color: distance > 0 ? tokens.success : tokens.inkFaint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    ];

    return Column(children: weekData);
  }

  Widget _buildBreakdownItem({
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: Space.xs),
        Text(
          '$value $unit',
          style: context.typo.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Custom painter for weight line chart
class WeightLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> weightData;
  final double maxWeight;
  final double minWeight;
  final Color lineColor;

  WeightLineChartPainter({
    required this.weightData,
    required this.maxWeight,
    required this.minWeight,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weightData.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final width = size.width;
    final height = size.height;
    final padding = 40.0;
    final chartWidth = width - 2 * padding;
    final chartHeight = height - 2 * padding;

    final range = maxWeight - minWeight;
    final stepX = chartWidth / (weightData.length - 1);

    for (int i = 0; i < weightData.length; i++) {
      final data = weightData[i];
      final weight = data['weight'] as double;
      final normalizedWeight = range > 0 ? (weight - minWeight) / range : 0.5;
      
      final x = padding + i * stepX;
      final y = height - padding - normalizedWeight * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete the fill path
    fillPath.lineTo(width - padding, height - padding);
    fillPath.lineTo(padding, height - padding);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw data points
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < weightData.length; i++) {
      final data = weightData[i];
      final weight = data['weight'] as double;
      final normalizedWeight = range > 0 ? (weight - minWeight) / range : 0.5;
      
      final x = padding + i * stepX;
      final y = height - padding - normalizedWeight * chartHeight;

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 