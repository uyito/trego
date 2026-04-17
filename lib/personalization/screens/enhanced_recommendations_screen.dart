import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/ai_coach_service.dart';
import '../personalization_service.dart';

class EnhancedRecommendationsScreen extends StatefulWidget {
  const EnhancedRecommendationsScreen({super.key});

  @override
  State<EnhancedRecommendationsScreen> createState() => _EnhancedRecommendationsScreenState();
}

class _EnhancedRecommendationsScreenState extends State<EnhancedRecommendationsScreen> 
    with TickerProviderStateMixin {
  final AICoachService _aiCoachService = AICoachService();
  final PersonalizationService _personalizationService = PersonalizationService();
  late TabController _tabController;
  late AnimationController _refreshController;
  
  Map<String, dynamic>? _aiRecommendations;
  Map<String, dynamic>? _progressAnalysis;
  List<Map<String, dynamic>> _workoutRecommendations = [];
  List<Map<String, dynamic>> _nutritionRecommendations = [];
  Map<String, dynamic>? _insights;
  
  bool _isLoading = true;
  String _selectedCategory = 'all';
  String _selectedPeriod = 'week';

  final List<String> _categories = ['all', 'fitness', 'nutrition', 'recovery', 'lifestyle'];
  final List<String> _periods = ['week', 'month', 'quarter'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadAllRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRecommendations() async {
    setState(() => _isLoading = true);
    
    try {
      final futures = await Future.wait([
        _aiCoachService.getRecommendations(category: _selectedCategory == 'all' ? null : _selectedCategory),
        _aiCoachService.getProgressAnalysis(period: _selectedPeriod),
        _personalizationService.getPersonalizedWorkouts(count: 5),
        _personalizationService.getMealRecommendations(),
        _personalizationService.getUserInsights(),
      ]);

      setState(() {
        _aiRecommendations = futures[0] as Map<String, dynamic>?;
        _progressAnalysis = futures[1] as Map<String, dynamic>?;
        _workoutRecommendations = futures[2] as List<Map<String, dynamic>>;
        _nutritionRecommendations = futures[3] as List<Map<String, dynamic>>;
        _insights = futures[4] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load recommendations');
    }
  }

  Future<void> _refreshRecommendations() async {
    _refreshController.repeat();
    await _loadAllRecommendations();
    _refreshController.stop();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view recommendations')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header with filters
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Recommendations',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    RotationTransition(
                      turns: _refreshController,
                      child: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _refreshRecommendations,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        'Category',
                        _selectedCategory,
                        _categories,
                        (value) => setState(() => _selectedCategory = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterDropdown(
                        'Period',
                        _selectedPeriod,
                        _periods,
                        (value) => setState(() => _selectedPeriod = value!),
                      ),
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
              Tab(icon: Icon(Icons.auto_awesome), text: 'AI Coach'),
              Tab(icon: Icon(Icons.fitness_center), text: 'Workouts'),
              Tab(icon: Icon(Icons.restaurant), text: 'Nutrition'),
              Tab(icon: Icon(Icons.insights), text: 'Insights'),
            ],
          ),
          
          // Tab Views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAICoachTab(),
                      _buildWorkoutsTab(),
                      _buildNutritionTab(),
                      _buildInsightsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          items: options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(option.toUpperCase()),
          )).toList(),
          onChanged: (newValue) {
            onChanged(newValue);
            _loadAllRecommendations();
          },
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildAICoachTab() {
    if (_aiRecommendations == null && _progressAnalysis == null) {
      return const Center(child: Text('No AI recommendations available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_progressAnalysis != null) ...[
            _buildProgressAnalysisCard(),
            const SizedBox(height: 16),
          ],
          if (_aiRecommendations != null) _buildAIRecommendationsCard(),
        ],
      ),
    );
  }

  Widget _buildProgressAnalysisCard() {
    final analysis = _progressAnalysis!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Progress Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (analysis['summary'] != null)
              Text(
                analysis['summary'],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 12),
            if (analysis['metrics'] != null) ...[
              Text(
                'Key Metrics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...((analysis['metrics'] as List).map((metric) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${metric['name']}: ${metric['value']} ${metric['unit'] ?? ''}')),
                  ],
                ),
              ))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAIRecommendationsCard() {
    final recommendations = _aiRecommendations!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'AI Coach Recommendations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recommendations['recommendations'] != null)
              ...((recommendations['recommendations'] as List).map((rec) => _buildRecommendationItem(rec))),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getRecommendationIcon(recommendation['category']),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation['title'] ?? 'Recommendation',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (recommendation['priority'] != null)
                Chip(
                  label: Text(recommendation['priority']),
                  backgroundColor: _getPriorityColor(recommendation['priority']),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(recommendation['description'] ?? ''),
          if (recommendation['action'] != null) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _handleRecommendationAction(recommendation),
              child: Text(recommendation['action']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getRecommendationIcon(String? category) {
    switch (category) {
      case 'fitness': return const Icon(Icons.fitness_center, color: Colors.blue);
      case 'nutrition': return const Icon(Icons.restaurant, color: Colors.green);
      case 'recovery': return const Icon(Icons.bed, color: Colors.purple);
      case 'lifestyle': return const Icon(Icons.psychology, color: Colors.orange);
      default: return const Icon(Icons.lightbulb, color: Colors.yellow);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red.withValues(alpha: 0.2);
      case 'medium': return Colors.orange.withValues(alpha: 0.2);
      case 'low': return Colors.green.withValues(alpha: 0.2);
      default: return Colors.grey.withValues(alpha: 0.2);
    }
  }

  void _handleRecommendationAction(Map<String, dynamic> recommendation) {
    // Handle recommendation actions (navigate to specific screens, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action: ${recommendation['action']}')),
    );
  }

  Widget _buildWorkoutsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _workoutRecommendations.length,
      itemBuilder: (context, index) {
        final workout = _workoutRecommendations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.fitness_center, color: Colors.blue),
            title: Text(workout['name'] ?? 'Workout'),
            subtitle: Text('${workout['duration'] ?? 0} min • ${workout['difficulty'] ?? 'Medium'}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _handleWorkoutTap(workout),
          ),
        );
      },
    );
  }

  Widget _buildNutritionTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _nutritionRecommendations.length,
      itemBuilder: (context, index) {
        final meal = _nutritionRecommendations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.restaurant, color: Colors.green),
            title: Text(meal['name'] ?? 'Meal'),
            subtitle: Text('${meal['calories'] ?? 0} kcal • ${meal['prepTime'] ?? 0} min'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _handleMealTap(meal),
          ),
        );
      },
    );
  }

  Widget _buildInsightsTab() {
    if (_insights == null) {
      return const Center(child: Text('No insights available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_insights!['summary'] != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Insights',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_insights!['summary']),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleWorkoutTap(Map<String, dynamic> workout) {
    // Navigate to workout details or start workout
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening workout: ${workout['name']}')),
    );
  }

  void _handleMealTap(Map<String, dynamic> meal) {
    // Navigate to meal details or recipe
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening meal: ${meal['name']}')),
    );
  }
}