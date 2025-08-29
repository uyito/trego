const express = require('express');
const { body, query, validationResult } = require('express-validator');
const achievementService = require('../services/fitness/achievementService');
const logger = require('../utils/logger');

const router = express.Router();

// Get user's achievements
router.get('/', async (req, res, next) => {
  try {
    const achievements = await achievementService.getUserAchievements(req.user.uid);

    res.json({
      success: true,
      data: achievements
    });

  } catch (error) {
    next(error);
  }
});

// Check and award new achievements based on activity
router.post('/check', [
  body('activityData')
    .isObject()
    .withMessage('Activity data must be an object'),
  body('activityData.workouts_completed')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Workouts completed must be a non-negative integer'),
  body('activityData.workout_streak')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Workout streak must be a non-negative integer'),
  body('activityData.total_distance')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Total distance must be a non-negative number'),
  body('activityData.single_run_distance')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Single run distance must be a non-negative number'),
  body('activityData.calorie_tracking_streak')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Calorie tracking streak must be a non-negative integer'),
  body('activityData.water_goal_streak')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Water goal streak must be a non-negative integer'),
  body('activityData.weight_lost')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Weight lost must be a non-negative number'),
  body('activityData.recipes_generated')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Recipes generated must be a non-negative integer')
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { activityData } = req.body;

    const newAchievements = await achievementService.checkAchievements(
      req.user.uid,
      activityData
    );

    logger.info('Achievement check completed', {
      userId: req.user.uid,
      newAchievements: newAchievements.length,
      achievementIds: newAchievements.map(a => a.id)
    });

    res.json({
      success: true,
      newAchievements,
      message: newAchievements.length > 0 
        ? `Congratulations! You've earned ${newAchievements.length} new achievement${newAchievements.length > 1 ? 's' : ''}!`
        : 'No new achievements this time. Keep going!'
    });

  } catch (error) {
    next(error);
  }
});

// Get next achievable goals for motivation
router.get('/next-goals', async (req, res, next) => {
  try {
    const nextGoals = await achievementService.getNextGoals(req.user.uid);

    res.json({
      success: true,
      data: nextGoals,
      message: nextGoals.length > 0 
        ? 'Here are your next achievement goals!'
        : 'Great job! You\'re close to earning some amazing achievements.'
    });

  } catch (error) {
    next(error);
  }
});

// Get all available achievements
router.get('/all', async (req, res, next) => {
  try {
    const allAchievements = achievementService.getAllAchievements();

    // Group by category
    const categorizedAchievements = {};
    allAchievements.forEach(achievement => {
      const categoryId = achievement.category.id || 'uncategorized';
      if (!categorizedAchievements[categoryId]) {
        categorizedAchievements[categoryId] = {
          category: achievement.category,
          achievements: []
        };
      }
      categorizedAchievements[categoryId].achievements.push(achievement);
    });

    res.json({
      success: true,
      data: {
        total: allAchievements.length,
        categories: Object.keys(categorizedAchievements).length,
        achievements: categorizedAchievements
      }
    });

  } catch (error) {
    next(error);
  }
});

// Get achievement leaderboard
router.get('/leaderboard', [
  query('category')
    .optional()
    .isIn(['getting_started', 'consistency', 'running', 'nutrition', 'weight', 'recipes', 'social', 'special'])
    .withMessage('Invalid category'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100')
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { category, limit = 50 } = req.query;

    const leaderboard = await achievementService.getLeaderboard(category, parseInt(limit));

    res.json({
      success: true,
      data: leaderboard
    });

  } catch (error) {
    next(error);
  }
});

// Share achievement on social media
router.post('/share/:achievementId', [
  body('platform')
    .optional()
    .isIn(['twitter', 'facebook', 'instagram', 'general'])
    .withMessage('Invalid platform')
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { achievementId } = req.params;
    const { platform = 'general' } = req.body;

    const shareContent = await achievementService.shareAchievement(
      req.user.uid,
      achievementId,
      platform
    );

    res.json({
      success: true,
      data: shareContent,
      message: 'Achievement shared successfully!'
    });

  } catch (error) {
    if (error.message === 'Achievement not found') {
      return res.status(404).json({
        error: 'Achievement not found',
        message: 'The specified achievement does not exist'
      });
    }
    
    if (error.message === 'Achievement not earned by user') {
      return res.status(403).json({
        error: 'Achievement not earned',
        message: 'You can only share achievements you have earned'
      });
    }
    
    next(error);
  }
});

// Get specific achievement details
router.get('/:achievementId', async (req, res, next) => {
  try {
    const { achievementId } = req.params;
    
    const achievement = achievementService.achievements[achievementId];
    if (!achievement) {
      return res.status(404).json({
        error: 'Achievement not found',
        message: 'The specified achievement does not exist'
      });
    }

    // Check if user has earned this achievement
    const userAchievements = await achievementService.getUserAchievements(req.user.uid);
    const earned = userAchievements.earned.find(a => a.id === achievementId);

    res.json({
      success: true,
      data: {
        ...achievement,
        earned: !!earned,
        earnedAt: earned?.earnedAt || null,
        category: achievementService.categories[achievement.category]
      }
    });

  } catch (error) {
    next(error);
  }
});

// Generate achievement badge/certificate (for sharing)
router.get('/:achievementId/badge', async (req, res, next) => {
  try {
    const { achievementId } = req.params;
    
    const achievement = achievementService.achievements[achievementId];
    if (!achievement) {
      return res.status(404).json({
        error: 'Achievement not found'
      });
    }

    // Check if user has earned this achievement
    const userAchievements = await achievementService.getUserAchievements(req.user.uid);
    const earned = userAchievements.earned.find(a => a.id === achievementId);
    
    if (!earned) {
      return res.status(403).json({
        error: 'Achievement not earned',
        message: 'You can only generate badges for achievements you have earned'
      });
    }

    // In a real implementation, you would generate an actual image badge
    // For now, return badge data that could be used to generate an image on the client
    const badgeData = {
      achievement: {
        title: achievement.title,
        description: achievement.description,
        icon: achievement.icon,
        category: achievementService.categories[achievement.category]
      },
      user: {
        name: req.user.name || 'Trego User',
        earnedAt: earned.earnedAt
      },
      badge: {
        backgroundColor: achievementService.categories[achievement.category].color,
        template: 'certificate',
        size: '800x600'
      }
    };

    res.json({
      success: true,
      data: badgeData,
      shareUrl: `https://trego.app/achievements/${achievementId}/badge.png`
    });

  } catch (error) {
    next(error);
  }
});

// Get user's achievement statistics
router.get('/stats/summary', async (req, res, next) => {
  try {
    const userAchievements = await achievementService.getUserAchievements(req.user.uid);
    
    // Calculate statistics
    const stats = {
      total: {
        earned: userAchievements.summary.totalAchievements,
        available: Object.keys(achievementService.achievements).length,
        points: userAchievements.summary.totalPoints
      },
      categories: userAchievements.categories.map(cat => ({
        id: cat.id,
        name: cat.name,
        icon: cat.icon,
        earned: cat.progress.earned,
        total: cat.progress.total,
        percentage: cat.progress.total > 0 ? Math.round((cat.progress.earned / cat.progress.total) * 100) : 0
      })),
      recent: userAchievements.earned
        .slice(0, 5)
        .map(a => ({
          id: a.id,
          title: a.title,
          icon: a.icon,
          earnedAt: a.earnedAt,
          points: a.points
        })),
      streaks: {
        longest: 30, // This would be calculated from actual data
        current: 7   // This would be calculated from actual data
      }
    };

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;