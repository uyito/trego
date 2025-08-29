const tf = require('@tensorflow/tfjs-node');
const natural = require('natural');
const logger = require('../../utils/logger');
const { cache } = require('../../config/redis');
const { getFirestore } = require('../../config/firebase');

class PersonalizationService {
  constructor() {
    this.model = null;
    this.initialized = false;
    this.userProfiles = new Map();
    
    // Content-based filtering weights
    this.featureWeights = {
      workoutType: 0.3,
      duration: 0.25,
      difficulty: 0.2,
      equipment: 0.15,
      targetMuscles: 0.1
    };

    // Initialize TF.js model for recommendations
    this.initializeModel();
  }

  async initializeModel() {
    try {
      // Create a simple neural network for workout recommendations
      this.model = tf.sequential({
        layers: [
          tf.layers.dense({
            inputShape: [15], // User features + workout features
            units: 32,
            activation: 'relu'
          }),
          tf.layers.dropout({ rate: 0.2 }),
          tf.layers.dense({
            units: 16,
            activation: 'relu'
          }),
          tf.layers.dense({
            units: 1,
            activation: 'sigmoid' // Probability of user liking the workout
          })
        ]
      });

      this.model.compile({
        optimizer: 'adam',
        loss: 'binaryCrossentropy',
        metrics: ['accuracy']
      });

      this.initialized = true;
      logger.info('ML personalization model initialized');
    } catch (error) {
      logger.error('Failed to initialize ML model:', error.message);
    }
  }

  // Generate personalized workout recommendations
  async generateWorkoutRecommendations(userId, options = {}) {
    try {
      const {
        count = 5,
        workoutType = null,
        duration = null,
        refreshProfile = false
      } = options;

      // Get or build user profile
      const userProfile = await this.getUserProfile(userId, refreshProfile);
      
      // Get available workouts
      const availableWorkouts = await this.getAvailableWorkouts(userId);
      
      // Score and rank workouts
      const scoredWorkouts = await this.scoreWorkouts(userProfile, availableWorkouts);
      
      // Apply diversity and novelty factors
      const diversifiedWorkouts = this.applyDiversification(scoredWorkouts, userProfile);
      
      // Return top recommendations
      const recommendations = diversifiedWorkouts
        .slice(0, count)
        .map(workout => ({
          ...workout,
          reasoning: this.generateRecommendationReasoning(userProfile, workout)
        }));

      // Log recommendation for feedback learning
      await this.logRecommendation(userId, recommendations);

      logger.info('Generated personalized workout recommendations', {
        userId,
        count: recommendations.length,
        avgScore: recommendations.reduce((sum, w) => sum + w.score, 0) / recommendations.length
      });

      return recommendations;
    } catch (error) {
      logger.error('Failed to generate workout recommendations:', error.message);
      return this.getFallbackRecommendations();
    }
  }

