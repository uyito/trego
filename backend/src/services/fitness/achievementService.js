const logger = require('../../utils/logger');
const { cache } = require('../../config/redis');
const { getFirestore } = require('../../config/firebase');

class AchievementService {
  constructor() {
    // Define all available achievements
    this.achievements = {
      // Streak achievements
      'first_workout': {
        id: 'first_workout',
        title: 'First Steps',
        description: 'Complete your first workout',
        icon: '🏃‍♂️',
        category: 'getting_started',
        points: 10,
        type: 'single',
        criteria: { workouts_completed: 1 }
      },
      'workout_streak_7': {
        id: 'workout_streak_7',
        title: 'Weekly Warrior',
        description: 'Complete workouts for 7 days straight',
        icon: '🔥',
        category: 'consistency',
        points: 50,
        type: 'streak',
        criteria: { workout_streak: 7 }
      },
      'workout_streak_30': {
        id: 'workout_streak_30',
        title: 'Monthly Master',
        description: 'Complete workouts for 30 days straight',
        icon: '💪',
        category: 'consistency',
        points: 200,
        type: 'streak',
        criteria: { workout_streak: 30 }
      },
      'workout_streak_100': {
        id: 'workout_streak_100',
        title: 'Centurion',
        description: 'Complete workouts for 100 days straight',
        icon: '👑',
        category: 'consistency',
        points: 500,
        type: 'streak',
        criteria: { workout_streak: 100 }
      },

      // Distance achievements
      'first_5k': {
        id: 'first_5k',
        title: '5K Finisher',
        description: 'Complete your first 5K run',
        icon: '🏃‍♀️',
        category: 'running',
        points: 30,
        type: 'single',
        criteria: { single_run_distance: 5000 }
      },
      'first_10k': {
        id: 'first_10k',
        title: '10K Champion',
        description: 'Complete your first 10K run',
        icon: '🏆',
        category: 'running',
        points: 60,
        type: 'single',
        criteria: { single_run_distance: 10000 }
      },
      'marathon_ready': {
        id: 'marathon_ready',
        title: 'Marathon Ready',
        description: 'Complete a 42.2K run',
        icon: '🎖️',
        category: 'running',
        points: 300,
        type: 'single',
        criteria: { single_run_distance: 42200 }
      },
      'total_100k': {
        id: 'total_100k',
        title: 'Century Runner',
        description: 'Run a total of 100K',
        icon: '💯',
        category: 'running',
        points: 150,
        type: 'cumulative',
        criteria: { total_distance: 100000 }
      },
      'total_1000k': {
        id: 'total_1000k',
        title: 'Ultra Runner',
        description: 'Run a total of 1000K',
        icon: '🚀',
        category: 'running',
        points: 1000,
        type: 'cumulative',
        criteria: { total_distance: 1000000 }
      },

      // Nutrition achievements
      'calorie_tracker_7': {
        id: 'calorie_tracker_7',
        title: 'Calorie Counter',
        description: 'Track calories for 7 days straight',
        icon: '📊',
        category: 'nutrition',
        points: 30,
        type: 'streak',
        criteria: { calorie_tracking_streak: 7 }
      },
      'water_goal_30': {
        id: 'water_goal_30',
        title: 'Hydration Hero',
        description: 'Meet water goal for 30 days',
        icon: '💧',
        category: 'nutrition',
        points: 100,
        type: 'streak',
        criteria: { water_goal_streak: 30 }
      },
      'macro_balance_14': {
        id: 'macro_balance_14',
        title: 'Macro Master',
        description: 'Stay within macro targets for 14 days',
        icon: '⚖️',
        category: 'nutrition',
        points: 80,
        type: 'streak',
        criteria: { macro_balance_streak: 14 }
      },

      // Weight management achievements
      'first_weigh_in': {
        id: 'first_weigh_in',
        title: 'Getting Started',
        description: 'Record your first weigh-in',
        icon: '⚖️',
        category: 'weight',
        points: 10,
        type: 'single',
        criteria: { weigh_ins: 1 }
      },
      'weight_loss_5kg': {
        id: 'weight_loss_5kg',
        title: 'Fantastic Five',
        description: 'Lose 5kg from starting weight',
        icon: '📉',
        category: 'weight',
        points: 100,
        type: 'progress',
        criteria: { weight_lost: 5 }
      },
      'weight_loss_10kg': {
        id: 'weight_loss_10kg',
        title: 'Perfect Ten',
        description: 'Lose 10kg from starting weight',
        icon: '🎯',
        category: 'weight',
        points: 250,
        type: 'progress',
        criteria: { weight_lost: 10 }
      },
      'weight_maintenance_30': {
        id: 'weight_maintenance_30',
        title: 'Steady State',
        description: 'Maintain weight within 1kg for 30 days',
        icon: '🎚️',
        category: 'weight',
        points: 150,
        type: 'streak',
        criteria: { weight_maintenance_streak: 30 }
      },

      // Recipe achievements
      'recipe_explorer': {
        id: 'recipe_explorer',
        title: 'Recipe Explorer',
        description: 'Generate your first AI recipe',
        icon: '👨‍🍳',
        category: 'recipes',
        points: 20,
        type: 'single',
        criteria: { recipes_generated: 1 }
      },
      'recipe_master': {
        id: 'recipe_master',
        title: 'Recipe Master',
        description: 'Generate 50 AI recipes',
        icon: '🍳',
        category: 'recipes',
        points: 200,
        type: 'cumulative',
        criteria: { recipes_generated: 50 }
      },

      // Social achievements
      'first_share': {
        id: 'first_share',
        title: 'Social Butterfly',
        description: 'Share your first achievement',
        icon: '📱',
        category: 'social',
        points: 15,
        type: 'single',
        criteria: { achievements_shared: 1 }
      },
      'motivator': {
        id: 'motivator',
        title: 'Motivator',
        description: 'Encourage 10 friends',
        icon: '🤝',
        category: 'social',
        points: 75,
        type: 'cumulative',
        criteria: { friends_encouraged: 10 }
      },

      // Special achievements
      'early_bird': {
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Complete 10 workouts before 7 AM',
        icon: '🌅',
        category: 'special',
        points: 100,
        type: 'cumulative',
        criteria: { early_morning_workouts: 10 }
      },
      'night_owl': {
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Complete 10 workouts after 9 PM',
        icon: '🦉',
        category: 'special',
        points: 100,
        type: 'cumulative',
        criteria: { late_night_workouts: 10 }
      },
      'all_weather': {
        id: 'all_weather',
        title: 'All Weather Warrior',
        description: 'Work out in all weather conditions',
        icon: '⛈️',
        category: 'special',
        points: 150,
        type: 'collection',
        criteria: { weather_types: ['sunny', 'rainy', 'snowy', 'cloudy', 'windy'] }
      }
    };

    this.categories = {
      'getting_started': { name: 'Getting Started', icon: '🌱', color: '#4CAF50' },
      'consistency': { name: 'Consistency', icon: '🔥', color: '#FF9800' },
      'running': { name: 'Running', icon: '🏃‍♂️', color: '#2196F3' },
      'nutrition': { name: 'Nutrition', icon: '🥗', color: '#8BC34A' },
      'weight': { name: 'Weight Management', icon: '⚖️', color: '#9C27B0' },
      'recipes': { name: 'Recipes', icon: '👨‍🍳', color: '#FF5722' },
      'social': { name: 'Social', icon: '👥', color: '#E91E63' },
      'special': { name: 'Special', icon: '⭐', color: '#FFC107' }
    };
  }

