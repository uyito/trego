// MongoDB initialization script
db.auth('admin', 'password')

// Create trego database
db = db.getSiblingDB('trego')

// Create indexes for optimal performance
db.users.createIndex({ "email": 1 }, { unique: true })
db.users.createIndex({ "uid": 1 }, { unique: true })
db.users.createIndex({ "createdAt": -1 })
db.users.createIndex({ "lastLoginAt": -1 })

// Daily logs indexes
db.daily_logs.createIndex({ "userId": 1, "date": -1 })
db.daily_logs.createIndex({ "date": -1 })

// Workout completions indexes
db.workout_completions.createIndex({ "userId": 1, "completedAt": -1 })
db.workout_completions.createIndex({ "completedAt": -1 })

// Run tracking indexes
db.runs.createIndex({ "userId": 1, "completedAt": -1 })
db.runs.createIndex({ "completedAt": -1 })
db.runs.createIndex({ "userId": 1, "distance": -1 })

// Achievement indexes
db.achievements.createIndex({ "userId": 1, "earnedAt": -1 })
db.achievements.createIndex({ "earnedAt": -1 })

// Social features indexes
db.friendships.createIndex({ "userId": 1, "status": 1 })
db.friendships.createIndex({ "friendId": 1, "status": 1 })
db.posts.createIndex({ "authorId": 1, "createdAt": -1 })
db.posts.createIndex({ "createdAt": -1, "visibility": 1 })
db.challenges.createIndex({ "creatorId": 1, "status": 1 })
db.challenges.createIndex({ "status": 1, "isPublic": 1, "createdAt": -1 })

// Admin and analytics indexes
db.admin_logs.createIndex({ "timestamp": -1 })
db.admin_logs.createIndex({ "adminId": 1, "timestamp": -1 })
db.recommendation_logs.createIndex({ "userId": 1, "timestamp": -1 })
db.recommendation_feedback.createIndex({ "userId": 1, "timestamp": -1 })

// Create collections with initial data
db.system.insertOne({
  _id: "config",
  maintenanceMode: false,
  maxUsersPerChallenge: 100,
  postModerationEnabled: false,
  challengeModerationEnabled: false,
  newUserRegistrationEnabled: true,
  maxPostsPerDay: 10,
  maxChallengesPerUser: 5,
  createdAt: new Date(),
  updatedAt: new Date()
})

// Insert sample achievement data
db.achievement_templates.insertMany([
  {
    id: 'first_workout',
    title: 'First Steps',
    description: 'Complete your first workout',
    icon: '🏃‍♂️',
    category: 'getting_started',
    points: 10,
    type: 'single',
    criteria: { workouts_completed: 1 }
  },
  {
    id: 'workout_streak_7',
    title: 'Weekly Warrior',
    description: 'Complete workouts for 7 days straight',
    icon: '🔥',
    category: 'consistency',
    points: 50,
    type: 'streak',
    criteria: { workout_streak: 7 }
  },
  {
    id: 'first_5k',
    title: '5K Finisher',
    description: 'Complete your first 5K run',
    icon: '🏃‍♀️',
    category: 'running',
    points: 30,
    type: 'single',
    criteria: { single_run_distance: 5000 }
  }
])

print("MongoDB initialization completed successfully")
print("Created indexes for optimal query performance")
print("Inserted default configuration and achievement templates")