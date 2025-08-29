const express = require('express');
const { query, validationResult } = require('express-validator');
const personalizationService = require('../services/ai/personalizationService');
const { premiumMiddleware } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Get personalized workout recommendations
router.get('/workouts', [
  query('count').optional().isInt({ min: 1, max: 20 }),
  query('workoutType').optional().isIn(['cardio', 'strength', 'flexibility', 'hiit', 'mixed']),
  query('duration').optional().isInt({ min: 10, max: 120 }),
  query('refreshProfile').optional().isBoolean()
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      count = 5,
      workoutType,
      duration,
      refreshProfile = false
    } = req.query;

    const recommendations = await personalizationService.generateWorkoutRecommendations(
      req.user.uid,
      {
        count: parseInt(count),
        workoutType,
        duration: duration ? parseInt(duration) : null,
        refreshProfile: refreshProfile === 'true'
      }
    );

    logger.info('Personalized workouts generated', {
      userId: req.user.uid,
      count: recommendations.length,
      avgScore: recommendations.length > 0 ? 
        (recommendations.reduce((sum, r) => sum + r.score, 0) / recommendations.length).toFixed(2) : 0
    });

    res.json({
      success: true,
      data: {
        recommendations,
        personalizationLevel: 'high', // Based on user profile completeness
        generatedAt: new Date().toISOString()
      },
      message: recommendations.length > 0 ? 
        'Here are your personalized workout recommendations!' :
        'No personalized recommendations available. Try updating your profile.'
    });

  } catch (error) {
    next(error);
  }
});

// Get personalized nutrition recommendations
router.get('/nutrition', async (req, res, next) => {
  try {
    const recommendations = await personalizationService.generateNutritionRecommendations(req.user.uid);

    logger.info('Personalized nutrition recommendations generated', {
      userId: req.user.uid
    });

    res.json({
      success: true,
      data: recommendations,
      message: 'Nutrition recommendations personalized for your goals and preferences'
    });

  } catch (error) {
    next(error);
  }
});

// Get user's personalization profile
router.get('/profile', [
  query('refresh').optional().isBoolean()
], async (req, res, next) => {
  try {
    const refresh = req.query.refresh === 'true';
    
    const userProfile = await personalizationService.getUserProfile(req.user.uid, refresh);

    // Remove sensitive internal data before sending to client
    const publicProfile = {
      demographics: userProfile.demographics,
      preferences: userProfile.preferences,
      performance: userProfile.performance,
      goals: userProfile.goals,
      contextual: {
        recentActivity: userProfile.contextual.recentActivity,
        availableTime: userProfile.contextual.availableTime
      },
      profileCompleteness: personalizationService.calculateProfileCompleteness(userProfile)
    };

    res.json({
      success: true,
      data: publicProfile,
      lastUpdated: new Date().toISOString()
    });

  } catch (error) {
    next(error);
  }
});

// Premium feature: Advanced ML recommendations
router.get('/advanced-recommendations', premiumMiddleware, [
  query('type').optional().isIn(['workouts', 'nutrition', 'recovery', 'goals']),
  query('timeframe').optional().isIn(['week', 'month', 'quarter'])
], async (req, res, next) => {
  try {
    const {
      type = 'workouts',
      timeframe = 'week'
    } = req.query;

    const userProfile = await personalizationService.getUserProfile(req.user.uid);
    
    let recommendations = {};

    switch (type) {
      case 'workouts':
        recommendations = {
          immediate: await personalizationService.generateWorkoutRecommendations(req.user.uid, { count: 3 }),
          weekly: await generateWeeklyWorkoutPlan(userProfile),
          progressive: await generateProgressiveTrainingPlan(userProfile, timeframe)
        };
        break;
        
      case 'nutrition':
        recommendations = {
          daily: await personalizationService.generateNutritionRecommendations(req.user.uid),
          mealPlans: await generatePersonalizedMealPlans(userProfile, timeframe),
          supplementation: await generateSupplementationPlan(userProfile)
        };
        break;
        
      case 'recovery':
        recommendations = {
          sleep: await generateSleepRecommendations(userProfile),
          restDays: await generateRestDayRecommendations(userProfile),
          stressManagement: await generateStressManagementRecommendations(userProfile)
        };
        break;
        
      case 'goals':
        recommendations = {
          shortTerm: await generateShortTermGoals(userProfile),
          longTerm: await generateLongTermGoals(userProfile),
          milestones: await generateMilestoneRecommendations(userProfile)
        };
        break;
    }

    res.json({
      success: true,
      data: {
        type,
        timeframe,
        recommendations,
        confidence: calculateRecommendationConfidence(userProfile),
        generatedAt: new Date().toISOString()
      }
    });

  } catch (error) {
    next(error);
  }
});