  // Check and award achievements for a user based on their activity
  async checkAchievements(userId, activityData) {
    try {
      const firestore = getFirestore();
      
      // Get user's current achievements
      const userAchievementsDoc = await firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc('summary')
        .get();

      const currentAchievements = userAchievementsDoc.exists 
        ? userAchievementsDoc.data().earned || []
        : [];

      const newAchievements = [];

      // Check each achievement
      for (const [achievementId, achievement] of Object.entries(this.achievements)) {
        // Skip if already earned
        if (currentAchievements.includes(achievementId)) {
          continue;
        }

        const earned = await this.evaluateAchievement(achievement, activityData, userId);
        
        if (earned) {
          newAchievements.push({
            id: achievementId,
            ...achievement,
            earnedAt: new Date().toISOString()
          });
        }
      }

      // Save new achievements
      if (newAchievements.length > 0) {
        const updatedEarned = [...currentAchievements, ...newAchievements.map(a => a.id)];
        const totalPoints = this.calculateTotalPoints(updatedEarned);
        
        await firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('summary')
          .set({
            earned: updatedEarned,
            totalPoints,
            lastChecked: new Date(),
            totalAchievements: updatedEarned.length
          }, { merge: true });

        // Save individual achievement records
        for (const achievement of newAchievements) {
          await firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc(achievement.id)
            .set(achievement);
        }

        logger.info('New achievements earned', {
          userId,
          achievements: newAchievements.map(a => a.id),
          totalPoints
        });
      }

      return newAchievements;
    } catch (error) {
      logger.error('Achievement check failed', { userId, error: error.message });
      throw error;
    }
  }