  // Build comprehensive user profile
  async getUserProfile(userId, refresh = false) {
    const cacheKey = `user_profile:${userId}`;
    
    if (!refresh && this.userProfiles.has(userId)) {
      return this.userProfiles.get(userId);
    }

    const cachedProfile = await cache.get(cacheKey);
    if (!refresh && cachedProfile) {
      this.userProfiles.set(userId, cachedProfile);
      return cachedProfile;
    }

    const firestore = getFirestore();
    
    // Gather user data
    const [
      userDoc,
      workoutHistory,
      runHistory,
      dailyLogs,
      achievements
    ] = await Promise.all([
      firestore.collection('users').doc(userId).get(),
      firestore.collection('users').doc(userId).collection('workout_completions')
        .orderBy('completedAt', 'desc').limit(50).get(),
      firestore.collection('users').doc(userId).collection('runs')
        .orderBy('completedAt', 'desc').limit(30).get(),
      firestore.collection('users').doc(userId).collection('daily_logs')
        .orderBy('date', 'desc').limit(30).get(),
      firestore.collection('users').doc(userId).collection('achievements')
        .doc('summary').get()
    ]);

    const userData = userDoc.data();
    const workouts = workoutHistory.docs.map(doc => doc.data());
    const runs = runHistory.docs.map(doc => doc.data());
    const logs = dailyLogs.docs.map(doc => doc.data());
    const achievementData = achievements.exists ? achievements.data() : {};

    // Build profile
    const profile = {
      userId,
      demographics: {
        age: userData.age || 30,
        gender: userData.gender || 'unknown',
        fitnessLevel: this.inferFitnessLevel(workouts, runs),
        experienceLevel: this.calculateExperienceLevel(workouts, runs, userData.createdAt)
      },
      preferences: {
        workoutTypes: this.extractWorkoutTypePreferences(workouts),
        duration: this.extractDurationPreferences(workouts),
        difficulty: this.extractDifficultyPreferences(workouts),
        equipment: this.extractEquipmentPreferences(workouts),
        timeOfDay: this.extractTimePreferences(workouts)
      },
      performance: {
        avgWorkoutDuration: workouts.length > 0 ? 
          workouts.reduce((sum, w) => sum + (w.duration || 0), 0) / workouts.length : 0,
        workoutFrequency: this.calculateWorkoutFrequency(workouts),
        progressTrend: this.calculateProgressTrend(workouts, logs),
        consistency: this.calculateConsistencyScore(workouts, logs)
      },
      goals: {
        primary: userData.goals?.primary || 'general_fitness',
        weightGoal: userData.goals?.weightGoal || 'maintain',
        targetAreas: userData.goals?.targetAreas || ['general']
      },
      behavioral: {
        motivationFactors: this.inferMotivationFactors(achievementData, workouts),
        dropoffRisk: this.calculateDropoffRisk(workouts),
        socialEngagement: this.calculateSocialEngagement(userId)
      },
      contextual: {
        recentActivity: this.analyzeRecentActivity(workouts, logs),
        seasonalPatterns: this.identifySeasonalPatterns(workouts, logs),
        availableTime: this.estimateAvailableTime(workouts)
      }
    };

    // Cache profile for 24 hours
    await cache.set(cacheKey, profile, 86400);
    this.userProfiles.set(userId, profile);

    return profile;
  }

  // Score workouts based on user profile
  async scoreWorkouts(userProfile, workouts) {
    const scoredWorkouts = [];

    for (const workout of workouts) {
      let score = 0;

      // Content-based scoring
      score += this.scoreWorkoutType(userProfile, workout) * this.featureWeights.workoutType;
      score += this.scoreDuration(userProfile, workout) * this.featureWeights.duration;
      score += this.scoreDifficulty(userProfile, workout) * this.featureWeights.difficulty;
      score += this.scoreEquipment(userProfile, workout) * this.featureWeights.equipment;
      score += this.scoreTargetMuscles(userProfile, workout) * this.featureWeights.targetMuscles;

      // Collaborative filtering (if ML model is available)
      if (this.initialized && this.model) {
        const features = this.extractFeatures(userProfile, workout);
        const prediction = await this.model.predict(tf.tensor2d([features])).data();
        score = (score * 0.7) + (prediction[0] * 0.3); // Blend content and collaborative
      }

      // Apply contextual boosts
      score = this.applyContextualBoosts(score, userProfile, workout);

      scoredWorkouts.push({
        ...workout,
        score,
        confidence: this.calculateConfidence(userProfile, workout)
      });
    }

    return scoredWorkouts.sort((a, b) => b.score - a.score);
  }

