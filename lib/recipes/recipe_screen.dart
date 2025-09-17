import 'package:flutter/material.dart';
import 'dart:async';
import 'package:trego/recipes/recipe_service.dart';
import 'package:trego/auth/auth_service.dart';

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
  final RecipeService _recipeService = RecipeService();
  final AuthService _authService = AuthService();
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
    final user = _authService.currentUser;
    if (user != null && user.displayName != null) {
      final fullName = user.displayName!;
      final firstName = fullName.split(' ').first;
      setState(() {
        _userFirstName = firstName;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _showDetail ? _buildRecipeDetailView(context) : _buildRecipeListView(context),
        ),
      ),
    );
  }

  Widget _buildRecipeListView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with greeting and icons
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Hi ! $_userFirstName",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Main title
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: Text(
              "What's On Your Plate Today?",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Describe what you\'re craving...',
                        hintStyle: TextStyle(color: Color(0xFF999999)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF666666)),
                    onPressed: () {},
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Search', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          
          // Easy AI Recipes Section
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
            child: Row(
              children: [
                Text(
                  "Easy AI Recipes",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
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
                  icon: _isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                        )
                      : const Icon(Icons.star_rounded, size: 18),
                  label: const Text('Generate new'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0E7FF),
                    foregroundColor: const Color(0xFF6366F1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // AI Recipes Horizontal List
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _aiRecipes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final recipe = _aiRecipes[index];
                  return _buildRecipeCard(recipe);
                },
              ),
            ),
          ),
          
          // Daily Meal Plan Section
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
            child: Text(
              "Daily Meal Plan",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          
          // Daily Meal Plan List
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
            child: Column(
              children: _dailyMealPlan.map((meal) => _buildMealPlanItem(meal)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return GestureDetector(
      onTap: () => setState(() => _showDetail = true),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Image.network(
                recipe['image'],
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildInfoChip(Icons.schedule, recipe['time']),
                            const SizedBox(width: 8),
                            _buildInfoChip(Icons.local_fire_department_rounded, recipe['calories']),
                            const SizedBox(width: 8),
                            _buildInfoChip(Icons.restaurant_rounded, recipe['items']),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _showDetail = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cook Now', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF8B5CF6),
                                side: const BorderSide(color: Color(0xFF8B5CF6)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Order Online', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF666666)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanItem(Map<String, dynamic> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              meal['image'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.restaurant_rounded, size: 16, color: Color(0xFF666666)),
                    const SizedBox(width: 4),
                    Text(
                      meal['mealType'],
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
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

  Widget _buildInfoIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE31E24), size: 18),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeDetailView(BuildContext context) {
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
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    child: Image.network(
                      recipe['image'] ?? '',
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                    ),
                  ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFFE31E24)),
                      onPressed: () => setState(() => _showDetail = false),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.star_rounded, color: Color(0xFFE31E24), size: 18),
                        SizedBox(width: 6),
                        Text('Popular Recipe', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE31E24))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              recipe['title'] ?? '',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Row(
              children: [
                _buildInfoIconText(Icons.schedule, recipe['time'] ?? ''),
                const SizedBox(width: 16),
                _buildInfoIconText(Icons.local_fire_department_rounded, recipe['calories'] ?? ''),
                const SizedBox(width: 16),
                _buildInfoIconText(Icons.scale, recipe['weight'] ?? ''),
              ],
            ),
          ),
          // Portion selector
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Row(
              children: [
                const Text('Portion to cook', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFE31E24)),
                  onPressed: _portion > 1 ? () => setState(() => _portion--) : null,
                ),
                Text('$_portion', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE31E24)),
                  onPressed: () => setState(() => _portion++),
                ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Text(
              recipe['description'] ?? '',
              style: const TextStyle(fontSize: 15, color: Color(0xFF444444)),
            ),
          ),
          // Ingredients
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Row(
              children: const [
                Icon(Icons.list_alt_rounded, color: Color(0xFFE31E24)),
                SizedBox(width: 8),
                Text('Ingredients', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              children: List.generate((recipe['ingredients'] as List?)?.length ?? 0, (i) {
                final rawIng = (recipe['ingredients'] as List)[i];
                final Map<String, dynamic> ing = rawIng is Map<String, dynamic>
                  ? rawIng
                  : {'name': rawIng?.toString() ?? '', 'icon': null, 'amount': ''};
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (ing['icon'] != null)
                        Icon(ing['icon'], color: const Color(0xFFE31E24), size: 22),
                      if (ing['icon'] == null)
                        const Icon(Icons.circle, color: Color(0xFFE31E24), size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          ing['name']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      Text(
                        ing['amount']?.toString() ?? '',
                        style: const TextStyle(color: Color(0xFF666666), fontWeight: FontWeight.w500),
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