  // Evaluate if a specific achievement has been earned
  async evaluateAchievement(achievement, activityData, userId) {
    try {
      const { criteria, type } = achievement;

      switch (type) {
        case 'single':
          return this.evaluateSingleAchievement(criteria, activityData);
        
        case 'streak':
          return this.evaluateStreakAchievement(criteria, activityData);
        
        case 'cumulative':
          return await this.evaluateCumulativeAchievement(criteria, activityData, userId);
        
        case 'progress':
          return await this.evaluateProgressAchievement(criteria, activityData, userId);
        
        case 'collection':
          return this.evaluateCollectionAchievement(criteria, activityData);
        
        default:
          return false;
      }
    } catch (error) {
      logger.error('Achievement evaluation failed', {
        achievementId: achievement.id,
        error: error.message
      });
      return false;
    }
  }

  evaluateSingleAchievement(criteria, activityData) {
    for (const [key, threshold] of Object.entries(criteria)) {
      if (!activityData[key] || activityData[key] < threshold) {
        return false;
      }
    }
    return true;
  }

  evaluateStreakAchievement(criteria, activityData) {
    for (const [key, threshold] of Object.entries(criteria)) {
      const currentStreak = activityData[key] || 0;
      if (currentStreak < threshold) {
        return false;
      }
    }
    return true;
  }

  async evaluateCumulativeAchievement(criteria, activityData, userId) {
    try {
      // Get historical data from cache or database
      const historicalKey = `user_stats:${userId}`;
      const historicalData = await cache.get(historicalKey) || {};

      for (const [key, threshold] of Object.entries(criteria)) {
        const currentValue = activityData[key] || 0;
        const historicalValue = historicalData[key] || 0;
        const totalValue = currentValue + historicalValue;
        
        if (totalValue < threshold) {
          return false;
        }
      }
      return true;
    } catch (error) {
      logger.error('Cumulative achievement evaluation failed', error);
      return false;
    }
  }

  async evaluateProgressAchievement(criteria, activityData, userId) {
    try {
      // Get starting values
      const firestore = getFirestore();
      const startingDataDoc = await firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc('baseline')
        .get();

      if (!startingDataDoc.exists) {
        return false;
      }

      const startingData = startingDataDoc.data();

      for (const [key, threshold] of Object.entries(criteria)) {
        const currentValue = activityData[key] || 0;
        const startingValue = startingData[key] || 0;
        const progress = Math.abs(startingValue - currentValue);
        
        if (progress < threshold) {
          return false;
        }
      }
      return true;
    } catch (error) {
      logger.error('Progress achievement evaluation failed', error);
      return false;
    }
  }

