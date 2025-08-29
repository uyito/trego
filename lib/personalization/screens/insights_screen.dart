import 'package:flutter/material.dart';
import '../personalization_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final PersonalizationService _personalizationService = PersonalizationService();
  
  Map<String, dynamic>? _insights;
  Map<String, dynamic>? _personalizationStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    
    try {
      final futures = await Future.wait([
        _personalizationService.getUserInsights(),
        _personalizationService.getPersonalizationStatus(),
      ]);

      setState(() {
        _insights = futures[0] as Map<String, dynamic>?;
        _personalizationStatus = futures[1] as Map<String, dynamic>?;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load insights')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInsights,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildInsightsContent(),
    );
  }

  Widget _buildInsightsContent() {
    if (_insights == null || _insights!.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPersonalizationStatus(),
          const SizedBox(height: 24),
          _buildWorkoutInsights(),
          const SizedBox(height: 24),
          _buildNutritionInsights(),
          const SizedBox(height: 24),
          _buildProgressInsights(),
          const SizedBox(height: 24),
          _buildRecommendationInsights(),
          const SizedBox(height: 24),
          _buildAITips(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Building Your Insights',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep tracking your workouts and meals to unlock personalized insights powered by AI.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              child: const Text('Track Activity'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizationStatus() {
    if (_personalizationStatus == null) return const SizedBox.shrink();

    final level = _personalizationStatus!['personalizationLevel'] ?? 'low';
    final completeness = _personalizationStatus!['profileCompleteness'] ?? 0.0;
    final dataPoints = _personalizationStatus!['dataPoints'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: _getPersonalizationColor(level),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Personalization Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusMetric(
                    'Level',
                    level.toUpperCase(),
                    _getPersonalizationColor(level),
                  ),
                ),
                Expanded(
                  child: _buildStatusMetric(
                    'Profile',
                    '${(completeness * 100).toInt()}%',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatusMetric(
                    'Data Points',
                    dataPoints.toString(),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completeness,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(_getPersonalizationColor(level)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile completeness affects recommendation quality',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/personalization/settings'),
                  child: const Text('Improve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWorkoutInsights() {
    final workoutData = _insights!['workoutInsights'];
    if (workoutData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Workout Insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightTile(
              'Favorite Workout Type',
              workoutData['favoriteType'] ?? 'Not enough data',
              Icons.favorite,
              Colors.red,
            ),
            _buildInsightTile(
              'Optimal Workout Time',
              workoutData['optimalTime'] ?? 'Not enough data',
              Icons.access_time,
              Colors.orange,
            ),
            _buildInsightTile(
              'Average Workout Duration',
              '${workoutData['averageDuration'] ?? 0} minutes',
              Icons.timer,
              Colors.green,
            ),
            _buildInsightTile(
              'Consistency Score',
              '${workoutData['consistencyScore'] ?? 0}/10',
              Icons.trending_up,
              Colors.purple,
            ),
            if (workoutData['recommendations'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 AI Recommendation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(workoutData['recommendations']),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInsights() {
    final nutritionData = _insights!['nutritionInsights'];
    if (nutritionData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Nutrition Insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightTile(
              'Average Daily Calories',
              '${nutritionData['averageCalories'] ?? 0} cal',
              Icons.local_fire_department,
              Colors.red,
            ),
            _buildInsightTile(
              'Protein Target Achievement',
              '${nutritionData['proteinAchievement'] ?? 0}%',
              Icons.fitness_center,
              Colors.orange,
            ),
            _buildInsightTile(
              'Meal Logging Consistency',
              '${nutritionData['loggingConsistency'] ?? 0}%',
              Icons.edit_note,
              Colors.blue,
            ),
            _buildInsightTile(
              'Hydration Score',
              '${nutritionData['hydrationScore'] ?? 0}/10',
              Icons.water_drop,
              Colors.lightBlue,
            ),
            if (nutritionData['recommendations'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🥗 Nutrition Tip',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(nutritionData['recommendations']),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInsights() {
    final progressData = _insights!['progressInsights'];
    if (progressData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Progress Analysis',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressMetric(
              'Goal Progress',
              progressData['goalProgress'] ?? 0.0,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildProgressMetric(
              'Activity Streak',
              (progressData['activityStreak'] ?? 0) / 30.0, // Normalize to 30 days
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildProgressMetric(
              'Consistency Trend',
              progressData['consistencyTrend'] ?? 0.0,
              Colors.green,
            ),
            if (progressData['predictions'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔮 AI Prediction',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(progressData['predictions']),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressMetric(String label, double value, Color color) {
    final percentage = (value * 100).clamp(0, 100).toInt();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$percentage%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }

  Widget _buildRecommendationInsights() {
    final recData = _insights!['recommendationInsights'];
    if (recData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Recommendation Performance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightTile(
              'Recommendation Accuracy',
              '${recData['accuracy'] ?? 0}%',
              Icons.gps_fixed,
              Colors.green,
            ),
            _buildInsightTile(
              'User Satisfaction',
              '${recData['satisfaction'] ?? 0}/5 stars',
              Icons.star,
              Colors.amber,
            ),
            _buildInsightTile(
              'Recommendations Followed',
              '${recData['followRate'] ?? 0}%',
              Icons.check_circle,
              Colors.blue,
            ),
            _buildInsightTile(
              'Model Confidence',
              '${recData['modelConfidence'] ?? 0}%',
              Icons.psychology,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAITips() {
    final tips = _insights!['aiTips'] as List<String>? ?? [];
    
    if (tips.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'AI Tips for You',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tips.asMap().entries.map((entry) {
              final index = entry.key;
              final tip = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPersonalizationColor(String level) {
    switch (level) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}