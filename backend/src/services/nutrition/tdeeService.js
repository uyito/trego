const logger = require('../../utils/logger');
const { cache } = require('../../config/redis');

class TDEEService {
  constructor() {
    // Activity level multipliers based on research
    this.activityMultipliers = {
      'sedentary': 1.2,           // Little or no exercise
      'lightly_active': 1.375,    // Light exercise 1-3 days/week
      'moderately_active': 1.55,  // Moderate exercise 3-5 days/week
      'very_active': 1.725,       // Hard exercise 6-7 days/week
      'extremely_active': 1.9     // Very hard exercise, physical job
    };

    // Goal multipliers for calorie adjustment
    this.goalMultipliers = {
      'lose_weight_fast': 0.8,    // -20% (aggressive)
      'lose_weight': 0.85,        // -15% (moderate)
      'lose_weight_slow': 0.9,    // -10% (conservative)
      'maintain_weight': 1.0,     // 0% (maintenance)
      'gain_weight_slow': 1.1,    // +10% (lean bulk)
      'gain_weight': 1.15,        // +15% (moderate bulk)
      'gain_muscle': 1.2          // +20% (aggressive bulk)
    };

    // Macro distribution templates
    this.macroTemplates = {
      'balanced': { protein: 0.25, carbs: 0.45, fat: 0.30 },
      'high_protein': { protein: 0.35, carbs: 0.35, fat: 0.30 },
      'low_carb': { protein: 0.30, carbs: 0.20, fat: 0.50 },
      'keto': { protein: 0.25, carbs: 0.05, fat: 0.70 },
      'mediterranean': { protein: 0.20, carbs: 0.50, fat: 0.30 }
    };
  }

  // Calculate Basal Metabolic Rate using Mifflin-St Jeor Equation
  calculateBMR({ age, gender, weight, height, weightUnit = 'kg', heightUnit = 'cm' }) {
    try {
      // Convert to metric if needed
      let weightKg = weight;
      let heightCm = height;

      if (weightUnit === 'lbs') {
        weightKg = weight * 0.453592;
      }

      if (heightUnit === 'ft') {
        heightCm = height * 30.48;
      } else if (heightUnit === 'in') {
        heightCm = height * 2.54;
      }

      let bmr;
      if (gender.toLowerCase() === 'male') {
        bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
      } else {
        bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
      }

      return Math.round(bmr);
    } catch (error) {
      logger.error('BMR calculation failed', { error: error.message });
      throw new Error('Invalid parameters for BMR calculation');
    }
  }

  // Calculate Total Daily Energy Expenditure
  calculateTDEE({ bmr, activityLevel }) {
    const multiplier = this.activityMultipliers[activityLevel];
    if (!multiplier) {
      throw new Error(`Invalid activity level: ${activityLevel}`);
    }

    return Math.round(bmr * multiplier);
  }

  // Calculate target calories based on goals
  calculateTargetCalories({ tdee, goal }) {
    const multiplier = this.goalMultipliers[goal];
    if (!multiplier) {
      throw new Error(`Invalid goal: ${goal}`);
    }

    return Math.round(tdee * multiplier);
  }

  // Calculate macro targets
  calculateMacros({ targetCalories, macroTemplate = 'balanced' }) {
    const template = this.macroTemplates[macroTemplate];
    if (!template) {
      throw new Error(`Invalid macro template: ${macroTemplate}`);
    }

    return {
      protein: {
        percentage: template.protein,
        calories: Math.round(targetCalories * template.protein),
        grams: Math.round((targetCalories * template.protein) / 4) // 4 calories per gram
      },
      carbs: {
        percentage: template.carbs,
        calories: Math.round(targetCalories * template.carbs),
        grams: Math.round((targetCalories * template.carbs) / 4) // 4 calories per gram
      },
      fat: {
        percentage: template.fat,
        calories: Math.round(targetCalories * template.fat),
        grams: Math.round((targetCalories * template.fat) / 9) // 9 calories per gram
      }
    };
  }

  // Complete TDEE calculation with all components
  async calculateComplete({
    age,
    gender,
    weight,
    height,
    activityLevel,
    goal,
    weightUnit = 'kg',
    heightUnit = 'cm',
    macroTemplate = 'balanced',
    userId
  }) {
    try {
      // Create cache key
      const cacheKey = `tdee:${userId}:${JSON.stringify({
        age, gender, weight, height, activityLevel, goal, weightUnit, heightUnit, macroTemplate
      })}`;

      // Check cache first
      const cached = await cache.get(cacheKey);
      if (cached) {
        logger.info('Returning cached TDEE calculation', { userId });
        return cached;
      }

      // Calculate BMR
      const bmr = this.calculateBMR({ age, gender, weight, height, weightUnit, heightUnit });

      // Calculate TDEE
      const tdee = this.calculateTDEE({ bmr, activityLevel });

      // Calculate target calories
      const targetCalories = this.calculateTargetCalories({ tdee, goal });

      // Calculate macros
      const macros = this.calculateMacros({ targetCalories, macroTemplate });

      // Additional calculations
      const results = {
        bmr,
        tdee,
        targetCalories,
        macros,
        metadata: {
          age,
          gender,
          weight: { value: weight, unit: weightUnit },
          height: { value: height, unit: heightUnit },
          activityLevel,
          goal,
          macroTemplate,
          calculatedAt: new Date().toISOString()
        },
        recommendations: this.generateRecommendations({ bmr, tdee, targetCalories, goal, age, gender })
      };

      // Cache for 24 hours
      await cache.set(cacheKey, results, 86400);

      logger.info('TDEE calculated successfully', {
        userId,
        bmr,
        tdee,
        targetCalories,
        goal
      });

      return results;
    } catch (error) {
      logger.error('Complete TDEE calculation failed', { userId, error: error.message });
      throw error;
    }
  }