  // Apply diversification to avoid repetitive recommendations
  applyDiversification(scoredWorkouts, userProfile) {
    const diversified = [];
    const typesSeen = new Set();
    const difficultiesSeen = new Set();
    
    // Ensure variety in workout types and difficulties
    for (const workout of scoredWorkouts) {
      const workoutType = workout.type || 'general';
      const difficulty = workout.difficulty || 'medium';
      
      // Boost score for diversity
      let diversityBoost = 1.0;
      if (!typesSeen.has(workoutType)) {
        diversityBoost += 0.1;
        typesSeen.add(workoutType);
      }
      if (!difficultiesSeen.has(difficulty)) {
        diversityBoost += 0.05;
        difficultiesSeen.add(difficulty);
      }

      // Apply novelty boost for new workout types
      if (!userProfile.preferences.workoutTypes[workoutType]) {
        diversityBoost += 0.15; // Encourage exploration
      }

      diversified.push({
        ...workout,
        score: workout.score * diversityBoost
      });
    }

    return diversified.sort((a, b) => b.score - a.score);
  }

  // Generate personalized nutrition recommendations
  async generateNutritionRecommendations(userId) {
    try {
      const userProfile = await this.getUserProfile(userId);
      const firestore = getFirestore();

      // Get user's TDEE and macro preferences
      const tdeeDoc = await firestore.collection('users').doc(userId)
        .collection('tdee').orderBy('timestamp', 'desc').limit(1).get();

      let tdeeData = null;
      if (!tdeeDoc.empty) {
        tdeeData = tdeeDoc.docs[0].data();
      }

      // Generate recommendations based on profile and goals
      const recommendations = {
        mealTiming: this.generateMealTimingRecommendations(userProfile),
        macroAdjustments: this.generateMacroRecommendations(userProfile, tdeeData),
        hydration: this.generateHydrationRecommendations(userProfile),
        supplements: this.generateSupplementRecommendations(userProfile),
        recipes: await this.generatePersonalizedRecipes(userProfile, tdeeData)
      };

      return recommendations;
    } catch (error) {
      logger.error('Failed to generate nutrition recommendations:', error.message);
      return this.getFallbackNutritionRecommendations();
    }
  }

  // Feature extraction methods
  extractFeatures(userProfile, workout) {
    return [
      // User features
      userProfile.demographics.age / 100,
      userProfile.demographics.gender === 'male' ? 1 : 0,
      userProfile.demographics.fitnessLevel / 5,
      userProfile.performance.avgWorkoutDuration / 60,
      userProfile.performance.workoutFrequency,
      userProfile.performance.consistency / 100,
      
      // Workout features
      this.encodeWorkoutType(workout.type),
      (workout.duration || 30) / 120,
      this.encodeDifficulty(workout.difficulty),
      this.encodeEquipment(workout.equipment),
      (workout.exercises?.length || 5) / 20,
      
      // Interaction features
      userProfile.preferences.workoutTypes[workout.type] || 0,
      this.calculateSimilarityScore(userProfile, workout),
      Math.random() // Random factor for exploration
    ];
  }

  // Scoring methods
  scoreWorkoutType(userProfile, workout) {
    const workoutType = workout.type || 'general';
    const preference = userProfile.preferences.workoutTypes[workoutType] || 0;
    return Math.min(1, preference / 0.5); // Normalize to 0-1
  }

  scoreDuration(userProfile, workout) {
    const workoutDuration = workout.duration || 30;
    const preferredDuration = userProfile.preferences.duration.preferred || 30;
    const tolerance = 15; // minutes
    
    const difference = Math.abs(workoutDuration - preferredDuration);
    return Math.max(0, 1 - (difference / tolerance));
  }

  scoreDifficulty(userProfile, workout) {
    const workoutDifficulty = this.encodeDifficulty(workout.difficulty);
    const userLevel = userProfile.demographics.fitnessLevel / 5;
    const preferredDifficulty = userProfile.preferences.difficulty.preferred || 0.5;
    
    // Match difficulty to user's fitness level and preferences
    const levelMatch = 1 - Math.abs(workoutDifficulty - userLevel);
    const preferenceMatch = 1 - Math.abs(workoutDifficulty - preferredDifficulty);
    
    return (levelMatch + preferenceMatch) / 2;
  }