  evaluateCollectionAchievement(criteria, activityData) {
    for (const [key, requiredItems] of Object.entries(criteria)) {
      const userItems = activityData[key] || [];
      const hasAllItems = requiredItems.every(item => userItems.includes(item));
      
      if (!hasAllItems) {
        return false;
      }
    }
    return true;
  }

  calculateTotalPoints(achievementIds) {
    return achievementIds.reduce((total, id) => {
      const achievement = this.achievements[id];
      return total + (achievement ? achievement.points : 0);
    }, 0);
  }

  // Get user's achievement summary
  async getUserAchievements(userId) {
    try {
      const firestore = getFirestore();
      
      // Get summary
      const summaryDoc = await firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc('summary')
        .get();

      const summary = summaryDoc.exists ? summaryDoc.data() : {
        earned: [],
        totalPoints: 0,
        totalAchievements: 0
      };

      // Get detailed achievements
      const achievementsCollection = await firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .get();

      const earnedDetails = [];
      achievementsCollection.docs.forEach(doc => {
        if (doc.id !== 'summary') {
          earnedDetails.push({ id: doc.id, ...doc.data() });
        }
      });

      // Get available achievements by category
      const availableByCategory = {};
      const earnedByCategory = {};

      for (const [id, achievement] of Object.entries(this.achievements)) {
        const category = achievement.category;
        
        if (!availableByCategory[category]) {
          availableByCategory[category] = [];
          earnedByCategory[category] = [];
        }
        
        availableByCategory[category].push(achievement);
        
        if (summary.earned.includes(id)) {
          earnedByCategory[category].push(achievement);
        }
      }

      return {
        summary,
        earned: earnedDetails.sort((a, b) => new Date(b.earnedAt) - new Date(a.earnedAt)),
        categories: Object.keys(this.categories).map(categoryId => ({
          id: categoryId,
          ...this.categories[categoryId],
          available: availableByCategory[categoryId] || [],
          earned: earnedByCategory[categoryId] || [],
          progress: {
            earned: (earnedByCategory[categoryId] || []).length,
            total: (availableByCategory[categoryId] || []).length
          }
        }))
      };
    } catch (error) {
      logger.error('Get user achievements failed', { userId, error: error.message });
      throw error;
    }
  }

