import 'package:flutter/material.dart';
import 'dart:async';
import 'package:trego/recipes/recipe_service.dart';
import 'package:trego/auth/auth_service.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/trego_button.dart';
import '../widgets/core/trego_scaffold.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  // UI State
  String _selectedCategory = 'Dinner';
  bool _showDetail = false;
  int _portion = 2;
  bool _isFavorite = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _aiRecipe;
  // Lazily constructed: these touch Firebase/network on first access, which
  // must not happen synchronously during State construction (it would crash
  // build() before a frame is ever produced, including in test hosts where
  // Firebase isn't initialized).
  late final RecipeService _recipeService = RecipeService();
  late final AuthService _authService = AuthService();
  String _userFirstName = 'User';

  // Mock Data
  final Map<String, dynamic> _suggestedRecipe = {
    'title': 'Creamy Mushroom Pasta',
    'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=80',
    'time': '30 mins',
    'calories': '350 kcal',
    'weight': '1.5 kg',
    'description': 'A rich and creamy mushroom pasta dish featuring sautéed mushrooms, garlic, Parmesan, and a velvety cream sauce, perfect for a comforting meal.',
    'ingredients': [
      {'icon': Icons.ramen_dining, 'name': 'Pasta', 'amount': '90g (1 slice)'},
      {'icon': Icons.egg, 'name': 'Onion', 'amount': '100g (1 slice)'},
      {'icon': Icons.grass, 'name': 'Mushroom', 'amount': '90g (10 slice)'},
      {'icon': Icons.spa, 'name': 'Garlic', 'amount': '90g (10 slice)'},
      {'icon': Icons.icecream, 'name': 'Curd', 'amount': '90g (10 slice)'},
      {'icon': Icons.oil_barrel, 'name': 'Olive oil', 'amount': '2 tbsp'},
    ],
  };

  final List<String> _categories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];

  final TextEditingController _searchController = TextEditingController();

  // Mock AI Recipes
  final List<Map<String, dynamic>> _aiRecipes = [
    {
      'title': 'Spicy Grilled Chicken with Avocado Salsa',
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      'time': '20min',
      'calories': '350 kcal',
      'items': '2 items',
    },
    {
      'title': 'Almond Butter Banana Toast',
      'image': 'https://images.unsplash.com/photo-1484723091739-30a097e8f929?auto=format&fit=crop&w=800&q=80',
      'time': '30min',
      'calories': '450 kcal',
      'items': '3 items',
    },
    {
      'title': 'Quinoa Buddha Bowl',
      'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80',
      'time': '25min',
      'calories': '380 kcal',
      'items': '4 items',
    },
  ];

  // Mock Daily Meal Plan
  final List<Map<String, dynamic>> _dailyMealPlan = [
    {
      'title': 'Banana Oat Pancakes',
      'image': 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?auto=format&fit=crop&w=400&q=80',
      'mealType': 'Breakfast',
    },
    {
      'title': 'Quinoa Salmon Bowl',
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=400&q=80',
      'mealType': 'Lunch',
    },
    {
      'title': 'Grilled Vegetable Pasta',
      'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80',
      'mealType': 'Dinner',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final user = _authService.currentUser;
      if (user != null && user.displayName != null) {
        final fullName = user.displayName!;
        final firstName = fullName.split(' ').first;
        if (mounted) {
          setState(() {
            _userFirstName = firstName;
          });
        }
      }
    } catch (_) {
      // Auth unavailable (e.g. Firebase not configured in this context);
      // keep the default greeting name.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TregoScaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _showDetail ? _buildRecipeDetailView(context) : _buildRecipeListView(context),
        ),
      ),
    );
  }

  Widget _buildRecipeListView(BuildContext context) {
    final tokens = context.tokens;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with greeting and icons
          Padding(
            padding: const EdgeInsets.fromLTRB(0, Space.lg, 0, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Hi ! $_userFirstName",
                    style: context.typo.title,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tokens.brand,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: tokens.onBrand,
                    size: 24,
                  ),
                ),
                const SizedBox(width: Space.md),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tokens.brand,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: tokens.onBrand,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Main title
          Padding(
            padding: const EdgeInsets.fromLTRB(0, Space.lg, 0, 0),
            child: Text(
              "What's On Your Plate Today?",
              style: context.typo.title,
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(0, Space.lg, 0, 0),
            child: Container(
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(Radii.standardCard),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: context.typo.body,
                      decoration: InputDecoration(
                        hintText: 'Describe what you\'re craving...',
                        hintStyle: context.typo.body.copyWith(color: tokens.inkMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.tune, color: tokens.inkMuted),
                    onPressed: () {},
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: Space.sm),
                    child: TregoButton(
                      label: 'Search',
                      loading: _isLoading,
                      onPressed: _isLoading ? null : () async {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        try {
                          final aiRecipe = await _recipeService.generateAIRecipe(
                            mealType: _selectedCategory,
                            targetCalories: 400,
                            availableIngredients: _searchController.text.isNotEmpty ? [_searchController.text] : null,
                          );
                          setState(() {
                            _aiRecipe = aiRecipe;
                            _isLoading = false;
                          });
                        } catch (e) {
                          setState(() {
                            _errorMessage = 'Failed to generate recipe. Please try again.';
                            _isLoading = false;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.sm),
              child: Text(_errorMessage!, style: context.typo.body.copyWith(color: tokens.danger)),
            ),

          // Easy AI Recipes Section
          Padding(
            padding: const EdgeInsets.fromLTRB(0, Space.xxl, 0, 0),
            child: Row(
              children: [
                Text(
                  "Easy AI Recipes",
                  style: context.typo.title,
                ),
                const Spacer(),
                TregoButton(
                  label: 'Generate new',
                  leadingIcon: Icons.star_rounded,
                  loading: _isLoading,
                  variant: TregoButtonVariant.secondary,
                  onPressed: _isLoading ? null : () async {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    try {
                      final aiRecipe = await _recipeService.generateAIRecipe(
                        mealType: _selectedCategory,
                        targetCalories: 400,
                      );
                      setState(() {
                        _aiRecipe = aiRecipe;
                        _isLoading = false;
                      });
                    } catch (e) {
                      setState(() {
                        _errorMessage = 'Failed to generate recipe. Please try again.';
                        _isLoading = false;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // AI Recipes Horizontal List
          Padding(
            padding: const EdgeInsets.fromLTRB(0, Space.lg, 0, 0),
            child: SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _aiRecipes.length,
                separatorBuilder: (_, __) => const SizedBox(width: Space.lg),
                itemBuilder: (context, index) {
                  final recipe = _aiRecipes[index];
                  return _buildRecipeCard(context, recipe);
                },
              ),
            ),
          ),

          // Daily Meal Plan Section
          Padding(
            padding: const EdgeInsets.fromLTRB(0, Space.xxl, 0, 0),
            child: Text(
              "Daily Meal Plan",
              style: context.typo.title,
            ),
          ),

          // Daily Meal Plan List
          Padding(
            padding: const EdgeInsets.fromLTRB(0, Space.lg, 0, Space.xxl),
            child: Column(
              children: _dailyMealPlan.map((meal) => _buildMealPlanItem(context, meal)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Map<String, dynamic> recipe) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: () => setState(() => _showDetail = true),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(Radii.screenWrapper),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Radii.screenWrapper),
                topRight: Radius.circular(Radii.screenWrapper),
              ),
              child: Image.network(
                recipe['image'],
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  width: double.infinity,
                  color: tokens.surfaceSunken,
                  child: Icon(Icons.image_not_supported_outlined, color: tokens.inkMuted),
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe['title'],
                        style: context.typo.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Space.md),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildInfoChip(context, Icons.schedule, recipe['time']),
                            const SizedBox(width: Space.sm),
                            _buildInfoChip(context, Icons.local_fire_department_rounded, recipe['calories']),
                            const SizedBox(width: Space.sm),
                            _buildInfoChip(context, Icons.restaurant_rounded, recipe['items']),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.lg),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _showDetail = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tokens.brand,
                                foregroundColor: tokens.onBrand,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Radii.button),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: Space.md),
                              ),
                              child: Text('Cook Now', style: context.typo.button),
                            ),
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: tokens.brand,
                                side: BorderSide(color: tokens.brand),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(Radii.button),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: Space.md),
                              ),
                              child: Text('Order Online', style: context.typo.button.copyWith(color: tokens.brand)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
      decoration: BoxDecoration(
        color: tokens.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tokens.inkMuted),
          const SizedBox(width: Space.xs),
          Text(
            text,
            style: context.typo.bodySmall.copyWith(color: tokens.inkMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanItem(BuildContext context, Map<String, dynamic> meal) {
    final tokens = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(Radii.standardCard),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.statTile),
            child: Image.network(
              meal['image'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: tokens.surfaceSunken,
                child: Icon(Icons.image_not_supported_outlined, color: tokens.inkMuted, size: 20),
              ),
            ),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['title'],
                  style: context.typo.titleSmall,
                ),
                const SizedBox(height: Space.xs),
                Row(
                  children: [
                    Icon(Icons.restaurant_rounded, size: 16, color: tokens.inkMuted),
                    const SizedBox(width: Space.xs),
                    Text(
                      meal['mealType'],
                      style: context.typo.body.copyWith(color: tokens.inkMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoIconText(BuildContext context, IconData icon, String text) {
    final tokens = context.tokens;
    return Row(
      children: [
        Icon(icon, color: tokens.brand, size: 18),
        const SizedBox(width: 5),
        Text(
          text,
          style: context.typo.body.copyWith(fontWeight: FontWeight.w600, color: tokens.ink),
        ),
      ],
    );
  }

  Widget _buildRecipeDetailView(BuildContext context) {
    final tokens = context.tokens;
    final recipe = _aiRecipe ?? _suggestedRecipe;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: Stack(
              children: [
                if ((recipe['image'] ?? '').toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(Radii.screenWrapper),
                      bottomRight: Radius.circular(Radii.screenWrapper),
                    ),
                    child: Image.network(
                      recipe['image'] ?? '',
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 260,
                        color: tokens.surfaceSunken,
                        child: Icon(Icons.image_not_supported_outlined, color: tokens.inkMuted),
                      ),
                    ),
                  ),
                Positioned(
                  top: 40,
                  left: Space.lg,
                  child: CircleAvatar(
                    backgroundColor: tokens.surface,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: tokens.brand),
                      onPressed: () => setState(() => _showDetail = false),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: Space.lg,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Space.xs),
                    decoration: BoxDecoration(
                      color: tokens.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(Radii.standardCard),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: tokens.brand, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Popular Recipe',
                          style: context.typo.bodySmall.copyWith(fontWeight: FontWeight.w700, color: tokens.brand),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.xl, 0),
            child: Text(
              recipe['title'] ?? '',
              style: context.typo.title,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, 14, Space.xl, 0),
            child: Row(
              children: [
                _buildInfoIconText(context, Icons.schedule, recipe['time'] ?? ''),
                const SizedBox(width: Space.lg),
                _buildInfoIconText(context, Icons.local_fire_department_rounded, recipe['calories'] ?? ''),
                const SizedBox(width: Space.lg),
                _buildInfoIconText(context, Icons.scale, recipe['weight'] ?? ''),
              ],
            ),
          ),
          // Portion selector
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, 18, Space.xl, 0),
            child: Row(
              children: [
                Text(
                  'Portion to cook',
                  style: context.typo.body.copyWith(fontWeight: FontWeight.w600, color: tokens.ink),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: tokens.brand),
                  onPressed: _portion > 1 ? () => setState(() => _portion--) : null,
                ),
                Text(
                  '$_portion',
                  style: context.typo.title,
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: tokens.brand),
                  onPressed: () => setState(() => _portion++),
                ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, 18, Space.xl, 0),
            child: Text(
              recipe['description'] ?? '',
              style: context.typo.body.copyWith(color: tokens.inkMuted),
            ),
          ),
          // Ingredients
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, 28, Space.xl, 0),
            child: Row(
              children: [
                Icon(Icons.list_alt_rounded, color: tokens.brand),
                const SizedBox(width: Space.sm),
                Text('Ingredients', style: context.typo.title),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xl, Space.xxl),
            child: Column(
              children: List.generate((recipe['ingredients'] as List?)?.length ?? 0, (i) {
                final rawIng = (recipe['ingredients'] as List)[i];
                final Map<String, dynamic> ing = rawIng is Map<String, dynamic>
                  ? rawIng
                  : {'name': rawIng?.toString() ?? '', 'icon': null, 'amount': ''};
                return Container(
                  margin: const EdgeInsets.only(bottom: Space.md),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(Radii.compactCard),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        ing['icon'] ?? Icons.circle,
                        color: tokens.brand,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          ing['name']?.toString() ?? '',
                          style: context.typo.titleSmall,
                        ),
                      ),
                      Text(
                        ing['amount']?.toString() ?? '',
                        style: context.typo.bodySmall.copyWith(color: tokens.inkMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