  scoreEquipment(userProfile, workout) {
    const workoutEquipment = workout.equipment || 'bodyweight';
    const availableEquipment = userProfile.preferences.equipment.available || ['bodyweight'];
    
    return availableEquipment.includes(workoutEquipment) ? 1 : 0.3;
  }

  scoreTargetMuscles(userProfile, workout) {
    const workoutMuscles = workout.targetMuscles || ['general'];
    const targetAreas = userProfile.goals.targetAreas || ['general'];
    
    const overlap = workoutMuscles.filter(muscle => targetAreas.includes(muscle)).length;
    return overlap > 0 ? overlap / Math.max(workoutMuscles.length, targetAreas.length) : 0.5;
  }

  // Contextual boost methods
  applyContextualBoosts(score, userProfile, workout) {
    let boostedScore = score;

    // Time of day boost
    const currentHour = new Date().getHours();
    const preferredTime = userProfile.preferences.timeOfDay.peak || 18;
    if (Math.abs(currentHour - preferredTime) <= 2) {
      boostedScore *= 1.1;
    }

    // Consistency boost (encourage regular workout types)
    const recentTypes = userProfile.contextual.recentActivity.workoutTypes || {};
    const workoutType = workout.type || 'general';
    if (recentTypes[workoutType] && recentTypes[workoutType] >= 2) {
      boostedScore *= 1.05;
    }

    // Goal alignment boost
    if (this.alignsWithGoals(workout, userProfile.goals)) {
      boostedScore *= 1.15;
    }

    // Novelty penalty (reduce repetition)
    if (userProfile.contextual.recentActivity.workoutIds?.includes(workout.id)) {
      boostedScore *= 0.8;
    }

    return boostedScore;
  }

  // Helper methods for profile building
  inferFitnessLevel(workouts, runs) {
    if (workouts.length === 0 && runs.length === 0) return 1; // Beginner
    
    const avgWorkoutDuration = workouts.length > 0 ?
      workouts.reduce((sum, w) => sum + (w.duration || 0), 0) / workouts.length : 0;
    const avgRunDistance = runs.length > 0 ?
      runs.reduce((sum, r) => sum + (r.distance || 0), 0) / runs.length : 0;
    
    let level = 1;
    if (avgWorkoutDuration > 45 || avgRunDistance > 5000) level = 3;
    else if (avgWorkoutDuration > 30 || avgRunDistance > 2000) level = 2;
    if (workouts.length > 20 || runs.length > 15) level = Math.min(5, level + 1);
    
    return level;
  }

  extractWorkoutTypePreferences(workouts) {
    const typeCount = {};
    workouts.forEach(workout => {
      const type = workout.type || 'general';
      typeCount[type] = (typeCount[type] || 0) + 1;
    });
    
    const total = workouts.length || 1;
    const preferences = {};
    Object.keys(typeCount).forEach(type => {
      preferences[type] = typeCount[type] / total;
    });
    
    return preferences;
  }

  calculateWorkoutFrequency(workouts) {
    if (workouts.length < 2) return 0;
    
    const sortedWorkouts = workouts.sort((a, b) => new Date(b.completedAt) - new Date(a.completedAt));
    const recentWorkouts = sortedWorkouts.slice(0, 14); // Last 14 workouts
    
    if (recentWorkouts.length < 2) return 0;
    
    const timeSpan = new Date(recentWorkouts[0].completedAt) - new Date(recentWorkouts[recentWorkouts.length - 1].completedAt);
    const days = timeSpan / (1000 * 60 * 60 * 24);
    
    return days > 0 ? recentWorkouts.length / days : 0;
  }

  generateRecommendationReasoning(userProfile, workout) {
    const reasons = [];
    
    if (workout.score > 0.8) {
      reasons.push('Highly matches your preferences');
    }
    
    const workoutType = workout.type || 'general';
    if (userProfile.preferences.workoutTypes[workoutType] > 0.3) {
      reasons.push(`You enjoy ${workoutType} workouts`);
    }
    
    if (this.alignsWithGoals(workout, userProfile.goals)) {
      reasons.push('Aligned with your fitness goals');
    }
    
    if (reasons.length === 0) {
      reasons.push('Recommended to add variety to your routine');
    }
    
    return reasons[0]; // Return primary reason
  }

