import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/ai_coach_service.dart';
import '../personalization_service.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';

/// Category accent colors for recommendation items (fitness/nutrition/
/// recovery/lifestyle/default). No token role exists for these — they're a
/// fixed palette independent of light/dark surface tokens, so they're
/// centralized here as the single source rather than scattered per-use.
class _CategoryAccents {
  static const fitness = Color(0xFF2196F3); // ALLOW-HEX: category accent, no token role
  static const nutrition = Color(0xFF4CAF50); // ALLOW-HEX: category accent, no token role
  static const recovery = Color(0xFF9C27B0); // ALLOW-HEX: category accent, no token role
  static const lifestyle = Color(0xFFFF9800); // ALLOW-HEX: category accent, no token role
  static const fallback = Color(0xFFFFEB3B); // ALLOW-HEX: category accent, no token role
  _CategoryAccents._();
}

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
    final tokens = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: tokens.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: tokens.canvas,
        body: Center(
          child: Text(
            'Please sign in to view recommendations',
            style: context.typo.body,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: Column(
        children: [
          // Header with filters
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Radii.standardCard)),
              boxShadow: [
                BoxShadow(
                  color: tokens.ink.withValues(alpha: 0.1),
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
                      style: context.typo.title.copyWith(color: tokens.ink),
                    ),
                    RotationTransition(
                      turns: _refreshController,
                      child: IconButton(
                        icon: Icon(Icons.refresh, color: tokens.ink),
                        onPressed: _refreshRecommendations,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
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
                    const SizedBox(width: Space.md),
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
            labelColor: tokens.brand,
            unselectedLabelColor: tokens.inkMuted,
            indicatorColor: tokens.brand,
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
                ? Center(child: CircularProgressIndicator(color: tokens.brand))
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
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.typo.body.copyWith(fontWeight: FontWeight.w500, color: tokens.ink)),
        const SizedBox(height: Space.xs),
        DropdownButtonFormField<String>(
          value: value,
          items: options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(option.toUpperCase(), style: context.typo.body.copyWith(color: tokens.ink)),
          )).toList(),
          onChanged: (newValue) {
            onChanged(newValue);
            _loadAllRecommendations();
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.button),
              borderSide: BorderSide(color: tokens.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAICoachTab() {
    if (_aiRecommendations == null && _progressAnalysis == null) {
      final tokens = context.tokens;
      return Center(
        child: Text(
          'No AI recommendations available',
          style: context.typo.body.copyWith(color: tokens.inkMuted),
        ),
      );
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
    final tokens = context.tokens;

    return Card(
      color: tokens.surface,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: tokens.brand),
                const SizedBox(width: Space.sm),
                Text(
                  'Progress Analysis',
                  style: context.typo.titleSmall.copyWith(color: tokens.ink),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            if (analysis['summary'] != null)
              Text(
                analysis['summary'],
                style: context.typo.body.copyWith(color: tokens.ink),
              ),
            const SizedBox(height: Space.md),
            if (analysis['metrics'] != null) ...[
              Text(
                'Key Metrics',
                style: context.typo.body.copyWith(fontWeight: FontWeight.w600, color: tokens.ink),
              ),
              const SizedBox(height: Space.sm),
              ...((analysis['metrics'] as List).map((metric) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tokens.brand,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        '${metric['name']}: ${metric['value']} ${metric['unit'] ?? ''}',
                        style: context.typo.body.copyWith(color: tokens.ink),
                      ),
                    ),
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
    final tokens = context.tokens;

    return Card(
      color: tokens.surface,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: tokens.brand),
                const SizedBox(width: Space.sm),
                Text(
                  'AI Coach Recommendations',
                  style: context.typo.titleSmall.copyWith(color: tokens.ink),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            if (recommendations['recommendations'] != null)
              ...((recommendations['recommendations'] as List).map((rec) => _buildRecommendationItem(rec))),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    final tokens = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: tokens.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getRecommendationIcon(recommendation['category']),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  recommendation['title'] ?? 'Recommendation',
                  style: context.typo.body.copyWith(fontWeight: FontWeight.w600, color: tokens.ink),
                ),
              ),
              if (recommendation['priority'] != null)
                Chip(
                  label: Text(
                    recommendation['priority'],
                    style: context.typo.bodySmall.copyWith(color: tokens.ink),
                  ),
                  backgroundColor: _getPriorityColor(recommendation['priority']),
                ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            recommendation['description'] ?? '',
            style: context.typo.body.copyWith(color: tokens.inkMuted),
          ),
          if (recommendation['action'] != null) ...[
            const SizedBox(height: Space.sm),
            ElevatedButton(
              onPressed: () => _handleRecommendationAction(recommendation),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.brand,
                foregroundColor: tokens.onBrand,
              ),
              child: Text(recommendation['action']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getRecommendationIcon(String? category) {
    switch (category) {
      case 'fitness': return const Icon(Icons.fitness_center, color: _CategoryAccents.fitness);
      case 'nutrition': return const Icon(Icons.restaurant, color: _CategoryAccents.nutrition);
      case 'recovery': return const Icon(Icons.bed, color: _CategoryAccents.recovery);
      case 'lifestyle': return const Icon(Icons.psychology, color: _CategoryAccents.lifestyle);
      default: return const Icon(Icons.lightbulb, color: _CategoryAccents.fallback);
    }
  }

  Color _getPriorityColor(String priority) {
    final tokens = context.tokens;
    switch (priority.toLowerCase()) {
      case 'high': return tokens.danger.withValues(alpha: 0.2);
      case 'medium': return _CategoryAccents.lifestyle.withValues(alpha: 0.2);
      case 'low': return tokens.success.withValues(alpha: 0.2);
      default: return tokens.inkMuted.withValues(alpha: 0.2);
    }
  }

  void _handleRecommendationAction(Map<String, dynamic> recommendation) {
    // Handle recommendation actions (navigate to specific screens, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action: ${recommendation['action']}')),
    );
  }

  Widget _buildWorkoutsTab() {
    final tokens = context.tokens;
    return ListView.builder(
      padding: const EdgeInsets.all(Space.lg),
      itemCount: _workoutRecommendations.length,
      itemBuilder: (context, index) {
        final workout = _workoutRecommendations[index];
        return Card(
          color: tokens.surface,
          margin: const EdgeInsets.only(bottom: Space.md),
          child: ListTile(
            leading: const Icon(Icons.fitness_center, color: _CategoryAccents.fitness),
            title: Text(workout['name'] ?? 'Workout', style: context.typo.body.copyWith(color: tokens.ink)),
            subtitle: Text(
              '${workout['duration'] ?? 0} min • ${workout['difficulty'] ?? 'Medium'}',
              style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: tokens.inkMuted),
            onTap: () => _handleWorkoutTap(workout),
          ),
        );
      },
    );
  }

  Widget _buildNutritionTab() {
    final tokens = context.tokens;
    return ListView.builder(
      padding: const EdgeInsets.all(Space.lg),
      itemCount: _nutritionRecommendations.length,
      itemBuilder: (context, index) {
        final meal = _nutritionRecommendations[index];
        return Card(
          color: tokens.surface,
          margin: const EdgeInsets.only(bottom: Space.md),
          child: ListTile(
            leading: const Icon(Icons.restaurant, color: _CategoryAccents.nutrition),
            title: Text(meal['name'] ?? 'Meal', style: context.typo.body.copyWith(color: tokens.ink)),
            subtitle: Text(
              '${meal['calories'] ?? 0} kcal • ${meal['prepTime'] ?? 0} min',
              style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: tokens.inkMuted),
            onTap: () => _handleMealTap(meal),
          ),
        );
      },
    );
  }

  Widget _buildInsightsTab() {
    final tokens = context.tokens;
    if (_insights == null) {
      return Center(child: Text('No insights available', style: context.typo.body.copyWith(color: tokens.inkMuted)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.lg),
      child: Column(
        children: [
          if (_insights!['summary'] != null) ...[
            Card(
              color: tokens.surface,
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Insights',
                      style: context.typo.titleSmall.copyWith(color: tokens.ink),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(_insights!['summary'], style: context.typo.body.copyWith(color: tokens.ink)),
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