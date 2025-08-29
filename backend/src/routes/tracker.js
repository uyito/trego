const express = require('express');
const { body, query, validationResult } = require('express-validator');
const { getFirestore } = require('../config/firebase');
const { cache } = require('../config/redis');
const achievementService = require('../services/fitness/achievementService');
const logger = require('../utils/logger');

const router = express.Router();

// Validation middleware
const validateDailyLog = [
  body('date')
    .isISO8601()
    .withMessage('Date must be in ISO format (YYYY-MM-DD)'),
  body('calories')
    .optional()
    .isInt({ min: 0, max: 10000 })
    .withMessage('Calories must be between 0 and 10000'),
  body('water')
    .optional()
    .isInt({ min: 0, max: 10000 })
    .withMessage('Water intake must be between 0 and 10000ml'),
  body('weight')
    .optional()
    .isFloat({ min: 30, max: 300 })
    .withMessage('Weight must be between 30 and 300'),
  body('steps')
    .optional()
    .isInt({ min: 0, max: 100000 })
    .withMessage('Steps must be between 0 and 100000'),
  body('sleep')
    .optional()
    .isFloat({ min: 0, max: 24 })
    .withMessage('Sleep hours must be between 0 and 24'),
  body('mood')
    .optional()
    .isInt({ min: 1, max: 10 })
    .withMessage('Mood must be between 1 and 10'),
  body('notes')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Notes must be less than 500 characters')
];

const validateRunTracking = [
  body('distance')
    .isFloat({ min: 0, max: 1000 })
    .withMessage('Distance must be between 0 and 1000 km'),
  body('duration')
    .isInt({ min: 0, max: 86400 })
    .withMessage('Duration must be between 0 and 86400 seconds'),
  body('calories')
    .optional()
    .isInt({ min: 0, max: 5000 })
    .withMessage('Calories must be between 0 and 5000'),
  body('averagePace')
    .optional()
    .isFloat({ min: 0, max: 1800 })
    .withMessage('Average pace must be between 0 and 1800 seconds per km'),
  body('route')
    .optional()
    .isArray()
    .withMessage('Route must be an array of coordinates'),
  body('weather')
    .optional()
    .isObject()
    .withMessage('Weather must be an object'),
  body('notes')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Notes must be less than 500 characters')
];

// Save daily log entry
router.post('/daily-log', validateDailyLog, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      date,
      calories,
      water,
      weight,
      steps,
      sleep,
      mood,
      notes
    } = req.body;

    const firestore = getFirestore();
    const logData = {
      userId: req.user.uid,
      date,
      calories: calories || null,
      water: water || null,
      weight: weight || null,
      steps: steps || null,
      sleep: sleep || null,
      mood: mood || null,
      notes: notes || '',
      updatedAt: new Date(),
      createdAt: new Date()
    };

    // Save to Firestore
    await firestore
      .collection('users')
      .doc(req.user.uid)
      .collection('daily_logs')
      .doc(date)
      .set(logData, { merge: true });

    // Update user statistics for achievements
    await updateUserStats(req.user.uid, {
      calories_logged: calories ? 1 : 0,
      water_logged: water ? 1 : 0,
      weight_logged: weight ? 1 : 0,
      steps_logged: steps || 0
    });

    // Check for achievements
    const activityData = {
      weigh_ins: weight ? 1 : 0,
      calorie_tracking_streak: 1, // Will be calculated properly in achievement service
      water_goal_streak: water && water >= 2000 ? 1 : 0 // Assuming 2L goal
    };

    const newAchievements = await achievementService.checkAchievements(
      req.user.uid,
      activityData
    );

    logger.info('Daily log saved', {
      userId: req.user.uid,
      date,
      fieldsLogged: Object.keys(logData).filter(key => logData[key] !== null && key !== 'userId').length
    });

    res.json({
      success: true,
      message: 'Daily log saved successfully',
      newAchievements,
      loggedAt: new Date().toISOString()
    });

  } catch (error) {
    next(error);
  }
});

