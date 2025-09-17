import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/api_client.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiClient _apiClient = ApiClient.instance;

  // Get user's latest TDEE data
  Future<Map<String, dynamic>?> getUserTDEE(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tdee')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Generate AI recipe using backend API
  Future<Map<String, dynamic>> generateAIRecipe({
    required String mealType,
    int? maxPrepTime,
    int? targetCalories,
    List<String>? dietaryRestrictions,
    List<String>? availableIngredients,
    String? cuisineType,
    int? servings,
  }) async {
    try {
      final response = await _apiClient.post('/recipes/generate-ai', data: {
        'mealType': mealType,
        if (maxPrepTime != null) 'maxPrepTime': maxPrepTime,
        if (targetCalories != null) 'targetCalories': targetCalories,
        if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty)
          'dietaryRestrictions': dietaryRestrictions,
        if (availableIngredients != null && availableIngredients.isNotEmpty)
          'availableIngredients': availableIngredients,
        if (cuisineType != null) 'cuisineType': cuisineType,
        if (servings != null) 'servings': servings,
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Backend AI recipe generation failed: $e');
    }
    
    // Fallback to mock data
    return _generateMockRecipe(
      dietaryPreference: dietaryRestrictions?.first ?? 'Balanced',
      mealType: mealType,
      calories: targetCalories ?? 500,
      foodName: null,
    );
  }

  // Get personalized recipe recommendations
  Future<List<Map<String, dynamic>>> getRecommendations({
    int limit = 10,
    String? mealType,
  }) async {
    try {
      final response = await _apiClient.get('/recipes/recommendations', queryParameters: {
        'limit': limit.toString(),
        if (mealType != null) 'mealType': mealType,
      });
      
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Failed to get recipe recommendations: $e');
    }
    
    return [];
  }

  // Search recipes
  Future<List<Map<String, dynamic>>> searchRecipes({
    String? query,
    String? cuisine,
    int? maxCalories,
    String? difficulty,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        if (query != null && query.isNotEmpty) 'query': query,
        if (cuisine != null) 'cuisine': cuisine,
        if (maxCalories != null) 'maxCalories': maxCalories.toString(),
        if (difficulty != null) 'difficulty': difficulty,
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final response = await _apiClient.get('/recipes/search', queryParameters: queryParams);
      
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Recipe search failed: $e');
    }
    
    return [];
  }

  // Generate recipe from pantry items
  Future<Map<String, dynamic>?> generateFromPantry({
    bool useExpiringItems = true,
    int maxAdditionalIngredients = 3,
    String? mealType,
    int? prepTime,
    String? difficulty,
  }) async {
    try {
      final response = await _apiClient.post('/recipes/from-pantry', data: {
        'useExpiringItems': useExpiringItems,
        'maxAdditionalIngredients': maxAdditionalIngredients,
        if (mealType != null) 'mealType': mealType,
        if (prepTime != null) 'maxPrepTime': prepTime,
        if (difficulty != null) 'difficulty': difficulty,
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Pantry recipe generation failed: $e');
    }
    
    return null;
  }

  // Save recipe
  Future<bool> saveRecipeToBackend(String recipeId) async {
    try {
      final response = await _apiClient.post('/recipes/$recipeId/save', data: {});
      return response.data?['success'] == true;
    } catch (e) {
      print('Failed to save recipe: $e');
      return false;
    }
  }

  // Rate recipe
  Future<bool> rateRecipe(String recipeId, int rating) async {
    try {
      final response = await _apiClient.post('/recipes/$recipeId/rate', data: {
        'rating': rating,
      });
      return response.data?['success'] == true;
    } catch (e) {
      print('Failed to rate recipe: $e');
      return false;
    }
  }

  // Mark recipe as made
  Future<bool> markRecipeAsMade(String recipeId) async {
    try {
      final response = await _apiClient.post('/recipes/$recipeId/made', data: {});
      return response.data?['success'] == true;
    } catch (e) {
      print('Failed to mark recipe as made: $e');
      return false;
    }
  }

  // Get meal plan suggestions
  Future<Map<String, dynamic>?> getMealPlan({
    int days = 7,
    String? mealType,
  }) async {
    try {
      final queryParams = <String, String>{
        'days': days.toString(),
        if (mealType != null) 'mealType': mealType,
      };
      
      final response = await _apiClient.get('/recipes/meal-plan', queryParameters: queryParams);
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to get meal plan: $e');
    }
    
    return null;
  }

  // Get user's saved recipes
  Future<List<Map<String, dynamic>>> getMySavedRecipes({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final response = await _apiClient.get('/recipes/my-recipes', queryParameters: queryParams);
      
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Failed to get saved recipes: $e');
    }
    
    return [];
  }

  // Get popular recipes
  Future<List<Map<String, dynamic>>> getPopularRecipes({
    int limit = 20,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (category != null) 'category': category,
      };
      
      final response = await _apiClient.get('/recipes/popular', queryParameters: queryParams);
      
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Failed to get popular recipes: $e');
    }
    
    return [];
  }

  // Analyze nutrition using backend API
  Future<Map<String, dynamic>?> analyzeNutrition(String foodText) async {
    try {
      final response = await _apiClient.post('/api/recipes/analyze-nutrition', data: {
        'foodText': foodText,
      });
      
      if (response.data['success'] == true) {
        return response.data['nutrition'];
      }
    } catch (e) {
      print('Nutrition analysis failed: $e');
    }
    
    return null;
  }

  // Get usage statistics from backend
  Future<Map<String, dynamic>?> getUsageStats() async {
    try {
      final response = await _apiClient.get('/api/recipes/usage');
      
      if (response.data['success'] == true) {
        return response.data['usage'];
      }
    } catch (e) {
      print('Failed to get usage stats: $e');
    }
    
    return null;
  }


  Map<String, dynamic> _generateMockRecipe({
    required String dietaryPreference,
    required String mealType,
    required int calories,
    String? foodName,
  }) {
    // If foodName is provided, generate a variant of that food
    if (foodName != null && foodName.isNotEmpty) {
      return _generateFoodVariantRecipe(
        foodName: foodName,
        dietaryPreference: dietaryPreference,
        calories: calories,
      );
    }
    
    // Generate different recipes based on dietary preference and meal type
    if (dietaryPreference == 'High Protein') {
      return {
        'title': 'High-Protein Chickpea Salad',
        'calories': calories.toString(),
        'ingredients': [
          '1 cup canned chickpeas',
          '1 tbsp olive oil',
          '1/2 avocado',
          'Lemon juice',
          'Salt & pepper',
          'Fresh herbs',
        ],
        'steps': [
          'Drain and rinse chickpeas thoroughly.',
          'Mash half of them with avocado in a bowl.',
          'Mix all ingredients together gently.',
          'Top with lemon juice and fresh herbs.',
          'Season with salt and pepper to taste.',
        ],
        'macros': {
          'protein': '20g',
          'carbs': '35g',
          'fat': '18g',
        },
      };
    } else if (dietaryPreference == 'Vegan') {
      return {
        'title': 'Vegan Buddha Bowl',
        'calories': calories.toString(),
        'ingredients': [
          '1 cup quinoa',
          '1 cup mixed vegetables',
          '1/2 cup chickpeas',
          '2 tbsp tahini',
          'Lemon juice',
          'Fresh herbs',
        ],
        'steps': [
          'Cook quinoa according to package instructions.',
          'Steam or roast mixed vegetables.',
          'Prepare tahini dressing with lemon juice.',
          'Assemble bowl with quinoa, vegetables, and chickpeas.',
          'Drizzle with tahini dressing and garnish with herbs.',
        ],
        'macros': {
          'protein': '15g',
          'carbs': '45g',
          'fat': '12g',
        },
      };
    } else if (dietaryPreference == 'Low Carb') {
      return {
        'title': 'Low-Carb Cauliflower Rice Bowl',
        'calories': calories.toString(),
        'ingredients': [
          '2 cups cauliflower rice',
          '1 chicken breast',
          '1 cup broccoli',
          '2 tbsp olive oil',
          'Garlic and herbs',
          'Salt & pepper',
        ],
        'steps': [
          'Season and cook chicken breast until done.',
          'Sauté cauliflower rice in olive oil.',
          'Steam broccoli until tender-crisp.',
          'Combine all ingredients in a bowl.',
          'Season with garlic, herbs, salt, and pepper.',
        ],
        'macros': {
          'protein': '35g',
          'carbs': '15g',
          'fat': '25g',
        },
      };
    } else {
      // Default recipe
      return {
        'title': 'Balanced Mediterranean Bowl',
        'calories': calories.toString(),
        'ingredients': [
          '1 cup brown rice',
          '1/2 cup grilled chicken',
          '1 cup mixed vegetables',
          '2 tbsp olive oil',
          'Lemon juice',
          'Fresh herbs',
        ],
        'steps': [
          'Cook brown rice according to package instructions.',
          'Grill chicken breast until cooked through.',
          'Steam or roast mixed vegetables.',
          'Combine rice, chicken, and vegetables in a bowl.',
          'Drizzle with olive oil and lemon juice.',
          'Garnish with fresh herbs and serve.',
        ],
        'macros': {
          'protein': '30g',
          'carbs': '40g',
          'fat': '20g',
        },
      };
    }
  }

  // Save recipe to Firestore
  Future<void> saveRecipe({
    required String userId,
    required Map<String, dynamic> recipe,
    required String dietaryPreference,
    required String mealType,
    required int calories,
    List<String>? dietaryFilters,
    List<String>? allergens,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('savedRecipes').add({
        'recipe': recipe,
        'dietaryPreference': dietaryPreference,
        'mealType': mealType,
        'calories': calories,
        'dietaryFilters': dietaryFilters ?? [],
        'allergens': allergens ?? [],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user's saved recipes
  Stream<QuerySnapshot> getUserSavedRecipes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedRecipes')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Save recipe template
  Future<void> saveRecipeTemplate({
    required String name,
    required String description,
    required List<String> ingredients,
    required List<String> instructions,
  }) async {
    try {
      await _firestore.collection('recipe_templates').add({
        'name': name,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get recipe templates
  Stream<QuerySnapshot> getRecipeTemplates() {
    return _firestore
        .collection('recipe_templates')
        .orderBy('name')
        .snapshots();
  }

  // Add recipe to meal plan
  Future<void> addToMealPlan({
    required String userId,
    required Map<String, dynamic> recipe,
    required String mealType,
    required DateTime date,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('mealPlan').add({
        'recipe': recipe,
        'mealType': mealType,
        'date': date,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get user's meal plan
  Stream<QuerySnapshot> getUserMealPlan(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('mealPlan')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // Generate shopping list from meal plan
  Future<List<String>> generateShoppingList(String userId) async {
    try {
      final mealPlanSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mealPlan')
          .get();
      
      final ingredients = <String>{};
      for (final doc in mealPlanSnapshot.docs) {
        final data = doc.data();
        final recipe = data['recipe'] as Map<String, dynamic>;
        final recipeIngredients = recipe['ingredients'] as List<dynamic>;
        ingredients.addAll(recipeIngredients.map((i) => i.toString()));
      }
      
      return ingredients.toList();
    } catch (e) {
      return [];
    }
  }

  // Generate food variant recipe
  Map<String, dynamic> _generateFoodVariantRecipe({
    required String foodName,
    required String dietaryPreference,
    required int calories,
  }) {
    final title = '${dietaryPreference} $foodName';
    
    // Generate different variants based on dietary preference
    if (dietaryPreference == 'Vegan') {
      return {
        'title': title,
        'calories': calories.toString(),
        'ingredients': [
          'Plant-based protein substitute',
          'Fresh vegetables',
          'Whole grains',
          'Herbs and spices',
          'Olive oil',
          'Lemon juice',
        ],
        'steps': [
          'Prepare plant-based protein according to package instructions.',
          'Chop and prepare fresh vegetables.',
          'Cook whole grains until tender.',
          'Combine all ingredients in a bowl.',
          'Season with herbs, spices, and lemon juice.',
          'Drizzle with olive oil and serve.',
        ],
        'macros': {
          'protein': '15g',
          'carbs': '45g',
          'fat': '12g',
        },
      };
    } else if (dietaryPreference == 'Low Carb') {
      return {
        'title': title,
        'calories': calories.toString(),
        'ingredients': [
          'Lean protein source',
          'Low-carb vegetables',
          'Healthy fats',
          'Herbs and spices',
          'Olive oil',
          'Salt and pepper',
        ],
        'steps': [
          'Season and cook lean protein until done.',
          'Sauté low-carb vegetables in olive oil.',
          'Combine protein and vegetables.',
          'Add healthy fats and seasonings.',
          'Serve hot with fresh herbs.',
        ],
        'macros': {
          'protein': '35g',
          'carbs': '15g',
          'fat': '25g',
        },
      };
    } else if (dietaryPreference == 'High Protein') {
      return {
        'title': title,
        'calories': calories.toString(),
        'ingredients': [
          'High-protein main ingredient',
          'Protein-rich vegetables',
          'Quinoa or legumes',
          'Nuts or seeds',
          'Herbs and spices',
          'Olive oil',
        ],
        'steps': [
          'Cook high-protein main ingredient.',
          'Prepare protein-rich vegetables.',
          'Cook quinoa or legumes.',
          'Combine all ingredients.',
          'Top with nuts or seeds.',
          'Season with herbs and spices.',
        ],
        'macros': {
          'protein': '40g',
          'carbs': '30g',
          'fat': '15g',
        },
      };
    } else {
      // Default balanced version
      return {
        'title': title,
        'calories': calories.toString(),
        'ingredients': [
          'Main ingredient',
          'Mixed vegetables',
          'Whole grains',
          'Healthy fats',
          'Herbs and spices',
          'Lemon or vinegar',
        ],
        'steps': [
          'Prepare main ingredient according to preference.',
          'Steam or roast mixed vegetables.',
          'Cook whole grains until tender.',
          'Combine all ingredients in a bowl.',
          'Add healthy fats and seasonings.',
          'Finish with lemon or vinegar for brightness.',
        ],
        'macros': {
          'protein': '25g',
          'carbs': '40g',
          'fat': '18g',
        },
      };
    }
  }
} 