  alignsWithGoals(workout, goals) {
    const primaryGoal = goals.primary || 'general_fitness';
    const workoutType = workout.type || 'general';
    
    const goalAlignments = {
      'weight_loss': ['cardio', 'hiit', 'circuit'],
      'muscle_gain': ['strength', 'resistance', 'weightlifting'],
      'endurance': ['cardio', 'running', 'cycling'],
      'flexibility': ['yoga', 'stretching', 'pilates'],
      'general_fitness': ['mixed', 'general', 'functional']
    };
    
    const alignedTypes = goalAlignments[primaryGoal] || [];
    return alignedTypes.includes(workoutType);
  }

  // Fallback methods
  getFallbackRecommendations() {
    return [
      {
        name: 'Beginner Full Body Workout',
        duration: 30,
        difficulty: 'beginner',
        type: 'strength',
        score: 0.7,
        reasoning: 'Great for building overall fitness'
      },
      {
        name: 'Quick Cardio Session',
        duration: 20,
        difficulty: 'intermediate',
        type: 'cardio',
        score: 0.6,
        reasoning: 'Perfect for busy schedules'
      }
    ];
  }

  getFallbackNutritionRecommendations() {
    return {
      mealTiming: 'Eat 3 balanced meals with 2 healthy snacks',
      macroAdjustments: 'Focus on lean protein and complex carbs',
      hydration: 'Drink at least 8 glasses of water daily',
      supplements: 'Consider a multivitamin and omega-3',
      recipes: []
    };
  }

  // Additional utility methods
  encodeDifficulty(difficulty) {
    const mapping = { 'beginner': 0.2, 'easy': 0.3, 'intermediate': 0.5, 'hard': 0.7, 'advanced': 0.9 };
    return mapping[difficulty] || 0.5;
  }

  encodeWorkoutType(type) {
    const mapping = { 'cardio': 0.2, 'strength': 0.4, 'flexibility': 0.6, 'hiit': 0.8, 'mixed': 1.0 };
    return mapping[type] || 0.5;
  }

  encodeEquipment(equipment) {
    const mapping = { 'bodyweight': 0.2, 'dumbbells': 0.4, 'resistance_bands': 0.6, 'full_gym': 0.8 };
    return mapping[equipment] || 0.2;
  }

  calculateConfidence(userProfile, workout) {
    // Calculate recommendation confidence based on profile completeness and match quality
    const profileCompleteness = this.calculateProfileCompleteness(userProfile);
    const matchQuality = workout.score;
    
    return (profileCompleteness + matchQuality) / 2;
  }

  calculateProfileCompleteness(userProfile) {
    let completeness = 0;
    const factors = [
      userProfile.demographics.age > 0,
      userProfile.demographics.gender !== 'unknown',
      userProfile.performance.avgWorkoutDuration > 0,
      Object.keys(userProfile.preferences.workoutTypes).length > 0,
      userProfile.goals.primary !== 'general_fitness'
    ];
    
    return factors.filter(Boolean).length / factors.length;
  }

  async logRecommendation(userId, recommendations) {
    try {
      const logData = {
        userId,
        recommendations: recommendations.map(r => ({ id: r.id, score: r.score })),
        timestamp: new Date(),
        type: 'workout_recommendation'
      };

      // Store in Firestore for learning
      const firestore = getFirestore();
      await firestore.collection('recommendation_logs').add(logData);
    } catch (error) {
      logger.error('Failed to log recommendation:', error.message);
    }
  }

  // Methods for other missing functionality (simplified implementations)
  calculateExperienceLevel(workouts, runs, createdAt) {
    const accountAge = (new Date() - new Date(createdAt)) / (1000 * 60 * 60 * 24 * 30); // months
    const totalActivities = workouts.length + runs.length;
    return Math.min(5, Math.floor(accountAge / 3) + Math.floor(totalActivities / 20));
  }

