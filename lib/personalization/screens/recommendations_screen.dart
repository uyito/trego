import 'package:flutter/material.dart';
import '../personalization_service.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> with SingleTickerProviderStateMixin {
  final PersonalizationService _personalizationService = PersonalizationService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _workoutRecommendations = [];
  Map<String, dynamic>? _nutritionRecommendations;
  List<Map<String, dynamic>> _mealRecommendations = [];
  Map<String, dynamic>? _insights;
  Map<String, dynamic>? _personalizationStatus;
  
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all recommendation data in parallel
      final futures = await Future.wait([
        _personalizationService.getPersonalizedWorkouts(count: 10, refreshProfile: false),
        _personalizationService.getNutritionRecommendations(),
        _personalizationService.getMealRecommendations(),
        _personalizationService.getUserInsights(),
        _personalizationService.getPersonalizationStatus(),
      ]);

      setState(() {
        _workoutRecommendations = futures[0] as List<Map<String, dynamic>>;
        _nutritionRecommendations = futures[1] as Map<String, dynamic>?;
        _mealRecommendations = futures[2] as List<Map<String, dynamic>>;
        _insights = futures[3] as Map<String, dynamic>?;
        _personalizationStatus = futures[4] as Map<String, dynamic>?;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load recommendations')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshRecommendations() async {
    setState(() => _isRefreshing = true);
    
    try {
      // Refresh with updated profile
      final workouts = await _personalizationService.getPersonalizedWorkouts(
        count: 10, 
        refreshProfile: true,
      );
      
      setState(() => _workoutRecommendations = workouts);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to refresh recommendations')),
        );
      }
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('For You'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshRecommendations,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/personalization/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Workouts', icon: Icon(Icons.fitness_center)),
            Tab(text: 'Nutrition', icon: Icon(Icons.restaurant)),
            Tab(text: 'Insights', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildWorkoutsTab(),
              _buildNutritionTab(),
              _buildInsightsTab(),
            ],
          ),
    );
  }

  Widget _buildWorkoutsTab() {
    if (_workoutRecommendations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.fitness_center_outlined,
        title: 'No workout recommendations yet',
        subtitle: 'Complete a few workouts to get personalized suggestions',
        actionText: 'Start Workout',
        onAction: () => Navigator.pushNamed(context, '/workouts'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshRecommendations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _workoutRecommendations.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildPersonalizationHeader();
          }
          return _buildWorkoutCard(_workoutRecommendations[index - 1]);
        },
      ),
    );
  }

  Widget _buildNutritionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPersonalizationHeader(),
          const SizedBox(height: 16),
          if (_nutritionRecommendations != null) ...[
            _buildNutritionOverview(),
            const SizedBox(height: 24),
          ],
          Text(
            'Meal Suggestions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (_mealRecommendations.isEmpty)
            _buildEmptyMeals()
          else
            ..._mealRecommendations.map(_buildMealCard),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    if (_insights == null || _insights!.isEmpty) {
      return _buildEmptyState(
        icon: Icons.analytics_outlined,
        title: 'Building your insights',
        subtitle: 'Track workouts and meals to see personalized insights',
        actionText: 'View Dashboard',
        onAction: () => Navigator.pushNamed(context, '/dashboard'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPersonalizationHeader(),
          const SizedBox(height: 16),
          _buildInsightsCards(),
        ],
      ),
    );
  }

  Widget _buildPersonalizationHeader() {
    final status = _personalizationStatus;
    if (status == null) return const SizedBox.shrink();

    final level = status['personalizationLevel'] ?? 'low';
    final completeness = status['profileCompleteness'] ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  level == 'high' ? Icons.auto_awesome : Icons.tune,
                  color: _getPersonalizationColor(level),
                ),
                const SizedBox(width: 8),
                Text(
                  'Personalization: ${level.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getPersonalizationColor(level),
                  ),
                ),
                const Spacer(),
                if (_isRefreshing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: completeness,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(_getPersonalizationColor(level)),
            ),
            const SizedBox(height: 8),
            Text(
              'Profile ${(completeness * 100).toInt()}% complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (completeness < 1.0) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/personalization/settings'),
                child: const Text('Improve Recommendations'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final score = (workout['score'] ?? 0.0) * 100;
    final confidence = (workout['confidence'] ?? 0.0) * 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _getDifficultyColor(workout['difficulty']),
              child: const Icon(Icons.fitness_center, color: Colors.white),
            ),
            title: Text(
              workout['name'] ?? 'Personalized Workout',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${workout['duration']} min • ${workout['difficulty']}'),
                if (workout['reasoning'] != null)
                  Text(
                    workout['reasoning'],
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${score.toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'match',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${confidence.toInt()}% confidence',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _previewWorkout(workout),
                    child: const Text('Preview'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startWorkout(workout),
                    child: const Text('Start'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionOverview() {
    final nutrition = _nutritionRecommendations!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Targets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildNutritionStat('Calories', '${nutrition['calories']}', Colors.orange)),
                Expanded(child: _buildNutritionStat('Protein', '${nutrition['protein']}g', Colors.red)),
                Expanded(child: _buildNutritionStat('Carbs', '${nutrition['carbs']}g', Colors.blue)),
                Expanded(child: _buildNutritionStat('Fat', '${nutrition['fat']}g', Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
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
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMealTypeColor(meal['type']),
          child: Icon(_getMealTypeIcon(meal['type']), color: Colors.white),
        ),
        title: Text(meal['name'] ?? 'Recommended Meal'),
        subtitle: Text('${meal['calories']} cal • ${meal['type']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _previewMeal(meal),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addMealToPlan(meal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCards() {
    final insights = _insights!;
    
    return Column(
      children: [
        if (insights['workoutPatterns'] != null)
          _buildInsightCard(
            'Workout Patterns',
            insights['workoutPatterns'],
            Icons.fitness_center,
            Colors.blue,
          ),
        const SizedBox(height: 16),
        if (insights['nutritionTrends'] != null)
          _buildInsightCard(
            'Nutrition Trends',
            insights['nutritionTrends'],
            Icons.restaurant,
            Colors.green,
          ),
        const SizedBox(height: 16),
        if (insights['recommendations'] != null)
          _buildInsightCard(
            'AI Suggestions',
            insights['recommendations'],
            Icons.auto_awesome,
            Colors.purple,
          ),
      ],
    );
  }

  Widget _buildInsightCard(String title, Map<String, dynamic> data, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMeals() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.restaurant_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No meal suggestions yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text('Log some meals to get personalized suggestions'),
          ],
        ),
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

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getMealTypeColor(String? type) {
    switch (type) {
      case 'breakfast':
        return Colors.yellow;
      case 'lunch':
        return Colors.orange;
      case 'dinner':
        return Colors.red;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getMealTypeIcon(String? type) {
    switch (type) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  void _previewWorkout(Map<String, dynamic> workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workout['name'] ?? 'Workout Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${workout['duration']} minutes'),
            Text('Difficulty: ${workout['difficulty']}'),
            if (workout['exercises'] != null) ...[
              const SizedBox(height: 8),
              const Text('Exercises:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...((workout['exercises'] as List).take(3).map(
                (exercise) => Text('• ${exercise['name']}'),
              )),
              if ((workout['exercises'] as List).length > 3)
                Text('• +${(workout['exercises'] as List).length - 3} more exercises'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startWorkout(workout);
            },
            child: const Text('Start Workout'),
          ),
        ],
      ),
    );
  }

  void _startWorkout(Map<String, dynamic> workout) {
    // Provide feedback to improve recommendations
    _personalizationService.provideFeedback(
      recommendationId: workout['id'] ?? '',
      feedback: 'started',
    );

    Navigator.pushNamed(
      context,
      '/workout/active',
      arguments: workout,
    );
  }

  void _previewMeal(Map<String, dynamic> meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meal['name'] ?? 'Meal Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${meal['type']}'),
            Text('Calories: ${meal['calories']}'),
            if (meal['ingredients'] != null) ...[
              const SizedBox(height: 8),
              const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...((meal['ingredients'] as List).take(3).map(
                (ingredient) => Text('• $ingredient'),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addMealToPlan(meal);
            },
            child: const Text('Add to Plan'),
          ),
        ],
      ),
    );
  }

  void _addMealToPlan(Map<String, dynamic> meal) {
    // Provide feedback to improve recommendations
    _personalizationService.provideFeedback(
      recommendationId: meal['id'] ?? '',
      feedback: 'added_to_plan',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${meal['name']} added to meal plan')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}