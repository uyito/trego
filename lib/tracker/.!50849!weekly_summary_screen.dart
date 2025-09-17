import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trego/auth/auth_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Weekly Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.analytics_rounded,
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
                                        'Weekly Summary',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        'Your progress this week',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.9),
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
