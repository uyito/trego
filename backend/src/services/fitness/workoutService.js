const openaiService = require('../ai/openaiService');
const logger = require('../../utils/logger');
const { cache } = require('../../config/redis');
const { getFirestore } = require('../../config/firebase');

class WorkoutService {
  constructor() {
    this.exerciseDatabase = {
      // Bodyweight exercises
      'push_ups': {
        name: 'Push-ups',
        category: 'strength',
        targetMuscles: ['chest', 'shoulders', 'triceps'],
        equipment: 'bodyweight',
        difficulty: 'beginner',
        instructions: [
          'Start in a plank position with hands slightly wider than shoulders',
          'Lower your body until chest nearly touches the floor',
          'Push back up to starting position',
          'Keep core engaged throughout'
        ],
        modifications: {
          easier: 'Knee push-ups',
          harder: 'Diamond push-ups'
        }
      },
      'squats': {
        name: 'Squats',
        category: 'strength',
        targetMuscles: ['quads', 'glutes', 'hamstrings'],
        equipment: 'bodyweight',
        difficulty: 'beginner',
        instructions: [
          'Stand with feet hip-width apart',
          'Lower down by bending knees and pushing hips back',
          'Keep chest up and knees tracking over toes',
          'Return to starting position'
        ],
        modifications: {
          easier: 'Chair-assisted squats',
          harder: 'Jump squats'
        }
      },
      'plank': {
        name: 'Plank',
        category: 'core',
        targetMuscles: ['core', 'shoulders', 'back'],
        equipment: 'bodyweight',
        difficulty: 'beginner',
        instructions: [
          'Start in push-up position',
          'Lower to forearms, elbows under shoulders',
          'Keep body in straight line from head to heels',
          'Hold position while breathing normally'
        ],
        modifications: {
          easier: 'Knee plank',
          harder: 'Single-arm plank'
        }
      },
      'burpees': {
        name: 'Burpees',
        category: 'cardio',
        targetMuscles: ['full body'],
        equipment: 'bodyweight',
        difficulty: 'advanced',
        instructions: [
          'Start standing, drop to squat position',
          'Kick feet back to plank position',
          'Do a push-up (optional)',
          'Jump feet back to squat, then jump up with arms overhead'
        ],
        modifications: {
          easier: 'Step back burpees',
          harder: 'Burpee box jumps'
        }
      },
      'mountain_climbers': {
        name: 'Mountain Climbers',
        category: 'cardio',
        targetMuscles: ['core', 'shoulders', 'legs'],
        equipment: 'bodyweight',
        difficulty: 'intermediate',
        instructions: [
          'Start in plank position',
          'Bring one knee toward chest',
          'Quickly switch legs in running motion',
          'Keep core tight and hips level'
        ],
        modifications: {
          easier: 'Slow mountain climbers',
          harder: 'Cross-body mountain climbers'
        }
      }
      // Add more exercises as needed
    };

    this.workoutTemplates = {
      'quick_cardio': {
        name: 'Quick Cardio Blast',
        duration: 15,
        type: 'cardio',
        difficulty: 'intermediate',
        exercises: [
          { exercise: 'burpees', duration: 30, rest: 30 },
          { exercise: 'mountain_climbers', duration: 30, rest: 30 },
          { exercise: 'squats', duration: 30, rest: 30 }
        ]
      },
      'strength_basics': {
        name: 'Strength Basics',
        duration: 20,
        type: 'strength',
        difficulty: 'beginner',
        exercises: [
          { exercise: 'push_ups', reps: '8-12', sets: 3, rest: 60 },
          { exercise: 'squats', reps: '10-15', sets: 3, rest: 60 },
          { exercise: 'plank', duration: 30, sets: 3, rest: 60 }
        ]
      }
    };
  }

