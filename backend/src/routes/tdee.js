const express = require('express');
const { body, validationResult } = require('express-validator');
const tdeeService = require('../services/nutrition/tdeeService');
const logger = require('../utils/logger');

const router = express.Router();

// Validation middleware for TDEE calculation
const validateTDEECalculation = [
  body('age')
    .isInt({ min: 13, max: 120 })
    .withMessage('Age must be between 13 and 120'),
  body('gender')
    .isIn(['male', 'female'])
    .withMessage('Gender must be male or female'),
  body('weight')
    .isFloat({ min: 30, max: 300 })
    .withMessage('Weight must be between 30 and 300'),
  body('height')
    .isFloat({ min: 100, max: 250 })
    .withMessage('Height must be between 100 and 250'),
  body('activityLevel')
    .isIn(['sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active'])
    .withMessage('Invalid activity level'),
  body('goal')
    .isIn(['lose_weight_fast', 'lose_weight', 'lose_weight_slow', 'maintain_weight', 'gain_weight_slow', 'gain_weight', 'gain_muscle'])
    .withMessage('Invalid goal'),
  body('weightUnit')
    .optional()
    .isIn(['kg', 'lbs'])
    .withMessage('Weight unit must be kg or lbs'),
  body('heightUnit')
    .optional()
    .isIn(['cm', 'in', 'ft'])
    .withMessage('Height unit must be cm, in, or ft'),
  body('macroTemplate')
    .optional()
    .isIn(['balanced', 'high_protein', 'low_carb', 'keto', 'mediterranean'])
    .withMessage('Invalid macro template')
];

const validateProgressTracking = [
  body('weight')
    .isFloat({ min: 30, max: 300 })
    .withMessage('Weight must be between 30 and 300'),
  body('bodyFat')
    .optional()
    .isFloat({ min: 3, max: 50 })
    .withMessage('Body fat percentage must be between 3 and 50'),
  body('measurements')
    .optional()
    .isObject()
    .withMessage('Measurements must be an object'),
  body('measurements.waist')
    .optional()
    .isFloat({ min: 50, max: 150 })
    .withMessage('Waist measurement must be between 50 and 150 cm'),
  body('measurements.chest')
    .optional()
    .isFloat({ min: 60, max: 200 })
    .withMessage('Chest measurement must be between 60 and 200 cm'),
  body('measurements.arms')
    .optional()
    .isFloat({ min: 15, max: 60 })
    .withMessage('Arm measurement must be between 15 and 60 cm'),
  body('measurements.thighs')
    .optional()
    .isFloat({ min: 30, max: 100 })
    .withMessage('Thigh measurement must be between 30 and 100 cm')
];

// Calculate complete TDEE with recommendations
router.post('/calculate', validateTDEECalculation, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      age,
      gender,
      weight,
      height,
      activityLevel,
      goal,
      weightUnit = 'kg',
      heightUnit = 'cm',
      macroTemplate = 'balanced'
    } = req.body;

    const results = await tdeeService.calculateComplete({
      age,
      gender,
      weight,
      height,
      activityLevel,
      goal,
      weightUnit,
      heightUnit,
      macroTemplate,
      userId: req.user.uid
    });

    logger.info('TDEE calculated via API', {
      userId: req.user.uid,
      bmr: results.bmr,
      tdee: results.tdee,
      goal
    });

    res.json({
      success: true,
      data: results,
      calculatedAt: new Date().toISOString()
    });

  } catch (error) {
    next(error);
  }
});