// Provide feedback on recommendations
router.post('/feedback', [
  body('recommendationId').isString().withMessage('Recommendation ID is required'),
  body('feedback').isIn(['liked', 'disliked', 'completed', 'skipped']).withMessage('Invalid feedback'),
  body('rating').optional().isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5'),
  body('comments').optional().isString().isLength({ max: 500 }).withMessage('Comments must be less than 500 characters')
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      recommendationId,
      feedback,
      rating,
      comments = ''
    } = req.body;

    // Store feedback for ML model training
    const feedbackData = {
      userId: req.user.uid,
      recommendationId,
      feedback,
      rating,
      comments,
      timestamp: new Date()
    };

    const firestore = getFirestore();
    await firestore.collection('recommendation_feedback').add(feedbackData);

    // Update user profile based on feedback
    await updateUserProfileFromFeedback(req.user.uid, feedbackData);

    logger.info('Recommendation feedback received', {
      userId: req.user.uid,
      recommendationId,
      feedback,
      rating
    });

    res.json({
      success: true,
      message: 'Thank you for your feedback! This helps us improve your recommendations.'
    });

  } catch (error) {
    next(error);
  }
});

// Get personalization insights
router.get('/insights', async (req, res, next) => {
  try {
    const userProfile = await personalizationService.getUserProfile(req.user.uid);
    
    const insights = {
      profileStrengths: identifyProfileStrengths(userProfile),
      improvementAreas: identifyImprovementAreas(userProfile),
      personalizedTips: generatePersonalizedTips(userProfile),
      motivationalFactors: userProfile.behavioral.motivationFactors,
      riskFactors: identifyRiskFactors(userProfile),
      recommendations: {
        immediate: 'Focus on consistency with shorter workouts',
        weekly: 'Add one strength training session',
        monthly: 'Consider tracking your nutrition more closely'
      }
    };

    res.json({
      success: true,
      data: insights
    });

  } catch (error) {
    next(error);
  }
});

// Helper functions for advanced recommendations
async function generateWeeklyWorkoutPlan(userProfile) {
  // Generate a balanced weekly plan based on user preferences and goals
  return {
    monday: { type: 'strength', focus: 'upper_body', duration: 45 },
    tuesday: { type: 'cardio', focus: 'endurance', duration: 30 },
    wednesday: { type: 'rest', focus: 'recovery' },
    thursday: { type: 'strength', focus: 'lower_body', duration: 45 },
    friday: { type: 'hiit', focus: 'metabolic', duration: 25 },
    saturday: { type: 'flexibility', focus: 'mobility', duration: 30 },
    sunday: { type: 'active_recovery', focus: 'light_activity', duration: 20 }
  };
}

async function generateProgressiveTrainingPlan(userProfile, timeframe) {
  // Generate a progressive training plan that adapts over time
  const weeks = timeframe === 'week' ? 1 : timeframe === 'month' ? 4 : 12;
  
  return {
    phase: 'foundation_building',
    duration: `${weeks} weeks`,
    progression: {
      week1: { intensity: 'moderate', volume: 'medium', focus: 'form' },
      week2: { intensity: 'moderate', volume: 'medium', focus: 'consistency' },
      week3: { intensity: 'high', volume: 'medium', focus: 'challenge' },
      week4: { intensity: 'low', volume: 'low', focus: 'recovery' }
    },
    adaptations: 'Increase weights by 5% every 2 weeks, add 5 minutes to cardio sessions'
  };
}

async function generatePersonalizedMealPlans(userProfile, timeframe) {
  return {
    approach: 'balanced_macros',
    calorieCycling: false,
    mealFrequency: 4,
    specialConsiderations: ['post_workout_nutrition', 'hydration_focus']
  };
}