  // Generate personalized workout using AI
  async generateWorkout({
    fitnessLevel = 'beginner',
    goals = ['general_fitness'],
    duration = 30,
    equipment = ['bodyweight'],
    preferences = [],
    focusAreas = [],
    userId
  }) {
    try {
      // Use OpenAI service for workout generation
      const workout = await openaiService.generateWorkoutPlan({
        fitnessLevel,
        goals,
        duration,
        equipment,
        preferences,
        userId
      });

      // Save generated workout to user's library
      await this.saveWorkoutToLibrary(userId, workout);

      logger.info('Workout generated', {
        userId,
        duration,
        fitnessLevel,
        exerciseCount: workout.exercises?.length || 0
      });

      return workout;
    } catch (error) {
      logger.error('Workout generation failed', { userId, error: error.message });
      
      // Return fallback template workout
      return this.getFallbackWorkout({ fitnessLevel, duration, goals });
    }
  }

  // Get fallback workout template
  getFallbackWorkout({ fitnessLevel, duration, goals }) {
    const isCardioGoal = goals.some(g => g.includes('cardio') || g.includes('endurance'));
    const template = isCardioGoal ? this.workoutTemplates.quick_cardio : this.workoutTemplates.strength_basics;
    
    return {
      ...template,
      duration: Math.min(duration, template.duration),
      difficulty: fitnessLevel,
      generatedAt: new Date().toISOString(),
      fallback: true
    };
  }

  // Save workout to user's library
  async saveWorkoutToLibrary(userId, workout) {
    try {
      const firestore = getFirestore();
      
      const workoutData = {
        ...workout,
        userId,
        savedAt: new Date(),
        isCustom: false,
        tags: this.generateWorkoutTags(workout)
      };

      await firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .add(workoutData);

      return true;
    } catch (error) {
      logger.error('Save workout to library failed', { userId, error: error.message });
      return false;
    }
  }

  // Generate relevant tags for workout
  generateWorkoutTags(workout) {
    const tags = [workout.difficulty];
    
    if (workout.exercises) {
      const hasCardio = workout.exercises.some(ex => 
        ex.type === 'cardio' || ex.name?.toLowerCase().includes('cardio')
      );
      const hasStrength = workout.exercises.some(ex =>
        ex.type === 'strength' || ex.targetMuscles?.length > 0
      );
      
      if (hasCardio) tags.push('cardio');
      if (hasStrength) tags.push('strength');
    }
    
    if (workout.duration <= 15) tags.push('quick');
    if (workout.duration >= 45) tags.push('long');
    
    return tags;
  }

  // Track workout completion
  async trackWorkoutCompletion({
    userId,
    workoutId,
    duration,
    exercises,
    caloriesBurned = 0,
    notes = '',
    difficulty = 'medium'
  }) {
    try {
      const firestore = getFirestore();
      
      const completionData = {
        workoutId,
        userId,
        completedAt: new Date(),
        duration,
        exercises: exercises.map(ex => ({
          name: ex.name,
          completed: ex.completed || false,
          reps: ex.reps || null,
          weight: ex.weight || null,
          duration: ex.duration || null,
          notes: ex.notes || ''
        })),
        caloriesBurned,
        notes,
        difficulty,
        rating: null // User can rate later
      };

      const docRef = await firestore
        .collection('users')
        .doc(userId)
        .collection('workout_completions')
        .add(completionData);

      // Update user stats for achievements
      await this.updateWorkoutStats(userId);

      logger.info('Workout completion tracked', {
        userId,
        workoutId,
        duration,
        caloriesBurned
      });

      return docRef.id;
    } catch (error) {
      logger.error('Track workout completion failed', { userId, error: error.message });
      throw error;
    }
  }

