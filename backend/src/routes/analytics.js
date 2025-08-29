const express = require('express');
const { query, validationResult } = require('express-validator');
const { getFirestore } = require('../config/firebase');
const { cache } = require('../config/redis');
const logger = require('../utils/logger');

const router = express.Router();

// Get user's personal analytics
router.get('/personal', [
  query('period').optional().isIn(['week', 'month', 'quarter', 'year']),
  query('metric').optional().isIn(['fitness', 'nutrition', 'progress', 'all'])
], async (req, res, next) => {
  try {
    const { period = 'month', metric = 'all' } = req.query;
    const userId = req.user.uid;
    
    const now = new Date();
    let startDate;
    
    switch (period) {
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case 'month':
        startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        break;
      case 'quarter':
        startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
        break;
      case 'year':
        startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
        break;
    }

    const firestore = getFirestore();
    const analytics = {};

    if (metric === 'fitness' || metric === 'all') {
      const [workoutsSnapshot, runsSnapshot] = await Promise.all([
        firestore
          .collection('users')
          .doc(userId)
          .collection('workout_completions')
          .where('completedAt', '>=', startDate)
          .get(),
        firestore
          .collection('users')
          .doc(userId)
          .collection('runs')
          .where('completedAt', '>=', startDate)
          .get()
      ]);

      const workouts = workoutsSnapshot.docs.map(doc => doc.data());
      const runs = runsSnapshot.docs.map(doc => doc.data());

      analytics.fitness = {
        summary: {
          totalWorkouts: workouts.length,
          totalRuns: runs.length,
          totalActivities: workouts.length + runs.length,
          totalDuration: workouts.reduce((sum, w) => sum + (w.duration || 0), 0) + 
                        runs.reduce((sum, r) => sum + (r.duration || 0), 0),
          totalDistance: runs.reduce((sum, r) => sum + (r.distance || 0), 0) / 1000, // km
          totalCaloriesBurned: [...workouts, ...runs].reduce((sum, activity) => 
            sum + (activity.caloriesBurned || activity.calories || 0), 0)
        },
        trends: {
          workoutsPerWeek: this.calculateWeeklyTrend(workouts, startDate, now),
          averageWorkoutDuration: workouts.length > 0 ? 
            workouts.reduce((sum, w) => sum + (w.duration || 0), 0) / workouts.length : 0,
          averageRunPace: runs.length > 0 ?
            runs.reduce((sum, r) => sum + (r.pace || 0), 0) / runs.length : 0,
          improvementScore: this.calculateImprovementScore(workouts, runs)
        }
      };
    }

    if (metric === 'nutrition' || metric === 'all') {
      const logsSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('daily_logs')
        .where('date', '>=', startDate.toISOString().split('T')[0])
        .get();

      const logs = logsSnapshot.docs.map(doc => doc.data());

      analytics.nutrition = {
        summary: {
          daysLogged: logs.filter(log => log.calories || log.water).length,
          totalCalories: logs.reduce((sum, log) => sum + (log.calories || 0), 0),
          averageCalories: logs.filter(log => log.calories).length > 0 ?
            logs.reduce((sum, log) => sum + (log.calories || 0), 0) / logs.filter(log => log.calories).length : 0,
          totalWater: logs.reduce((sum, log) => sum + (log.water || 0), 0),
          averageWater: logs.filter(log => log.water).length > 0 ?
            logs.reduce((sum, log) => sum + (log.water || 0), 0) / logs.filter(log => log.water).length : 0
        },
        trends: {
          calorieConsistency: this.calculateConsistencyScore(logs, 'calories'),
          waterConsistency: this.calculateConsistencyScore(logs, 'water'),
          weeklyPatterns: this.calculateWeeklyNutritionPatterns(logs)
        }
      };
    }

    if (metric === 'progress' || metric === 'all') {
      const progressLogs = logs || (await firestore
        .collection('users')
        .doc(userId)
        .collection('daily_logs')
        .where('date', '>=', startDate.toISOString().split('T')[0])
        .get()).docs.map(doc => doc.data());

      const weightLogs = progressLogs.filter(log => log.weight);
      const moodLogs = progressLogs.filter(log => log.mood);
      const sleepLogs = progressLogs.filter(log => log.sleep);

      analytics.progress = {
        weight: {
          totalEntries: weightLogs.length,
          currentWeight: weightLogs.length > 0 ? 
            weightLogs.sort((a, b) => new Date(b.date) - new Date(a.date))[0].weight : null,
          startWeight: weightLogs.length > 0 ?
            weightLogs.sort((a, b) => new Date(a.date) - new Date(b.date))[0].weight : null,
          weightChange: null, // Will be calculated below
          trend: this.calculateWeightTrend(weightLogs)
        },
        wellness: {
          averageMood: moodLogs.length > 0 ?
            moodLogs.reduce((sum, log) => sum + log.mood, 0) / moodLogs.length : null,
          averageSleep: sleepLogs.length > 0 ?
            sleepLogs.reduce((sum, log) => sum + log.sleep, 0) / sleepLogs.length : null,
          moodTrend: this.calculateTrend(moodLogs, 'mood'),
          sleepTrend: this.calculateTrend(sleepLogs, 'sleep')
        }
      };

      // Calculate weight change
      if (analytics.progress.weight.currentWeight && analytics.progress.weight.startWeight) {
        analytics.progress.weight.weightChange = 
          analytics.progress.weight.currentWeight - analytics.progress.weight.startWeight;
      }
    }

    // Get user stats from cache for additional context
    const userStats = await cache.get(`user_stats:${userId}`) || {};
    
    const response = {
      period,
      startDate: startDate.toISOString(),
      endDate: now.toISOString(),
      analytics,
      achievements: {
        currentStreak: userStats.workout_streak || 0,
        totalPoints: userStats.total_points || 0,
        totalAchievements: userStats.total_achievements || 0
      }
    };

    res.json({
      success: true,
      data: response
    });

  } catch (error) {
    next(error);
  }
});

