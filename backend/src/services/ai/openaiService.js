const { OpenAI } = require('openai');
const logger = require('../../utils/logger');
const { cache } = require('../../config/redis');

class OpenAIService {
  constructor() {
    this.client = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
      organization: process.env.OPENAI_ORGANIZATION,
    });
    
    this.rateLimits = {
      recipeGeneration: { requests: 50, window: 3600 }, // 50 requests per hour
      nutritionAnalysis: { requests: 100, window: 3600 }, // 100 requests per hour
      workoutPlanning: { requests: 30, window: 3600 }, // 30 requests per hour
    };
  }

  async checkRateLimit(userId, service) {
    const key = `rate_limit:${service}:${userId}`;
    const current = await cache.get(key) || 0;
    const limit = this.rateLimits[service];

    if (current >= limit.requests) {
      throw new Error(`Rate limit exceeded for ${service}. Try again in ${Math.ceil(limit.window / 60)} minutes.`);
    }

    await cache.set(key, current + 1, limit.window);
    return true;
  }

  async generateRecipe({ 
    dietaryPreference, 
    mealType, 
    calories, 
    ingredients, 
    allergens = [], 
    cuisine = '', 
    cookingTime = '', 
    difficulty = '',
    userId 
  }) {
    try {
      await this.checkRateLimit(userId, 'recipeGeneration');

      // Create cache key for similar requests
      const cacheKey = `recipe:${JSON.stringify({ 
        dietaryPreference, mealType, calories, ingredients, allergens 
      })}`;
      
      const cached = await cache.get(cacheKey);
      if (cached) {
        logger.info('Returning cached recipe', { userId, cacheKey });
        return cached;
      }

      const allergenText = allergens.length > 0 ? `Avoid: ${allergens.join(', ')}. ` : '';
      const cuisineText = cuisine ? `Cuisine style: ${cuisine}. ` : '';
      const timeText = cookingTime ? `Cooking time: ${cookingTime} minutes. ` : '';
      const difficultyText = difficulty ? `Difficulty: ${difficulty}. ` : '';
      const ingredientText = ingredients ? `Must include: ${ingredients}. ` : '';

      const prompt = `Create a detailed ${dietaryPreference} ${mealType} recipe with approximately ${calories} calories.
${ingredientText}${allergenText}${cuisineText}${timeText}${difficultyText}

Please provide a JSON response with the following structure:
{
  "name": "Recipe Name",
  "description": "Brief description",
  "calories": ${calories},
  "servings": 1,
  "prepTime": "10 minutes",
  "cookTime": "15 minutes",
  "difficulty": "Easy/Medium/Hard",
  "ingredients": [
    {
      "item": "ingredient name",
      "amount": "quantity",
      "unit": "cups/tbsp/etc",
      "calories": 100
    }
  ],
  "instructions": [
    "Step 1 instruction",
    "Step 2 instruction"
  ],
  "nutrition": {
    "calories": ${calories},
    "protein": "25g",
    "carbs": "30g",
    "fat": "15g",
    "fiber": "5g",
    "sugar": "10g"
  },
  "tags": ["dietary tags", "meal type"],
  "tips": ["cooking tips"]
}

Ensure the total calories from all ingredients approximately match the target of ${calories} calories.`;

      const completion = await this.client.chat.completions.create({
        model: 'gpt-4-turbo-preview',
        messages: [
          {
            role: 'system',
            content: 'You are a professional nutritionist and chef. Generate healthy, delicious recipes with accurate nutritional information. Always respond with valid JSON only.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 2000,
        temperature: 0.7,
        response_format: { type: 'json_object' }
      });

      const recipe = JSON.parse(completion.choices[0].message.content);
      
      // Cache the result for 24 hours
      await cache.set(cacheKey, recipe, 86400);

      logger.info('Recipe generated successfully', { 
        userId, 
        recipeName: recipe.name,
        calories: recipe.calories,
        tokens: completion.usage.total_tokens 
      });

      return recipe;
    } catch (error) {
      logger.error('Recipe generation failed', { userId, error: error.message });
      
      // Return fallback recipe if API fails
      if (error.message.includes('Rate limit') || error.response?.status === 429) {
        throw error;
      }
      
      return this.getFallbackRecipe(dietaryPreference, mealType, calories);
    }
  }

  async analyzeNutrition({ foodText, userId }) {
    try {
      await this.checkRateLimit(userId, 'nutritionAnalysis');

      const cacheKey = `nutrition:${foodText.toLowerCase().trim()}`;
      const cached = await cache.get(cacheKey);
      if (cached) {
        return cached;
      }

      const prompt = `Analyze the nutritional content of: "${foodText}"

Provide a JSON response with this structure:
{
  "food": "${foodText}",
  "portion": "1 serving",
  "nutrition": {
    "calories": 250,
    "protein": "20g",
    "carbs": "30g",
    "fat": "10g",
    "fiber": "5g",
    "sugar": "8g",
    "sodium": "400mg",
    "cholesterol": "50mg"
  },
  "vitamins": {
    "vitaminC": "15mg",
    "vitaminD": "2mcg",
    "calcium": "100mg",
    "iron": "2mg"
  },
  "confidence": 0.85
}

If the food item is unclear or you're uncertain, set confidence to a lower value.`;

      const completion = await this.client.chat.completions.create({
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: 'You are a nutrition expert. Analyze food items and provide accurate nutritional information. Always respond with valid JSON only.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 500,
        temperature: 0.3,
        response_format: { type: 'json_object' }
      });

      const analysis = JSON.parse(completion.choices[0].message.content);
      
      // Cache for 7 days
      await cache.set(cacheKey, analysis, 604800);

      return analysis;
    } catch (error) {
      logger.error('Nutrition analysis failed', { userId, error: error.message });
      throw new Error('Unable to analyze nutrition information at this time');
    }
  }

  async generateWorkoutPlan({ 
    fitnessLevel, 
    goals, 
    duration, 
    equipment, 
    preferences,
    userId 
  }) {
    try {
      await this.checkRateLimit(userId, 'workoutPlanning');

      const prompt = `Create a personalized workout plan with these parameters:
- Fitness Level: ${fitnessLevel}
- Goals: ${goals.join(', ')}
- Duration: ${duration} minutes
- Equipment: ${equipment.join(', ') || 'None'}
- Preferences: ${preferences.join(', ') || 'None'}

Provide a JSON response with this structure:
{
  "name": "Workout Plan Name",
  "duration": ${duration},
  "difficulty": "${fitnessLevel}",
  "goals": ${JSON.stringify(goals)},
  "exercises": [
    {
      "name": "Exercise Name",
      "type": "strength/cardio/flexibility",
      "duration": "30 seconds",
      "reps": "10-12",
      "sets": 3,
      "restTime": "60 seconds",
      "instructions": "How to perform the exercise",
      "modifications": "Easier/harder variations",
      "targetMuscles": ["muscle groups"]
    }
  ],
  "warmup": [
    {
      "exercise": "Warm-up exercise",
      "duration": "2 minutes"
    }
  ],
  "cooldown": [
    {
      "exercise": "Cool-down exercise", 
      "duration": "3 minutes"
    }
  ],
  "tips": ["workout tips"]
}`;

      const completion = await this.client.chat.completions.create({
        model: 'gpt-4-turbo-preview',
        messages: [
          {
            role: 'system',
            content: 'You are a certified fitness trainer. Create safe, effective workout plans tailored to user needs. Always respond with valid JSON only.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 2000,
        temperature: 0.7,
        response_format: { type: 'json_object' }
      });

      const workoutPlan = JSON.parse(completion.choices[0].message.content);
      
      logger.info('Workout plan generated', { 
        userId, 
        duration,
        exerciseCount: workoutPlan.exercises.length 
      });

      return workoutPlan;
    } catch (error) {
      logger.error('Workout plan generation failed', { userId, error: error.message });
      throw new Error('Unable to generate workout plan at this time');
    }
  }

  getFallbackRecipe(dietaryPreference, mealType, calories) {
    const fallbackRecipes = {
      'breakfast': {
        name: 'Simple Oatmeal Bowl',
        description: 'A nutritious breakfast bowl with oats and fresh fruits',
        calories: Math.min(calories, 400),
        servings: 1,
        prepTime: '5 minutes',
        cookTime: '5 minutes',
        difficulty: 'Easy',
        ingredients: [
          { item: 'rolled oats', amount: '1/2', unit: 'cup', calories: 150 },
          { item: 'almond milk', amount: '1', unit: 'cup', calories: 40 },
          { item: 'banana', amount: '1/2', unit: 'medium', calories: 50 },
          { item: 'honey', amount: '1', unit: 'tbsp', calories: 64 }
        ],
        instructions: [
          'Heat almond milk in a saucepan',
          'Add oats and cook for 3-5 minutes',
          'Top with sliced banana and drizzle with honey'
        ],
        nutrition: {
          calories: 304,
          protein: '8g',
          carbs: '58g',
          fat: '4g',
          fiber: '7g',
          sugar: '20g'
        },
        tags: [dietaryPreference, mealType],
        tips: ['Add nuts for extra protein', 'Use frozen berries for antioxidants']
      }
    };

    return fallbackRecipes[mealType] || fallbackRecipes['breakfast'];
  }

  async getUsageStats(userId) {
    const services = Object.keys(this.rateLimits);
    const usage = {};

    for (const service of services) {
      const key = `rate_limit:${service}:${userId}`;
      usage[service] = {
        used: await cache.get(key) || 0,
        limit: this.rateLimits[service].requests,
        window: this.rateLimits[service].window
      };
    }

    return usage;
  }
}

module.exports = new OpenAIService();