  // Update user workout statistics
  async updateWorkoutStats(userId) {
    try {
      const statsKey = `user_stats:${userId}`;
      const currentStats = await cache.get(statsKey) || {};

      // Increment workout counters
      currentStats.workouts_completed = (currentStats.workouts_completed || 0) + 1;
      
      // Calculate workout streak
      const today = new Date().toISOString().split('T')[0];
      const lastWorkoutDate = currentStats.last_workout_date;
      
      if (lastWorkoutDate === today) {
        // Already worked out today, don't increment streak
      } else if (this.isConsecutiveDay(lastWorkoutDate, today)) {
        currentStats.workout_streak = (currentStats.workout_streak || 0) + 1;
      } else {
        currentStats.workout_streak = 1; // Reset streak
      }
      
      currentStats.last_workout_date = today;

      // Check for time-based achievements
      const workoutHour = new Date().getHours();
      if (workoutHour < 7) {
        currentStats.early_morning_workouts = (currentStats.early_morning_workouts || 0) + 1;
      } else if (workoutHour >= 21) {
        currentStats.late_night_workouts = (currentStats.late_night_workouts || 0) + 1;
      }

      await cache.set(statsKey, currentStats, 86400 * 7); // Cache for 7 days

      return currentStats;
    } catch (error) {
      logger.error('Update workout stats failed', { userId, error: error.message });
      return {};
    }
  }

  // Check if two dates are consecutive days
  isConsecutiveDay(dateStr1, dateStr2) {
    if (!dateStr1 || !dateStr2) return false;
    
    const date1 = new Date(dateStr1);
    const date2 = new Date(dateStr2);
    const diffTime = Math.abs(date2 - date1);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    return diffDays === 1;
  }