// Get comparative analytics (compare with friends or community averages)
router.get('/comparative', [
  query('compareWith').optional().isIn(['friends', 'community', 'similar_users']),
  query('metric').optional().isIn(['workouts', 'distance', 'calories', 'consistency'])
], async (req, res, next) => {
  try {
    const { compareWith = 'community', metric = 'workouts' } = req.query;
    const userId = req.user.uid;
    
    // Get user's last 30 days data
    const last30Days = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const firestore = getFirestore();
    
    let userMetricValue = 0;
    let comparisonData = [];

    // Get user's metric value
    switch (metric) {
      case 'workouts':
        const userWorkouts = await firestore
          .collection('users')
          .doc(userId)
          .collection('workout_completions')
          .where('completedAt', '>=', last30Days)
          .get();
        userMetricValue = userWorkouts.size;
        break;
        
      case 'distance':
        const userRuns = await firestore
          .collection('users')
          .doc(userId)
          .collection('runs')
          .where('completedAt', '>=', last30Days)
          .get();
        userMetricValue = userRuns.docs.reduce((sum, doc) => 
          sum + (doc.data().distance || 0), 0) / 1000; // km
        break;
        
      case 'calories':
        const userLogs = await firestore
          .collection('users')
          .doc(userId)
          .collection('daily_logs')
          .where('date', '>=', last30Days.toISOString().split('T')[0])
          .get();
        const totalCaloriesBurned = userLogs.docs.reduce((sum, doc) => 
          sum + (doc.data().caloriesBurned || 0), 0);
        userMetricValue = totalCaloriesBurned;
        break;
        
      case 'consistency':
        const userActivityLogs = await firestore
          .collection('users')
          .doc(userId)
          .collection('daily_logs')
          .where('date', '>=', last30Days.toISOString().split('T')[0])
          .get();
        const activeDays = userActivityLogs.docs.filter(doc => 
          doc.data().calories || doc.data().water || doc.data().weight).length;
        userMetricValue = (activeDays / 30) * 100; // percentage
        break;
    }

    // Get comparison data based on compareWith parameter
    if (compareWith === 'friends') {
      // Get friends list
      const friendshipsSnapshot = await firestore
        .collection('friendships')
        .where('userId', '==', userId)
        .where('status', '==', 'accepted')
        .get();

      const friendIds = friendshipsSnapshot.docs.map(doc => doc.data().friendId);
      
      // For demonstration, create mock friend comparison data
      comparisonData = friendIds.slice(0, 10).map((friendId, index) => ({
        userId: friendId,
        name: `Friend ${index + 1}`,
        value: Math.floor(Math.random() * (userMetricValue * 2)) // Random comparison
      }));
    } else {
      // Community/similar users comparison (mock data)
      const communityAverage = userMetricValue * (0.8 + Math.random() * 0.4); // ±20% variation
      comparisonData = [
        { label: 'Community Average', value: communityAverage },
        { label: 'Top 10%', value: userMetricValue * 2.5 },
        { label: 'Top 25%', value: userMetricValue * 1.8 },
        { label: 'Bottom 25%', value: userMetricValue * 0.4 }
      ];
    }

    // Calculate user's percentile
    if (compareWith === 'community') {
      const communityAvg = comparisonData.find(d => d.label === 'Community Average')?.value || 0;
      const percentile = communityAvg > 0 ? 
        Math.min(95, Math.max(5, (userMetricValue / communityAvg) * 50)) : 50;
      
      comparisonData.push({ label: 'Your Percentile', value: percentile });
    }

    res.json({
      success: true,
      data: {
        metric,
        compareWith,
        userValue: userMetricValue,
        comparisons: comparisonData,
        insights: this.generateComparisonInsights(metric, userMetricValue, comparisonData)
      }
    });

  } catch (error) {
    next(error);
  }
});