  extractDurationPreferences(workouts) {
    const durations = workouts.map(w => w.duration || 30);
    return {
      preferred: durations.reduce((sum, d) => sum + d, 0) / durations.length || 30,
      range: { min: Math.min(...durations), max: Math.max(...durations) }
    };
  }

  extractDifficultyPreferences(workouts) {
    const difficulties = workouts.map(w => this.encodeDifficulty(w.difficulty));
    return {
      preferred: difficulties.reduce((sum, d) => sum + d, 0) / difficulties.length || 0.5
    };
  }

  extractEquipmentPreferences(workouts) {
    const equipment = workouts.map(w => w.equipment || 'bodyweight');
    return {
      available: [...new Set(equipment)]
    };
  }

  extractTimePreferences(workouts) {
    const hours = workouts.map(w => new Date(w.completedAt).getHours());
    return {
      peak: hours.reduce((sum, h) => sum + h, 0) / hours.length || 18
    };
  }

  calculateProgressTrend(workouts, logs) {
    // Simplified trend calculation
    return 'improving';
  }

  calculateConsistencyScore(workouts, logs) {
    // Simplified consistency score
    return Math.min(100, (workouts.length + logs.length) * 2);
  }

  inferMotivationFactors(achievementData, workouts) {
    return ['achievements', 'progress_tracking'];
  }

  calculateDropoffRisk(workouts) {
    const recentWorkouts = workouts.filter(w => 
      new Date(w.completedAt) > new Date(Date.now() - 14 * 24 * 60 * 60 * 1000)
    );
    return recentWorkouts.length < 2 ? 'high' : 'low';
  }

  calculateSocialEngagement(userId) {
    return 0.5; // Simplified
  }

  analyzeRecentActivity(workouts, logs) {
    return {
      workoutTypes: this.extractWorkoutTypePreferences(workouts.slice(0, 10)),
      workoutIds: workouts.slice(0, 5).map(w => w.id).filter(Boolean)
    };
  }

  identifySeasonalPatterns(workouts, logs) {
    return {}; // Simplified
  }

  estimateAvailableTime(workouts) {
    return workouts.reduce((sum, w) => sum + (w.duration || 30), 0) / workouts.length || 30;
  }

  async getAvailableWorkouts(userId) {
    // Return mock workout data - in real implementation, this would query the workout database
    return [
      {
        id: '1',
        name: 'Full Body Strength',
        type: 'strength',
        duration: 45,
        difficulty: 'intermediate',
        equipment: 'dumbbells',
        targetMuscles: ['chest', 'back', 'legs']
      },
      {
        id: '2',
        name: 'HIIT Cardio',
        type: 'cardio',
        duration: 30,
        difficulty: 'advanced',
        equipment: 'bodyweight',
        targetMuscles: ['cardio']
      },
      {
        id: '3',
        name: 'Yoga Flow',
        type: 'flexibility',
        duration: 60,
        difficulty: 'beginner',
        equipment: 'bodyweight',
        targetMuscles: ['flexibility']
      }
    ];
  }

  calculateSimilarityScore(userProfile, workout) {
    // Simplified similarity calculation
    return 0.5;
  }

  generateMealTimingRecommendations(userProfile) {
    return 'Eat every 3-4 hours with your largest meal after workouts';
  }

  generateMacroRecommendations(userProfile, tdeeData) {
    return 'Increase protein intake to 1.6g per kg body weight';
  }

  generateHydrationRecommendations(userProfile) {
    return 'Drink 500ml water 2 hours before workouts and 150-250ml every 15-20 minutes during exercise';
  }

  generateSupplementRecommendations(userProfile) {
    return ['Whey protein post-workout', 'Creatine monohydrate 3-5g daily'];
  }

  async generatePersonalizedRecipes(userProfile, tdeeData) {
    return []; // Would integrate with recipe generation service
  }
}

module.exports = new PersonalizationService();