  // Get user's workout history
  async getWorkoutHistory(userId, { limit = 20, offset = 0, dateFrom, dateTo } = {}) {
    try {
      const firestore = getFirestore();
      let query = firestore
        .collection('users')
        .doc(userId)
        .collection('workout_completions')
        .orderBy('completedAt', 'desc');

      if (dateFrom) {
        query = query.where('completedAt', '>=', new Date(dateFrom));
      }
      
      if (dateTo) {
        query = query.where('completedAt', '<=', new Date(dateTo));
      }

      const snapshot = await query
        .offset(offset)
        .limit(limit)
        .get();

      const workouts = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        completedAt: doc.data().completedAt.toDate().toISOString()
      }));

      return {
        workouts,
        hasMore: snapshot.size === limit,
        total: snapshot.size
      };
    } catch (error) {
      logger.error('Get workout history failed', { userId, error: error.message });
      throw error;
    }
  }

  // Get workout statistics
  async getWorkoutStatistics(userId) {
    try {
      const firestore = getFirestore();
      const statsKey = `user_stats:${userId}`;
      const cachedStats = await cache.get(statsKey);

      if (cachedStats) {
        return this.formatWorkoutStats(cachedStats);
      }

      // Calculate from database if not cached
      const snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('workout_completions')
        .orderBy('completedAt', 'desc')
        .get();

      const workouts = snapshot.docs.map(doc => doc.data());
      const stats = this.calculateWorkoutStatsFromHistory(workouts);

      // Cache for 1 hour
      await cache.set(statsKey, stats, 3600);

      return this.formatWorkoutStats(stats);
    } catch (error) {
      logger.error('Get workout statistics failed', { userId, error: error.message });
      throw error;
    }
  }

  formatWorkoutStats(stats) {
    return {
      totalWorkouts: stats.workouts_completed || 0,
      currentStreak: stats.workout_streak || 0,
      longestStreak: stats.longest_workout_streak || 0,
      totalDuration: stats.total_workout_duration || 0,
      averageDuration: stats.average_workout_duration || 0,
      totalCaloriesBurned: stats.total_calories_burned || 0,
      favoriteWorkoutType: stats.favorite_workout_type || 'strength',
      weeklyGoal: stats.weekly_workout_goal || 3,
      thisWeek: stats.workouts_this_week || 0,
      lastWorkout: stats.last_workout_date || null
    };
  }

  calculateWorkoutStatsFromHistory(workouts) {
    if (workouts.length === 0) {
      return {
        workouts_completed: 0,
        workout_streak: 0,
        total_workout_duration: 0,
        average_workout_duration: 0,
        total_calories_burned: 0
      };
    }

    const totalDuration = workouts.reduce((sum, w) => sum + (w.duration || 0), 0);
    const totalCalories = workouts.reduce((sum, w) => sum + (w.caloriesBurned || 0), 0);

    return {
      workouts_completed: workouts.length,
      workout_streak: this.calculateCurrentStreak(workouts),
      total_workout_duration: totalDuration,
      average_workout_duration: Math.round(totalDuration / workouts.length),
      total_calories_burned: totalCalories
    };
  }

  calculateCurrentStreak(workouts) {
    if (workouts.length === 0) return 0;

    // Sort by date (most recent first)
    const sortedWorkouts = workouts.sort((a, b) => 
      new Date(b.completedAt) - new Date(a.completedAt)
    );

    let streak = 0;
    let currentDate = new Date().toISOString().split('T')[0];

    for (const workout of sortedWorkouts) {
      const workoutDate = workout.completedAt.split('T')[0];
      
      if (workoutDate === currentDate || this.isConsecutiveDay(workoutDate, currentDate)) {
        streak++;
        currentDate = workoutDate;
      } else {
        break;
      }
    }

    return streak;
  }

  // Get recommended workouts based on user's history and preferences
  async getRecommendedWorkouts(userId) {
    try {
      // Get user's workout history and preferences
      const history = await this.getWorkoutHistory(userId, { limit: 10 });
      const stats = await this.getWorkoutStatistics(userId);

      // Simple recommendation logic
      const recommendations = [];

      // Recommend based on missing workout types
      if (stats.totalWorkouts > 0) {
        const recentTypes = history.workouts.map(w => w.type || 'general');
        const missingCardio = !recentTypes.includes('cardio');
        const missingStrength = !recentTypes.includes('strength');

        if (missingCardio) {
          recommendations.push({
            reason: 'Balance your routine',
            suggestion: 'cardio',
            workouts: ['quick_cardio']
          });
        }

        if (missingStrength) {
          recommendations.push({
            reason: 'Build strength',
            suggestion: 'strength',
            workouts: ['strength_basics']
          });
        }
      } else {
        // New user recommendations
        recommendations.push({
          reason: 'Great for beginners',
          suggestion: 'start_here',
          workouts: ['strength_basics']
        });
      }

      return recommendations;
    } catch (error) {
      logger.error('Get recommended workouts failed', { userId, error: error.message });
      return [];
    }
  }

  // Get exercise information
  getExerciseInfo(exerciseId) {
    return this.exerciseDatabase[exerciseId] || null;
  }

  // Search exercises
  searchExercises(query, filters = {}) {
    const exercises = Object.values(this.exerciseDatabase);
    let filtered = exercises;

    // Text search
    if (query) {
      const searchTerm = query.toLowerCase();
      filtered = filtered.filter(ex => 
        ex.name.toLowerCase().includes(searchTerm) ||
        ex.targetMuscles.some(muscle => muscle.includes(searchTerm)) ||
        ex.category.includes(searchTerm)
      );
    }

    // Apply filters
    if (filters.category) {
      filtered = filtered.filter(ex => ex.category === filters.category);
    }

    if (filters.equipment) {
      filtered = filtered.filter(ex => ex.equipment === filters.equipment);
    }

    if (filters.difficulty) {
      filtered = filtered.filter(ex => ex.difficulty === filters.difficulty);
    }

    if (filters.targetMuscle) {
      filtered = filtered.filter(ex => 
        ex.targetMuscles.includes(filters.targetMuscle)
      );
    }

    return filtered;
  }

  // Get available filter options
  getFilterOptions() {
    const exercises = Object.values(this.exerciseDatabase);
    
    return {
      categories: [...new Set(exercises.map(ex => ex.category))],
      equipment: [...new Set(exercises.map(ex => ex.equipment))],
      difficulties: [...new Set(exercises.map(ex => ex.difficulty))],
      targetMuscles: [...new Set(exercises.flatMap(ex => ex.targetMuscles))]
    };
  }
}

module.exports = new WorkoutService();