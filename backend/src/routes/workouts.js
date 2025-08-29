const express = require('express');
const { body, query, validationResult } = require('express-validator');
const workoutService = require('../services/fitness/workoutService');
const achievementService = require('../services/fitness/achievementService');
const { premiumMiddleware } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Validation middleware
const validateWorkoutGeneration = [
  body('fitnessLevel')
    .optional()
    .isIn(['beginner', 'intermediate', 'advanced'])
    .withMessage('Invalid fitness level'),
  body('goals')
    .optional()
    .isArray()
    .withMessage('Goals must be an array'),
  body('duration')
    .isInt({ min: 5, max: 120 })
    .withMessage('Duration must be between 5 and 120 minutes'),
  body('equipment')
    .optional()
    .isArray()
    .withMessage('Equipment must be an array'),
  body('preferences')
    .optional()
    .isArray()
    .withMessage('Preferences must be an array'),
  body('focusAreas')
    .optional()
    .isArray()
    .withMessage('Focus areas must be an array')
];

const validateWorkoutCompletion = [
  body('workoutId')
    .optional()
    .isString()
    .withMessage('Workout ID must be a string'),
  body('duration')
    .isInt({ min: 1, max: 300 })
    .withMessage('Duration must be between 1 and 300 minutes'),
  body('exercises')
    .isArray({ min: 1 })
    .withMessage('At least one exercise must be completed'),
  body('exercises.*.name')
    .isString()
    .withMessage('Exercise name is required'),
  body('exercises.*.completed')
    .isBoolean()
    .withMessage('Exercise completion status is required'),
  body('caloriesBurned')
    .optional()
    .isInt({ min: 0, max: 2000 })
    .withMessage('Calories burned must be between 0 and 2000'),
  body('difficulty')
    .optional()
    .isIn(['easy', 'medium', 'hard'])
    .withMessage('Invalid difficulty level'),
  body('notes')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Notes must be less than 500 characters')
];

// Generate personalized workout
router.post('/generate', validateWorkoutGeneration, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      fitnessLevel = 'beginner',
      goals = ['general_fitness'],
      duration = 30,
      equipment = ['bodyweight'],
      preferences = [],
      focusAreas = []
    } = req.body;

    const workout = await workoutService.generateWorkout({
      fitnessLevel,
      goals,
      duration,
      equipment,
      preferences,
      focusAreas,
      userId: req.user.uid
    });

    logger.info('Workout generated via API', {
      userId: req.user.uid,
      duration,
      fitnessLevel,
      exerciseCount: workout.exercises?.length || 0
    });

    res.json({
      success: true,
      workout,
      generatedAt: new Date().toISOString()
    });

  } catch (error) {
    next(error);
  }
});

// Track workout completion
router.post('/complete', validateWorkoutCompletion, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      workoutId,
      duration,
      exercises,
      caloriesBurned = 0,
      notes = '',
      difficulty = 'medium'
    } = req.body;

    const completionId = await workoutService.trackWorkoutCompletion({
      userId: req.user.uid,
      workoutId,
      duration,
      exercises,
      caloriesBurned,
      notes,
      difficulty
    });

    // Check for new achievements
    const activityData = {
      workouts_completed: 1, // This completion
      single_run_distance: 0, // Not applicable for general workouts
      workout_streak: 1 // Will be calculated in achievement service
    };

    const newAchievements = await achievementService.checkAchievements(
      req.user.uid,
      activityData
    );

    logger.info('Workout completion tracked', {
      userId: req.user.uid,
      completionId,
      duration,
      newAchievements: newAchievements.length
    });

    res.json({
      success: true,
      completionId,
      message: 'Workout completed successfully!',
      newAchievements,
      stats: {
        duration,
        caloriesBurned,
        exercisesCompleted: exercises.filter(ex => ex.completed).length,
        totalExercises: exercises.length
      }
    });

  } catch (error) {
    next(error);
  }
});

// Get workout history
router.get('/history', [
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  query('offset')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Offset must be a non-negative integer'),
  query('dateFrom')
    .optional()
    .isISO8601()
    .withMessage('Date from must be a valid ISO date'),
  query('dateTo')
    .optional()
    .isISO8601()
    .withMessage('Date to must be a valid ISO date')
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
      limit = 20,
      offset = 0,
      dateFrom,
      dateTo
    } = req.query;

    const history = await workoutService.getWorkoutHistory(req.user.uid, {
      limit: parseInt(limit),
      offset: parseInt(offset),
      dateFrom,
      dateTo
    });

    res.json({
      success: true,
      data: history
    });

  } catch (error) {
    next(error);
  }
});

// Get workout statistics
router.get('/stats', async (req, res, next) => {
  try {
    const stats = await workoutService.getWorkoutStatistics(req.user.uid);

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    next(error);
  }
});

// Get recommended workouts
router.get('/recommendations', async (req, res, next) => {
  try {
    const recommendations = await workoutService.getRecommendedWorkouts(req.user.uid);

    res.json({
      success: true,
      data: recommendations,
      message: recommendations.length > 0 
        ? 'Here are some workouts we recommend for you!'
        : 'Keep up the great work! Try exploring different workout types.'
    });

  } catch (error) {
    next(error);
  }
});