// Get BMR only (simpler calculation)
router.post('/bmr', [
  body('age').isInt({ min: 13, max: 120 }),
  body('gender').isIn(['male', 'female']),
  body('weight').isFloat({ min: 30, max: 300 }),
  body('height').isFloat({ min: 100, max: 250 }),
  body('weightUnit').optional().isIn(['kg', 'lbs']),
  body('heightUnit').optional().isIn(['cm', 'in', 'ft'])
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
      age,
      gender,
      weight,
      height,
      weightUnit = 'kg',
      heightUnit = 'cm'
    } = req.body;

    const bmr = tdeeService.calculateBMR({
      age,
      gender,
      weight,
      height,
      weightUnit,
      heightUnit
    });

    res.json({
      success: true,
      bmr,
      metadata: {
        age,
        gender,
        weight: { value: weight, unit: weightUnit },
        height: { value: height, unit: heightUnit }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Track progress over time
router.post('/progress', validateProgressTracking, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { weight, bodyFat, measurements = {} } = req.body;

    const result = await tdeeService.trackProgress({
      userId: req.user.uid,
      weight,
      bodyFat,
      measurements
    });

    logger.info('Progress tracked', {
      userId: req.user.uid,
      weight,
      bodyFat,
      entryCount: result.progress.length
    });

    res.json({
      success: true,
      message: 'Progress tracked successfully',
      data: result
    });

  } catch (error) {
    next(error);
  }
});

// Get progress history
router.get('/progress', async (req, res, next) => {
  try {
    const { limit = 30, days = 90 } = req.query;
    
    const progressKey = `tdee_progress:${req.user.uid}`;
    const { cache } = require('../config/redis');
    const allProgress = await cache.get(progressKey) || [];

    // Filter by date range
    const cutoffDate = Date.now() - (days * 24 * 60 * 60 * 1000);
    const filteredProgress = allProgress
      .filter(entry => entry.timestamp >= cutoffDate)
      .slice(-limit);

    // Calculate summary statistics
    let summary = null;
    if (filteredProgress.length > 0) {
      const weights = filteredProgress.map(p => p.weight);
      const bodyFats = filteredProgress.filter(p => p.bodyFat).map(p => p.bodyFat);

      summary = {
        totalEntries: filteredProgress.length,
        dateRange: {
          start: new Date(filteredProgress[0].timestamp).toISOString(),
          end: new Date(filteredProgress[filteredProgress.length - 1].timestamp).toISOString()
        },
        weight: {
          current: weights[weights.length - 1],
          min: Math.min(...weights),
          max: Math.max(...weights),
          average: Math.round((weights.reduce((a, b) => a + b, 0) / weights.length) * 10) / 10,
          change: weights.length > 1 ? Math.round((weights[weights.length - 1] - weights[0]) * 10) / 10 : 0
        }
      };

      if (bodyFats.length > 0) {
        summary.bodyFat = {
          current: bodyFats[bodyFats.length - 1],
          min: Math.min(...bodyFats),
          max: Math.max(...bodyFats),
          average: Math.round((bodyFats.reduce((a, b) => a + b, 0) / bodyFats.length) * 10) / 10,
          change: bodyFats.length > 1 ? Math.round((bodyFats[bodyFats.length - 1] - bodyFats[0]) * 10) / 10 : 0
        };
      }
    }

    res.json({
      success: true,
      data: {
        progress: filteredProgress,
        summary
      }
    });

  } catch (error) {
    next(error);
  }
});

// Get available options for form dropdowns
router.get('/options', (req, res) => {
  try {
    const options = tdeeService.getOptions();

    res.json({
      success: true,
      options
    });

  } catch (error) {
    next(error);
  }
});

// Calculate macro targets for specific calorie goal
router.post('/macros', [
  body('targetCalories').isInt({ min: 800, max: 5000 }),
  body('macroTemplate').optional().isIn(['balanced', 'high_protein', 'low_carb', 'keto', 'mediterranean'])
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { targetCalories, macroTemplate = 'balanced' } = req.body;

    const macros = tdeeService.calculateMacros({
      targetCalories,
      macroTemplate
    });

    res.json({
      success: true,
      data: {
        targetCalories,
        macroTemplate,
        macros
      }
    });

  } catch (error) {
    next(error);
  }
});

// Compare different scenarios
router.post('/compare', [
  body('scenarios')
    .isArray({ min: 2, max: 5 })
    .withMessage('Must provide 2-5 scenarios to compare'),
  body('scenarios.*').custom((scenario) => {
    const required = ['age', 'gender', 'weight', 'height', 'activityLevel', 'goal'];
    for (const field of required) {
      if (!scenario[field]) {
        throw new Error(`Missing field ${field} in scenario`);
      }
    }
    return true;
  })
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { scenarios } = req.body;
    const comparisons = [];

    for (let i = 0; i < scenarios.length; i++) {
      const scenario = scenarios[i];
      try {
        const result = await tdeeService.calculateComplete({
          ...scenario,
          userId: req.user.uid
        });
        
        comparisons.push({
          id: i + 1,
          name: scenario.name || `Scenario ${i + 1}`,
          ...result
        });
      } catch (error) {
        logger.warn(`Scenario ${i + 1} calculation failed:`, error.message);
        comparisons.push({
          id: i + 1,
          name: scenario.name || `Scenario ${i + 1}`,
          error: error.message
        });
      }
    }

    res.json({
      success: true,
      comparisons,
      comparedAt: new Date().toISOString()
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;