// Get daily log for specific date
router.get('/daily-log/:date', async (req, res, next) => {
  try {
    const { date } = req.params;

    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return res.status(400).json({
        error: 'Invalid date format',
        message: 'Date must be in YYYY-MM-DD format'
      });
    }

    const firestore = getFirestore();
    const doc = await firestore
      .collection('users')
      .doc(req.user.uid)
      .collection('daily_logs')
      .doc(date)
      .get();

    if (!doc.exists) {
      return res.json({
        success: true,
        data: null,
        message: 'No log found for this date'
      });
    }

    const logData = doc.data();
    const { createdAt, updatedAt, ...cleanData } = logData;

    res.json({
      success: true,
      data: {
        ...cleanData,
        createdAt: createdAt?.toDate?.()?.toISOString() || createdAt,
        updatedAt: updatedAt?.toDate?.()?.toISOString() || updatedAt
      }
    });

  } catch (error) {
    next(error);
  }
});

// Track run/exercise session
router.post('/runs', validateRunTracking, async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      distance,
      duration,
      calories = 0,
      averagePace,
      route = [],
      weather = {},
      notes = ''
    } = req.body;

    const firestore = getFirestore();
    const runData = {
      userId: req.user.uid,
      distance: distance * 1000, // Convert to meters
      duration,
      calories,
      averagePace,
      route,
      weather,
      notes,
      completedAt: new Date(),
      pace: duration > 0 ? (duration / 60) / distance : 0, // minutes per km
      speed: duration > 0 ? (distance * 3600) / duration : 0 // km/h
    };

    const docRef = await firestore
      .collection('users')
      .doc(req.user.uid)
      .collection('runs')
      .add(runData);

    // Update user running statistics
    await updateRunningStats(req.user.uid, distance * 1000, duration);

    // Check for running achievements
    const activityData = {
      single_run_distance: distance * 1000, // meters
      total_distance: distance * 1000, // This will be added to cumulative total
      workouts_completed: 1
    };

    const newAchievements = await achievementService.checkAchievements(
      req.user.uid,
      activityData
    );

    logger.info('Run tracked', {
      userId: req.user.uid,
      runId: docRef.id,
      distance: distance * 1000,
      duration,
      pace: runData.pace
    });

    res.json({
      success: true,
      runId: docRef.id,
      message: 'Run tracked successfully!',
      newAchievements,
      summary: {
        distance: `${distance} km`,
        duration: `${Math.floor(duration / 60)}:${(duration % 60).toString().padStart(2, '0')}`,
        pace: `${Math.floor(runData.pace)}:${Math.floor((runData.pace % 1) * 60).toString().padStart(2, '0')} /km`,
        speed: `${runData.speed.toFixed(1)} km/h`,
        calories: `${calories} kcal`
      }
    });

  } catch (error) {
    next(error);
  }
});

// Get runs history
router.get('/runs', [
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('offset').optional().isInt({ min: 0 }),
  query('dateFrom').optional().isISO8601(),
  query('dateTo').optional().isISO8601()
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

    const firestore = getFirestore();
    let query = firestore
      .collection('users')
      .doc(req.user.uid)
      .collection('runs')
      .orderBy('completedAt', 'desc');

    if (dateFrom) {
      query = query.where('completedAt', '>=', new Date(dateFrom));
    }
    
    if (dateTo) {
      query = query.where('completedAt', '<=', new Date(dateTo));
    }

    const snapshot = await query
      .offset(parseInt(offset))
      .limit(parseInt(limit))
      .get();

    const runs = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        distance: data.distance / 1000, // Convert back to km
        completedAt: data.completedAt.toDate().toISOString()
      };
    });

    res.json({
      success: true,
      data: {
        runs,
        hasMore: snapshot.size === parseInt(limit),
        total: snapshot.size
      }
    });

  } catch (error) {
    next(error);
  }
});