// Get goal tracking analytics
router.get('/goals', async (req, res, next) => {
  try {
    const userId = req.user.uid;
    const firestore = getFirestore();
    
    // Get user's goals (stored in user preferences or separate collection)
    const userDoc = await firestore.collection('users').doc(userId).get();
    const userData = userDoc.data();
    
    // Default goals if none set
    const goals = userData.goals || {
      weeklyWorkouts: 4,
      weeklyDistance: 20, // km
      dailyCalories: 2000,
      dailyWater: 2000, // ml
      weeklyWeightLoss: 0.5 // kg
    };

    // Get current week's progress
    const startOfWeek = new Date();
    startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay());
    startOfWeek.setHours(0, 0, 0, 0);

    const [workoutsSnapshot, runsSnapshot, logsSnapshot] = await Promise.all([
      firestore
        .collection('users')
        .doc(userId)
        .collection('workout_completions')
        .where('completedAt', '>=', startOfWeek)
        .get(),
      firestore
        .collection('users')
        .doc(userId)
        .collection('runs')
        .where('completedAt', '>=', startOfWeek)
        .get(),
      firestore
        .collection('users')
        .doc(userId)
        .collection('daily_logs')
        .where('date', '>=', startOfWeek.toISOString().split('T')[0])
        .get()
    ]);

    const workouts = workoutsSnapshot.docs.map(doc => doc.data());
    const runs = runsSnapshot.docs.map(doc => doc.data());
    const logs = logsSnapshot.docs.map(doc => doc.data());

    // Calculate progress
    const progress = {
      weeklyWorkouts: {
        goal: goals.weeklyWorkouts,
        current: workouts.length,
        percentage: Math.min(100, (workouts.length / goals.weeklyWorkouts) * 100),
        onTrack: workouts.length >= (goals.weeklyWorkouts * (new Date().getDay() / 7))
      },
      weeklyDistance: {
        goal: goals.weeklyDistance,
        current: runs.reduce((sum, run) => sum + (run.distance || 0), 0) / 1000,
        percentage: Math.min(100, ((runs.reduce((sum, run) => sum + (run.distance || 0), 0) / 1000) / goals.weeklyDistance) * 100),
        onTrack: true // Simplified
      },
      dailyNutrition: {
        calorieGoal: goals.dailyCalories,
        waterGoal: goals.dailyWater,
        avgCalories: logs.filter(l => l.calories).length > 0 ?
          logs.reduce((sum, l) => sum + (l.calories || 0), 0) / logs.filter(l => l.calories).length : 0,
        avgWater: logs.filter(l => l.water).length > 0 ?
          logs.reduce((sum, l) => sum + (l.water || 0), 0) / logs.filter(l => l.water).length : 0
      }
    };

    // Generate insights and recommendations
    const insights = this.generateGoalInsights(progress, goals);

    res.json({
      success: true,
      data: {
        goals,
        progress,
        insights,
        weekPeriod: {
          start: startOfWeek.toISOString(),
          end: new Date(startOfWeek.getTime() + 6 * 24 * 60 * 60 * 1000).toISOString()
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

// Helper methods (would typically be in a separate utility class)
router.calculateWeeklyTrend = function(activities, startDate, endDate) {
  const weeks = Math.ceil((endDate - startDate) / (7 * 24 * 60 * 60 * 1000));
  const weeklyData = [];
  
  for (let i = 0; i < weeks; i++) {
    const weekStart = new Date(startDate.getTime() + i * 7 * 24 * 60 * 60 * 1000);
    const weekEnd = new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000);
    
    const weekActivities = activities.filter(activity => {
      const activityDate = new Date(activity.completedAt);
      return activityDate >= weekStart && activityDate < weekEnd;
    });
    
    weeklyData.push({
      week: `Week ${i + 1}`,
      count: weekActivities.length,
      startDate: weekStart.toISOString().split('T')[0]
    });
  }
  
  return weeklyData;
};

router.calculateImprovementScore = function(workouts, runs) {
  // Simple improvement score based on recent vs older activities
  const totalActivities = workouts.length + runs.length;
  if (totalActivities < 4) return 0;
  
  const sortedActivities = [...workouts, ...runs]
    .sort((a, b) => new Date(a.completedAt) - new Date(b.completedAt));
  
  const firstHalf = sortedActivities.slice(0, Math.floor(totalActivities / 2));
  const secondHalf = sortedActivities.slice(Math.floor(totalActivities / 2));
  
  const firstHalfAvgDuration = firstHalf.reduce((sum, a) => sum + (a.duration || 0), 0) / firstHalf.length;
  const secondHalfAvgDuration = secondHalf.reduce((sum, a) => sum + (a.duration || 0), 0) / secondHalf.length;
  
  return firstHalfAvgDuration > 0 ? 
    ((secondHalfAvgDuration - firstHalfAvgDuration) / firstHalfAvgDuration * 100).toFixed(1) : 0;
};

router.calculateConsistencyScore = function(logs, field) {
  const totalDays = logs.length;
  const daysWithData = logs.filter(log => log[field]).length;
  return totalDays > 0 ? Math.round((daysWithData / totalDays) * 100) : 0;
};

router.calculateWeeklyNutritionPatterns = function(logs) {
  const dayPatterns = {
    'Sunday': [], 'Monday': [], 'Tuesday': [], 'Wednesday': [], 
    'Thursday': [], 'Friday': [], 'Saturday': []
  };
  
  logs.forEach(log => {
    const dayOfWeek = new Date(log.date).toLocaleDateString('en-US', { weekday: 'long' });
    if (log.calories) {
      dayPatterns[dayOfWeek].push(log.calories);
    }
  });
  
  const averages = {};
  Object.keys(dayPatterns).forEach(day => {
    averages[day] = dayPatterns[day].length > 0 ?
      dayPatterns[day].reduce((sum, cal) => sum + cal, 0) / dayPatterns[day].length : 0;
  });
  
  return averages;
};

router.calculateWeightTrend = function(weightLogs) {
  if (weightLogs.length < 2) return 'insufficient_data';
  
  const sortedLogs = weightLogs.sort((a, b) => new Date(a.date) - new Date(b.date));
  const firstWeight = sortedLogs[0].weight;
  const lastWeight = sortedLogs[sortedLogs.length - 1].weight;
  
  const change = lastWeight - firstWeight;
  
  if (Math.abs(change) < 0.5) return 'stable';
  return change > 0 ? 'increasing' : 'decreasing';
};

router.calculateTrend = function(logs, field) {
  if (logs.length < 2) return 'insufficient_data';
  
  const values = logs.map(log => log[field]).sort((a, b) => a - b);
  const firstHalf = values.slice(0, Math.floor(values.length / 2));
  const secondHalf = values.slice(Math.floor(values.length / 2));
  
  const firstAvg = firstHalf.reduce((sum, val) => sum + val, 0) / firstHalf.length;
  const secondAvg = secondHalf.reduce((sum, val) => sum + val, 0) / secondHalf.length;
  
  const change = secondAvg - firstAvg;
  if (Math.abs(change) < 0.1) return 'stable';
  return change > 0 ? 'improving' : 'declining';
};

router.generateComparisonInsights = function(metric, userValue, comparisons) {
  const insights = [];
  
  if (metric === 'workouts') {
    if (userValue > 15) {
      insights.push('You are very active! Keep up the excellent work.');
    } else if (userValue > 8) {
      insights.push('Great consistency! You are above average in workout frequency.');
    } else {
      insights.push('Try to increase your workout frequency for better results.');
    }
  }
  
  return insights;
};

router.generateGoalInsights = function(progress, goals) {
  const insights = [];
  
  if (progress.weeklyWorkouts.percentage >= 100) {
    insights.push('🎉 Congratulations! You have already achieved your weekly workout goal.');
  } else if (progress.weeklyWorkouts.onTrack) {
    insights.push('✅ You are on track to meet your weekly workout goal.');
  } else {
    insights.push('⚠️ You may need to increase your workout frequency to meet your weekly goal.');
  }
  
  return insights;
};

module.exports = router;