// Search exercises
router.get('/exercises/search', [
  query('q')
    .optional()
    .isString()
    .isLength({ min: 1, max: 50 })
    .withMessage('Query must be between 1 and 50 characters'),
  query('category')
    .optional()
    .isIn(['strength', 'cardio', 'flexibility', 'core'])
    .withMessage('Invalid category'),
  query('equipment')
    .optional()
    .isIn(['bodyweight', 'dumbbells', 'barbell', 'resistance_bands', 'kettlebell'])
    .withMessage('Invalid equipment'),
  query('difficulty')
    .optional()
    .isIn(['beginner', 'intermediate', 'advanced'])
    .withMessage('Invalid difficulty'),
  query('targetMuscle')
    .optional()
    .isString()
    .withMessage('Target muscle must be a string')
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { q, category, equipment, difficulty, targetMuscle } = req.query;

    const exercises = workoutService.searchExercises(q, {
      category,
      equipment,
      difficulty,
      targetMuscle
    });

    res.json({
      success: true,
      data: {
        exercises,
        total: exercises.length,
        query: { q, category, equipment, difficulty, targetMuscle }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Get exercise details
router.get('/exercises/:exerciseId', async (req, res, next) => {
  try {
    const { exerciseId } = req.params;
    
    const exercise = workoutService.getExerciseInfo(exerciseId);
    
    if (!exercise) {
      return res.status(404).json({
        error: 'Exercise not found',
        message: 'The specified exercise does not exist in our database'
      });
    }

    res.json({
      success: true,
      data: exercise
    });

  } catch (error) {
    next(error);
  }
});

// Get filter options for exercise search
router.get('/exercises/filters/options', (req, res) => {
  try {
    const options = workoutService.getFilterOptions();

    res.json({
      success: true,
      data: options
    });

  } catch (error) {
    next(error);
  }
});

// Premium feature: Advanced workout analytics
router.get('/analytics/detailed', premiumMiddleware, async (req, res, next) => {
  try {
    const { period = '30' } = req.query;
    const days = parseInt(period);

    if (days > 365) {
      return res.status(400).json({
        error: 'Invalid period',
        message: 'Maximum period is 365 days'
      });
    }

    const dateFrom = new Date();
    dateFrom.setDate(dateFrom.getDate() - days);

    const history = await workoutService.getWorkoutHistory(req.user.uid, {
      limit: 1000,
      dateFrom: dateFrom.toISOString()
    });

    // Calculate detailed analytics
    const workouts = history.workouts;
    const analytics = {
      period: `${days} days`,
      summary: {
        totalWorkouts: workouts.length,
        totalDuration: workouts.reduce((sum, w) => sum + w.duration, 0),
        totalCalories: workouts.reduce((sum, w) => sum + (w.caloriesBurned || 0), 0),
        averageRating: workouts.filter(w => w.rating).reduce((sum, w, _, arr) => sum + w.rating / arr.length, 0) || 0
      },
      trends: {
        workoutsPerWeek: this.calculateWeeklyTrends(workouts),
        mostActiveDay: this.getMostActiveDay(workouts),
        preferredDifficulty: this.getPreferredDifficulty(workouts)
      },
      progression: {
        durationTrend: this.calculateDurationTrend(workouts),
        consistencyScore: this.calculateConsistencyScore(workouts, days)
      }
    };

    res.json({
      success: true,
      data: analytics
    });

  } catch (error) {
    next(error);
  }
});

// Helper method for weekly trends (would be part of the service in real implementation)
function calculateWeeklyTrends(workouts) {
  const weeks = {};
  workouts.forEach(workout => {
    const weekStart = new Date(workout.completedAt);
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());
    const weekKey = weekStart.toISOString().split('T')[0];
    weeks[weekKey] = (weeks[weekKey] || 0) + 1;
  });
  
  return Object.entries(weeks).map(([week, count]) => ({ week, count }));
}

function getMostActiveDay(workouts) {
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const dayCounts = {};
  
  workouts.forEach(workout => {
    const day = new Date(workout.completedAt).getDay();
    const dayName = days[day];
    dayCounts[dayName] = (dayCounts[dayName] || 0) + 1;
  });
  
  return Object.entries(dayCounts).sort(([,a], [,b]) => b - a)[0]?.[0] || 'None';
}

function getPreferredDifficulty(workouts) {
  const difficulties = {};
  workouts.forEach(workout => {
    const diff = workout.difficulty || 'medium';
    difficulties[diff] = (difficulties[diff] || 0) + 1;
  });
  
  return Object.entries(difficulties).sort(([,a], [,b]) => b - a)[0]?.[0] || 'medium';
}

function calculateDurationTrend(workouts) {
  if (workouts.length < 2) return 'stable';
  
  const recent = workouts.slice(0, Math.min(5, workouts.length));
  const older = workouts.slice(-Math.min(5, workouts.length));
  
  const recentAvg = recent.reduce((sum, w) => sum + w.duration, 0) / recent.length;
  const olderAvg = older.reduce((sum, w) => sum + w.duration, 0) / older.length;
  
  const difference = recentAvg - olderAvg;
  
  if (difference > 5) return 'increasing';
  if (difference < -5) return 'decreasing';
  return 'stable';
}

function calculateConsistencyScore(workouts, days) {
  if (workouts.length === 0) return 0;
  
  const workoutDays = new Set(
    workouts.map(w => new Date(w.completedAt).toISOString().split('T')[0])
  );
  
  return Math.round((workoutDays.size / days) * 100);
}

module.exports = router;