// Get weekly summary
router.get('/weekly-summary', [
  query('date').optional().isISO8601()
], async (req, res, next) => {
  try {
    const { date } = req.query;
    const targetDate = date ? new Date(date) : new Date();
    
    // Calculate week boundaries
    const startOfWeek = new Date(targetDate);
    startOfWeek.setDate(targetDate.getDate() - targetDate.getDay());
    startOfWeek.setHours(0, 0, 0, 0);
    
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6);
    endOfWeek.setHours(23, 59, 59, 999);

    const firestore = getFirestore();
    
    // Get daily logs for the week
    const logsSnapshot = await firestore
      .collection('users')
      .doc(req.user.uid)
      .collection('daily_logs')
      .where('date', '>=', startOfWeek.toISOString().split('T')[0])
      .where('date', '<=', endOfWeek.toISOString().split('T')[0])
      .get();

    // Get runs for the week
    const runsSnapshot = await firestore
      .collection('users')
      .doc(req.user.uid)
      .collection('runs')
      .where('completedAt', '>=', startOfWeek)
      .where('completedAt', '<=', endOfWeek)
      .get();

    // Get workout completions for the week
    const workoutsSnapshot = await firestore
      .collection('users')
      .doc(req.user.uid)
      .collection('workout_completions')
      .where('completedAt', '>=', startOfWeek)
      .where('completedAt', '<=', endOfWeek)
      .get();

    const logs = logsSnapshot.docs.map(doc => doc.data());
    const runs = runsSnapshot.docs.map(doc => doc.data());
    const workouts = workoutsSnapshot.docs.map(doc => doc.data());

    // Calculate summary statistics
    const summary = {
      week: {
        start: startOfWeek.toISOString().split('T')[0],
        end: endOfWeek.toISOString().split('T')[0]
      },
      nutrition: {
        totalCalories: logs.reduce((sum, log) => sum + (log.calories || 0), 0),
        avgCalories: logs.length > 0 ? Math.round(logs.reduce((sum, log) => sum + (log.calories || 0), 0) / logs.length) : 0,
        totalWater: logs.reduce((sum, log) => sum + (log.water || 0), 0),
        avgWater: logs.length > 0 ? Math.round(logs.reduce((sum, log) => sum + (log.water || 0), 0) / logs.length) : 0,
        daysLogged: logs.filter(log => log.calories || log.water).length
      },
      fitness: {
        totalWorkouts: workouts.length,
        totalWorkoutDuration: workouts.reduce((sum, w) => sum + (w.duration || 0), 0),
        totalRuns: runs.length,
        totalRunDistance: runs.reduce((sum, run) => sum + (run.distance || 0), 0) / 1000, // km
        totalRunDuration: runs.reduce((sum, run) => sum + (run.duration || 0), 0),
        totalCaloriesBurned: [...workouts, ...runs].reduce((sum, activity) => sum + (activity.caloriesBurned || activity.calories || 0), 0)
      },
      health: {
        weighIns: logs.filter(log => log.weight).length,
        avgSleep: logs.filter(log => log.sleep).length > 0 
          ? logs.reduce((sum, log) => sum + (log.sleep || 0), 0) / logs.filter(log => log.sleep).length 
          : 0,
        avgMood: logs.filter(log => log.mood).length > 0 
          ? logs.reduce((sum, log) => sum + (log.mood || 0), 0) / logs.filter(log => log.mood).length 
          : 0,
        totalSteps: logs.reduce((sum, log) => sum + (log.steps || 0), 0)
      },
      dailyBreakdown: generateDailyBreakdown(logs, runs, workouts, startOfWeek)
    };

    res.json({
      success: true,
      data: summary
    });

  } catch (error) {
    next(error);
  }
});

// Get dashboard overview (current streaks, goals, etc.)
router.get('/dashboard', async (req, res, next) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const firestore = getFirestore();

    // Get today's log
    const todayLog = await firestore
      .collection('users')
      .doc(req.user.uid)
      .collection('daily_logs')
      .doc(today)
      .get();

    // Get recent activity (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const recentLogsSnapshot = await firestore
      .collection('users')
      .doc(req.user.uid)
      .collection('daily_logs')
      .where('date', '>=', sevenDaysAgo.toISOString().split('T')[0])
      .get();

    const recentRunsSnapshot = await firestore
      .collection('users')
      .doc(req.user.uid)
      .collection('runs')
      .where('completedAt', '>=', sevenDaysAgo)
      .limit(5)
      .orderBy('completedAt', 'desc')
      .get();

    // Get user stats from cache
    const statsKey = `user_stats:${req.user.uid}`;
    const userStats = await cache.get(statsKey) || {};

    const recentLogs = recentLogsSnapshot.docs.map(doc => doc.data());
    const recentRuns = recentRunsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      distance: doc.data().distance / 1000, // Convert to km
      completedAt: doc.data().completedAt.toDate().toISOString()
    }));

    // Calculate streaks
    const streaks = calculateStreaks(recentLogs);

    const dashboard = {
      today: {
        date: today,
        logged: todayLog.exists,
        data: todayLog.exists ? todayLog.data() : null
      },
      streaks: {
        workout: userStats.workout_streak || 0,
        calorie: streaks.calorie,
        water: streaks.water,
        weigh: streaks.weigh
      },
      recentActivity: {
        runs: recentRuns,
        totalWeeklyRuns: recentRuns.length,
        totalWeeklyDistance: recentRuns.reduce((sum, run) => sum + run.distance, 0)
      },
      goals: {
        weekly: {
          workouts: {
            target: 4,
            current: userStats.workouts_this_week || 0,
            percentage: Math.round(((userStats.workouts_this_week || 0) / 4) * 100)
          },
          runs: {
            target: 3,
            current: recentRuns.length,
            percentage: Math.round((recentRuns.length / 3) * 100)
          }
        }
      },
      quickStats: {
        totalWorkouts: userStats.workouts_completed || 0,
        totalRunDistance: (userStats.total_distance || 0) / 1000, // km
        currentStreak: Math.max(userStats.workout_streak || 0, streaks.calorie, streaks.water)
      }
    };

    res.json({
      success: true,
      data: dashboard
    });

  } catch (error) {
    next(error);
  }
});