  // Get achievement leaderboard
  async getLeaderboard(category = null, limit = 100) {
    try {
      // This would typically query a database for all users' achievement data
      // For now, return mock leaderboard data
      const mockLeaderboard = [
        { userId: 'user1', name: 'John Doe', totalPoints: 1250, totalAchievements: 15, avatar: '👨' },
        { userId: 'user2', name: 'Jane Smith', totalPoints: 1100, totalAchievements: 13, avatar: '👩' },
        { userId: 'user3', name: 'Mike Johnson', totalPoints: 950, totalAchievements: 11, avatar: '👨‍💼' },
        { userId: 'user4', name: 'Sarah Wilson', totalPoints: 800, totalAchievements: 9, avatar: '👩‍💻' },
        { userId: 'user5', name: 'David Brown', totalPoints: 650, totalAchievements: 7, avatar: '👨‍🎓' }
      ];

      return {
        category: category || 'all',
        leaderboard: mockLeaderboard.slice(0, limit),
        lastUpdated: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Get leaderboard failed', { error: error.message });
      throw error;
    }
  }

  // Share achievement
  async shareAchievement(userId, achievementId, platform = 'general') {
    try {
      const achievement = this.achievements[achievementId];
      
      if (!achievement) {
        throw new Error('Achievement not found');
      }

      // Check if user has earned this achievement
      const firestore = getFirestore();
      const achievementDoc = await firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc(achievementId)
        .get();

      if (!achievementDoc.exists) {
        throw new Error('Achievement not earned by user');
      }

      // Generate share content
      const shareContent = {
        text: `🎉 I just earned the "${achievement.title}" achievement in Trego! ${achievement.description} ${achievement.icon}`,
        hashtags: ['#TregoFitness', '#Achievement', '#FitnessGoals'],
        url: `https://trego.app/achievements/${achievementId}`,
        image: `https://trego.app/api/achievements/${achievementId}/badge.png`
      };

      // Track share event
      await this.trackAchievementShare(userId, achievementId, platform);

      logger.info('Achievement shared', { userId, achievementId, platform });

      return shareContent;
    } catch (error) {
      logger.error('Share achievement failed', { userId, achievementId, error: error.message });
      throw error;
    }
  }

  async trackAchievementShare(userId, achievementId, platform) {
    try {
      const firestore = getFirestore();
      
      await firestore
        .collection('users')
        .doc(userId)
        .collection('shares')
        .add({
          achievementId,
          platform,
          sharedAt: new Date(),
          type: 'achievement'
        });

      // Update user stats for social achievements
      const statsKey = `user_stats:${userId}`;
      const currentStats = await cache.get(statsKey) || {};
      currentStats.achievements_shared = (currentStats.achievements_shared || 0) + 1;
      await cache.set(statsKey, currentStats, 86400 * 7); // 7 days

    } catch (error) {
      logger.error('Track achievement share failed', error);
    }
  }

  // Get next achievable goals for motivation
  async getNextGoals(userId) {
    try {
      const userAchievements = await this.getUserAchievements(userId);
      const earnedIds = userAchievements.summary.earned;
      
      // Get user's current stats to see what they're close to achieving
      const statsKey = `user_stats:${userId}`;
      const userStats = await cache.get(statsKey) || {};
      
      const nextGoals = [];
      
      for (const [id, achievement] of Object.entries(this.achievements)) {
        if (earnedIds.includes(id)) continue;
        
        // Calculate progress towards this achievement
        const progress = this.calculateAchievementProgress(achievement, userStats, userId);
        
        if (progress.percentage > 0) {
          nextGoals.push({
            ...achievement,
            progress
          });
        }
      }

      // Sort by progress percentage (closest to completion first)
      nextGoals.sort((a, b) => b.progress.percentage - a.progress.percentage);

      return nextGoals.slice(0, 5); // Return top 5 next goals
    } catch (error) {
      logger.error('Get next goals failed', { userId, error: error.message });
      throw error;
    }
  }

  calculateAchievementProgress(achievement, userStats, userId) {
    const { criteria, type } = achievement;
    
    // This is a simplified progress calculation
    // In a real implementation, you'd need more sophisticated logic based on achievement type
    
    let totalProgress = 0;
    let criteriaCount = 0;
    
    for (const [key, threshold] of Object.entries(criteria)) {
      const currentValue = userStats[key] || 0;
      const progress = Math.min(currentValue / threshold, 1);
      totalProgress += progress;
      criteriaCount++;
    }
    
    const percentage = criteriaCount > 0 ? (totalProgress / criteriaCount) * 100 : 0;
    
    return {
      percentage: Math.round(percentage),
      description: this.getProgressDescription(achievement, userStats)
    };
  }

  getProgressDescription(achievement, userStats) {
    const { criteria } = achievement;
    const [key, threshold] = Object.entries(criteria)[0]; // Get first criteria
    const currentValue = userStats[key] || 0;
    const remaining = Math.max(threshold - currentValue, 0);
    
    return `${remaining} more to go!`;
  }

  // Get all available achievements
  getAllAchievements() {
    return Object.values(this.achievements).map(achievement => ({
      ...achievement,
      category: this.categories[achievement.category]
    }));
  }
}

module.exports = new AchievementService();