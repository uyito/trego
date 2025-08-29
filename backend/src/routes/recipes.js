const express = require('express');
const { body, validationResult } = require('express-validator');
const openaiService = require('../services/ai/openaiService');
const { premiumMiddleware } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Validation middleware
const validateRecipeGeneration = [
  body('dietaryPreference')
    .isIn(['vegetarian', 'vegan', 'pescatarian', 'keto', 'paleo', 'mediterranean', 'low-carb', 'high-protein', 'balanced'])
    .withMessage('Invalid dietary preference'),
  body('mealType')
    .isIn(['breakfast', 'lunch', 'dinner', 'snack', 'dessert'])
    .withMessage('Invalid meal type'),
  body('calories')
    .isInt({ min: 100, max: 2000 })
    .withMessage('Calories must be between 100 and 2000'),
  body('ingredients')
    .optional()
    .isString()
    .isLength({ max: 500 })
    .withMessage('Ingredients must be a string with max 500 characters'),
  body('allergens')
    .optional()
    .isArray()
    .withMessage('Allergens must be an array'),
  body('cuisine')
    .optional()
    .isString()
    .isLength({ max: 50 })
    .withMessage('Cuisine must be a string with max 50 characters'),
  body('cookingTime')
    .optional()
    .isInt({ min: 5, max: 180 })
    .withMessage('Cooking time must be between 5 and 180 minutes'),
  body('difficulty')
    .optional()
    .isIn(['easy', 'medium', 'hard'])
    .withMessage('Difficulty must be easy, medium, or hard')
];

const validateNutritionAnalysis = [
  body('foodText')
    .isString()
    .isLength({ min: 1, max: 200 })
    .withMessage('Food text must be between 1 and 200 characters'),
];

// Generate recipe using AI
router.post('/generate', validateRecipeGeneration, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      dietaryPreference,
      mealType,
      calories,
      ingredients,
      allergens = [],
      cuisine = '',
      cookingTime = '',
      difficulty = ''
    } = req.body;

    const recipe = await openaiService.generateRecipe({
      dietaryPreference,
      mealType,
      calories,
      ingredients,
      allergens,
      cuisine,
      cookingTime,
      difficulty,
      userId: req.user.uid
    });

    // Log successful generation for analytics
    logger.info('Recipe generated via API', {
      userId: req.user.uid,
      mealType,
      dietaryPreference,
      calories
    });

    res.json({
      success: true,
      recipe,
      generatedAt: new Date().toISOString()
    });

  } catch (error) {
    next(error);
  }
});

// Analyze nutrition content
router.post('/analyze-nutrition', validateNutritionAnalysis, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { foodText } = req.body;

    const analysis = await openaiService.analyzeNutrition({
      foodText,
      userId: req.user.uid
    });

    res.json({
      success: true,
      analysis,
      analyzedAt: new Date().toISOString()
    });

  } catch (error) {
    next(error);
  }
});

// Get user's AI service usage stats
router.get('/usage', async (req, res, next) => {
  try {
    const usage = await openaiService.getUsageStats(req.user.uid);

    res.json({
      success: true,
      usage,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    next(error);
  }
});

// Premium feature: Generate meal plan for the week
router.post('/meal-plan', premiumMiddleware, async (req, res, next) => {
  try {
    const {
      dietaryPreference = 'balanced',
      caloriesPerDay = 2000,
      mealsPerDay = 3,
      days = 7
    } = req.body;

    if (days > 14) {
      return res.status(400).json({
        error: 'Maximum 14 days allowed for meal planning'
      });
    }

    const mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'].slice(0, mealsPerDay);
    const caloriesPerMeal = Math.floor(caloriesPerDay / mealsPerDay);
    
    const mealPlan = [];
    
    for (let day = 1; day <= days; day++) {
      const dayMeals = [];
      
      for (const mealType of mealTypes) {
        try {
          const recipe = await openaiService.generateRecipe({
            dietaryPreference,
            mealType,
            calories: caloriesPerMeal,
            userId: req.user.uid
          });
          
          dayMeals.push({
            mealType,
            recipe
          });
        } catch (error) {
          logger.warn(`Failed to generate ${mealType} for day ${day}:`, error.message);
          // Continue with other meals even if one fails
        }
      }
      
      mealPlan.push({
        day,
        meals: dayMeals,
        totalCalories: dayMeals.reduce((sum, meal) => sum + (meal.recipe?.calories || 0), 0)
      });
    }

    res.json({
      success: true,
      mealPlan,
      summary: {
        totalDays: days,
        mealsPerDay,
        targetCaloriesPerDay: caloriesPerDay,
        dietaryPreference
      },
      generatedAt: new Date().toISOString()
    });

  } catch (error) {
    next(error);
  }
});

// Search and save recipes (fallback for when AI is unavailable)
router.get('/search', async (req, res, next) => {
  try {
    const { q, type, diet, maxCalories } = req.query;
    
    // This would integrate with a recipe database or external API
    // For now, return mock data
    const mockRecipes = [
      {
        id: '1',
        name: 'Healthy Quinoa Bowl',
        calories: 450,
        type: 'lunch',
        diet: 'vegetarian',
        prepTime: '15 minutes',
        difficulty: 'easy'
      },
      {
        id: '2', 
        name: 'Grilled Salmon with Vegetables',
        calories: 380,
        type: 'dinner',
        diet: 'pescatarian',
        prepTime: '25 minutes',
        difficulty: 'medium'
      }
    ];

    let filteredRecipes = mockRecipes;
    
    if (q) {
      filteredRecipes = filteredRecipes.filter(recipe => 
        recipe.name.toLowerCase().includes(q.toLowerCase())
      );
    }
    
    if (type) {
      filteredRecipes = filteredRecipes.filter(recipe => recipe.type === type);
    }
    
    if (diet) {
      filteredRecipes = filteredRecipes.filter(recipe => recipe.diet === diet);
    }
    
    if (maxCalories) {
      filteredRecipes = filteredRecipes.filter(recipe => 
        recipe.calories <= parseInt(maxCalories)
      );
    }

    res.json({
      success: true,
      recipes: filteredRecipes,
      total: filteredRecipes.length,
      query: { q, type, diet, maxCalories }
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;