// Helper functions
async function updateUserStats(userId, stats) {
  try {
    const statsKey = `user_stats:${userId}`;
    const currentStats = await cache.get(statsKey) || {};

    // Update stats
    Object.keys(stats).forEach(key => {
      currentStats[key] = (currentStats[key] || 0) + stats[key];
    });

    // Update last activity date
    currentStats.last_activity_date = new Date().toISOString().split('T')[0];

    await cache.set(statsKey, currentStats, 86400 * 7); // Cache for 7 days
    return currentStats;
  } catch (error) {
    logger.error('Update user stats failed', { userId, error: error.message });
    return {};
  }
}

async function updateRunningStats(userId, distance, duration) {
  try {
    const statsKey = `user_stats:${userId}`;
    const currentStats = await cache.get(statsKey) || {};

    currentStats.total_distance = (currentStats.total_distance || 0) + distance;
    currentStats.total_run_duration = (currentStats.total_run_duration || 0) + duration;
    currentStats.runs_completed = (currentStats.runs_completed || 0) + 1;
    currentStats.last_run_date = new Date().toISOString().split('T')[0];

    await cache.set(statsKey, currentStats, 86400 * 7); // Cache for 7 days
    return currentStats;
  } catch (error) {
    logger.error('Update running stats failed', { userId, error: error.message });
    return {};
  }
}

function calculateStreaks(logs) {
  const sortedLogs = logs.sort((a, b) => new Date(b.date) - new Date(a.date));
  
  return {
    calorie: calculateStreak(sortedLogs, 'calories'),
    water: calculateStreak(sortedLogs, 'water'),
    weigh: calculateStreak(sortedLogs, 'weight')
  };
}

function calculateStreak(logs, field) {
  let streak = 0;
  const today = new Date().toISOString().split('T')[0];
  let currentDate = today;

  for (const log of logs) {
    if (log.date === currentDate && log[field]) {
      streak++;
      const date = new Date(currentDate);
      date.setDate(date.getDate() - 1);
      currentDate = date.toISOString().split('T')[0];
    } else if (log.date === currentDate) {
      // Missing data for this date, break streak
      break;
    }
  }

  return streak;
}

function generateDailyBreakdown(logs, runs, workouts, startOfWeek) {
  const breakdown = [];
  
  for (let i = 0; i < 7; i++) {
    const date = new Date(startOfWeek);
    date.setDate(startOfWeek.getDate() + i);
    const dateStr = date.toISOString().split('T')[0];
    
    const dayLog = logs.find(log => log.date === dateStr);
    const dayRuns = runs.filter(run => {
      const runDate = new Date(run.completedAt).toISOString().split('T')[0];
      return runDate === dateStr;
    });
    const dayWorkouts = workouts.filter(workout => {
      const workoutDate = new Date(workout.completedAt).toISOString().split('T')[0];
      return workoutDate === dateStr;
    });

    breakdown.push({
      date: dateStr,
      dayOfWeek: date.toLocaleDateString('en-US', { weekday: 'long' }),
      calories: dayLog?.calories || 0,
      water: dayLog?.water || 0,
      weight: dayLog?.weight || null,
      runs: dayRuns.length,
      workouts: dayWorkouts.length,
      totalActivities: dayRuns.length + dayWorkouts.length
    });
  }

  return breakdown;
}

module.exports = router;