async function generateSupplementationPlan(userProfile) {
  const supplements = [];
  
  if (userProfile.goals.primary === 'muscle_gain') {
    supplements.push('Whey protein', 'Creatine monohydrate');
  }
  
  if (userProfile.performance.workoutFrequency > 5) {
    supplements.push('Magnesium', 'Vitamin D3');
  }
  
  return {
    recommended: supplements,
    timing: 'Post-workout for protein, daily for others',
    monitoring: 'Assess effectiveness after 6 weeks'
  };
}

async function generateSleepRecommendations(userProfile) {
  return {
    targetHours: 7.5,
    bedtimeWindow: '22:00-23:00',
    optimization: ['Cool room temperature', 'No screens 1 hour before bed', 'Consistent schedule']
  };
}

async function generateRestDayRecommendations(userProfile) {
  const workoutFreq = userProfile.performance.workoutFrequency;
  
  return {
    frequency: workoutFreq > 5 ? 2 : 1,
    activities: ['Light walking', 'Gentle yoga', 'Meditation'],
    importance: 'Essential for muscle recovery and preventing burnout'
  };
}

async function generateStressManagementRecommendations(userProfile) {
  return {
    techniques: ['Deep breathing exercises', '5-minute meditation', 'Progressive muscle relaxation'],
    frequency: 'Daily, especially post-workout',
    apps: ['Headspace', 'Calm', 'Insight Timer']
  };
}

async function generateShortTermGoals(userProfile) {
  return [
    'Complete 4 workouts this week',
    'Try one new exercise',
    'Track nutrition for 5 consecutive days'
  ];
}

async function generateLongTermGoals(userProfile) {
  return [
    'Increase strength by 20% in 3 months',
    'Run a 5K without stopping',
    'Maintain consistent workout routine for 6 months'
  ];
}

async function generateMilestoneRecommendations(userProfile) {
  return {
    '1_week': 'Complete first full week of recommended workouts',
    '1_month': 'Notice improvements in energy and mood',
    '3_months': 'Achieve measurable fitness improvements',
    '6_months': 'Establish sustainable long-term habits'
  };
}

function calculateRecommendationConfidence(userProfile) {
  const factors = [
    userProfile.performance.workoutFrequency > 0,
    Object.keys(userProfile.preferences.workoutTypes).length > 0,
    userProfile.demographics.age > 0,
    userProfile.goals.primary !== 'general_fitness'
  ];
  
  return factors.filter(Boolean).length / factors.length;
}

async function updateUserProfileFromFeedback(userId, feedback) {
  // Update user preferences based on feedback
  // This would integrate with the personalization service
  logger.info('Updating user profile from feedback', { userId, feedback: feedback.feedback });
}

function identifyProfileStrengths(userProfile) {
  const strengths = [];
  
  if (userProfile.performance.consistency > 70) {
    strengths.push('High workout consistency');
  }
  
  if (userProfile.performance.workoutFrequency > 3) {
    strengths.push('Good workout frequency');
  }
  
  if (Object.keys(userProfile.preferences.workoutTypes).length > 2) {
    strengths.push('Diverse workout preferences');
  }
  
  return strengths;
}

function identifyImprovementAreas(userProfile) {
  const areas = [];
  
  if (userProfile.performance.consistency < 50) {
    areas.push('Workout consistency');
  }
  
  if (userProfile.performance.avgWorkoutDuration < 20) {
    areas.push('Workout duration');
  }
  
  if (userProfile.behavioral.dropoffRisk === 'high') {
    areas.push('Motivation and adherence');
  }
  
  return areas;
}

function generatePersonalizedTips(userProfile) {
  const tips = [];
  
  if (userProfile.performance.workoutFrequency < 3) {
    tips.push('Start with 3 workouts per week for optimal progress');
  }
  
  if (userProfile.preferences.duration.preferred < 30) {
    tips.push('Even 20-minute workouts can be highly effective');
  }
  
  if (userProfile.goals.primary === 'weight_loss') {
    tips.push('Combine strength training with cardio for best results');
  }
  
  return tips;
}

function identifyRiskFactors(userProfile) {
  const risks = [];
  
  if (userProfile.behavioral.dropoffRisk === 'high') {
    risks.push('Risk of workout routine discontinuation');
  }
  
  if (userProfile.performance.workoutFrequency > 6) {
    risks.push('Risk of overtraining and burnout');
  }
  
  return risks;
}

module.exports = router;