  // Generate personalized recommendations
  generateRecommendations({ bmr, tdee, targetCalories, goal, age, gender }) {
    const recommendations = [];

    // Water intake recommendation (ml per day)
    const waterIntake = Math.round(targetCalories * 1.2); // 1.2ml per calorie
    recommendations.push({
      type: 'hydration',
      title: 'Daily Water Intake',
      value: `${waterIntake}ml (${Math.round(waterIntake / 250)} glasses)`,
      description: 'Adequate hydration is crucial for metabolism and overall health'
    });

    // Meal frequency recommendation
    if (goal.includes('lose_weight')) {
      recommendations.push({
        type: 'meal_timing',
        title: 'Meal Frequency',
        value: '5-6 small meals',
        description: 'Frequent smaller meals can help maintain steady blood sugar and reduce cravings'
      });
    } else if (goal.includes('gain_weight') || goal === 'gain_muscle') {
      recommendations.push({
        type: 'meal_timing',
        title: 'Meal Frequency',
        value: '4-5 larger meals',
        description: 'Larger, more frequent meals help meet higher calorie requirements'
      });
    }

    // Exercise recommendations based on goal
    if (goal.includes('lose_weight')) {
      recommendations.push({
        type: 'exercise',
        title: 'Recommended Exercise',
        value: 'Cardio 4-5x/week + Strength training 2-3x/week',
        description: 'Combination of cardio and strength training optimizes fat loss while preserving muscle'
      });
    } else if (goal === 'gain_muscle') {
      recommendations.push({
        type: 'exercise',
        title: 'Recommended Exercise',
        value: 'Strength training 4-5x/week + Light cardio 2-3x/week',
        description: 'Focus on progressive overload in strength training with minimal cardio'
      });
    }

    // Age-specific recommendations
    if (age >= 50) {
      recommendations.push({
        type: 'nutrition',
        title: 'Age-Specific Nutrition',
        value: 'Higher protein intake (1.2-1.6g/kg body weight)',
        description: 'Older adults need more protein to maintain muscle mass and bone health'
      });
    }

    // Gender-specific recommendations
    if (gender.toLowerCase() === 'female') {
      recommendations.push({
        type: 'nutrition',
        title: 'Iron and Calcium',
        value: 'Focus on iron-rich foods and calcium sources',
        description: 'Women have higher needs for iron and calcium, especially during reproductive years'
      });
    }

    return recommendations;
  }

  // Track TDEE changes over time
  async trackProgress({ userId, weight, bodyFat, measurements = {} }) {
    try {
      const progressKey = `tdee_progress:${userId}`;
      const currentProgress = await cache.get(progressKey) || [];

      const newEntry = {
        date: new Date().toISOString(),
        weight,
        bodyFat,
        measurements,
        timestamp: Date.now()
      };

      currentProgress.push(newEntry);

      // Keep only last 100 entries
      if (currentProgress.length > 100) {
        currentProgress.splice(0, currentProgress.length - 100);
      }

      await cache.set(progressKey, currentProgress, 86400 * 30); // 30 days

      // Calculate trends if we have enough data
      if (currentProgress.length >= 2) {
        const trends = this.calculateTrends(currentProgress);
        return { progress: currentProgress, trends };
      }

      return { progress: currentProgress };
    } catch (error) {
      logger.error('Progress tracking failed', { userId, error: error.message });
      throw error;
    }
  }

  // Calculate progress trends
  calculateTrends(progressData) {
    if (progressData.length < 2) return null;

    const recent = progressData.slice(-7); // Last 7 entries
    const older = progressData.slice(-14, -7); // Previous 7 entries

    if (older.length === 0) return null;

    const recentAvg = recent.reduce((sum, entry) => sum + entry.weight, 0) / recent.length;
    const olderAvg = older.reduce((sum, entry) => sum + entry.weight, 0) / older.length;

    const weightTrend = recentAvg - olderAvg;

    return {
      weight: {
        change: Math.round(weightTrend * 10) / 10,
        direction: weightTrend > 0 ? 'increasing' : weightTrend < 0 ? 'decreasing' : 'stable',
        rate: Math.abs(weightTrend)
      },
      period: 'weekly'
    };
  }

  // Get available options for dropdowns
  getOptions() {
    return {
      activityLevels: Object.keys(this.activityMultipliers).map(key => ({
        value: key,
        label: key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()),
        multiplier: this.activityMultipliers[key]
      })),
      goals: Object.keys(this.goalMultipliers).map(key => ({
        value: key,
        label: key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()),
        multiplier: this.goalMultipliers[key]
      })),
      macroTemplates: Object.keys(this.macroTemplates).map(key => ({
        value: key,
        label: key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()),
        distribution: this.macroTemplates[key]
      }))
    };
  }
}

module.exports = new TDEEService();