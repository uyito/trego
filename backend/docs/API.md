# Trego Backend API Documentation

## Overview

The Trego Backend API provides comprehensive endpoints for fitness tracking, nutrition management, social features, and ML-powered personalization. All endpoints require authentication unless otherwise specified.

## Base URL

- Development: `http://localhost:3000`
- Production: `https://api.trego.app`

## Authentication

### Headers
```
Authorization: Bearer <token>
Content-Type: application/json
```

### Token Types
1. **Firebase ID Token**: Obtained from Firebase Auth SDK
2. **JWT Token**: Issued by backend after authentication

### Authentication Flow
```javascript
// Firebase Authentication
const idToken = await user.getIdToken();

// Sync with backend
const response = await fetch('/api/auth/firebase-sync', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ idToken })
});

const { token } = await response.json();
// Use this token for subsequent API calls
```

## Error Handling

### Error Response Format
```json
{
  "error": "Error type",
  "message": "Human readable error message",
  "details": ["Validation error details if applicable"],
  "type": "error_category",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `429` - Too Many Requests
- `500` - Internal Server Error

## Rate Limiting

### Limits by Endpoint Category

| Service | Requests | Window | Notes |
|---------|----------|--------|--------|
| Recipe Generation | 50 | 1 hour | AI-powered endpoints |
| Nutrition Analysis | 100 | 1 hour | OpenAI integration |
| Workout Planning | 30 | 1 hour | Complex ML processing |
| General API | 1000 | 1 hour | Standard endpoints |
| Authentication | 10 | 1 minute | Login/register |

### Rate Limit Headers
```
X-RateLimit-Limit: 50
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1640995200
```

## API Endpoints

### Authentication

#### Register User
```http
POST /api/auth/register
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123",
  "name": "John Doe",
  "age": 30,
  "gender": "male"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "token": "jwt_token_here",
  "user": {
    "uid": "user_id",
    "email": "user@example.com",
    "name": "John Doe",
    "subscription": "free"
  }
}
```

#### Login User
```http
POST /api/auth/login
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123"
}
```

#### Firebase Sync
```http
POST /api/auth/firebase-sync
```

**Request Body:**
```json
{
  "idToken": "firebase_id_token"
}
```

#### Get Profile
```http
GET /api/auth/profile
```

**Response:**
```json
{
  "success": true,
  "user": {
    "uid": "user_id",
    "email": "user@example.com",
    "name": "John Doe",
    "age": 30,
    "gender": "male",
    "subscription": "free",
    "preferences": {
      "units": "metric",
      "notifications": true,
      "privacy": "friends"
    }
  }
}
```

### Recipe Management

#### Generate Recipe
```http
POST /api/recipes/generate
```

**Request Body:**
```json
{
  "dietaryPreference": "vegetarian",
  "mealType": "dinner",
  "calories": 500,
  "ingredients": "chicken, broccoli, rice",
  "allergens": ["nuts", "dairy"],
  "cuisine": "italian",
  "cookingTime": 30,
  "difficulty": "medium"
}
```

**Response:**
```json
{
  "success": true,
  "recipe": {
    "name": "Vegetarian Pasta Primavera",
    "description": "A delicious vegetarian pasta with fresh vegetables",
    "calories": 485,
    "servings": 1,
    "prepTime": "15 minutes",
    "cookTime": "20 minutes",
    "difficulty": "medium",
    "ingredients": [
      {
        "item": "whole wheat pasta",
        "amount": "100",
        "unit": "g",
        "calories": 350
      }
    ],
    "instructions": [
      "Boil water in a large pot",
      "Cook pasta according to package directions",
      "Sauté vegetables in olive oil"
    ],
    "nutrition": {
      "calories": 485,
      "protein": "18g",
      "carbs": "75g",
      "fat": "12g",
      "fiber": "8g"
    },
    "tags": ["vegetarian", "dinner"],
    "tips": ["Add herbs for extra flavor"]
  }
}
```

#### Analyze Nutrition
```http
POST /api/recipes/analyze-nutrition
```

**Request Body:**
```json
{
  "foodText": "1 cup cooked quinoa with vegetables"
}
```

#### Get Usage Stats
```http
GET /api/recipes/usage
```

**Response:**
```json
{
  "success": true,
  "usage": {
    "recipeGeneration": {
      "used": 15,
      "limit": 50,
      "window": 3600
    },
    "nutritionAnalysis": {
      "used": 8,
      "limit": 100,
      "window": 3600
    }
  }
}
```

### TDEE & Nutrition

#### Calculate TDEE
```http
POST /api/tdee/calculate
```

**Request Body:**
```json
{
  "age": 30,
  "gender": "male",
  "weight": 75,
  "height": 180,
  "activityLevel": "moderately_active",
  "goal": "lose_weight",
  "weightUnit": "kg",
  "heightUnit": "cm",
  "macroTemplate": "high_protein"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "bmr": 1750,
    "tdee": 2713,
    "targetCalories": 2306,
    "macros": {
      "protein": {
        "percentage": 0.35,
        "calories": 807,
        "grams": 202
      },
      "carbs": {
        "percentage": 0.35,
        "calories": 807,
        "grams": 202
      },
      "fat": {
        "percentage": 0.30,
        "calories": 692,
        "grams": 77
      }
    },
    "recommendations": [
      {
        "type": "hydration",
        "title": "Daily Water Intake",
        "value": "2767ml (11 glasses)",
        "description": "Adequate hydration is crucial for metabolism"
      }
    ],
    "metadata": {
      "calculatedAt": "2024-01-01T00:00:00.000Z"
    }
  }
}
```

#### Track Progress
```http
POST /api/tdee/progress
```

**Request Body:**
```json
{
  "weight": 74.5,
  "bodyFat": 15.2,
  "measurements": {
    "waist": 85,
    "chest": 102,
    "arms": 38,
    "thighs": 58
  }
}
```

### Workout Management

#### Generate Workout
```http
POST /api/workouts/generate
```

**Request Body:**
```json
{
  "fitnessLevel": "intermediate",
  "goals": ["strength", "muscle_gain"],
  "duration": 45,
  "equipment": ["dumbbells", "bodyweight"],
  "preferences": ["upper_body"],
  "focusAreas": ["chest", "shoulders"]
}
```

**Response:**
```json
{
  "success": true,
  "workout": {
    "name": "Upper Body Strength Builder",
    "duration": 45,
    "difficulty": "intermediate",
    "exercises": [
      {
        "name": "Push-ups",
        "type": "strength",
        "duration": "30 seconds",
        "reps": "12-15",
        "sets": 3,
        "restTime": "60 seconds",
        "instructions": "Keep core tight throughout movement",
        "targetMuscles": ["chest", "shoulders", "triceps"]
      }
    ],
    "warmup": [
      {
        "exercise": "Arm circles",
        "duration": "2 minutes"
      }
    ],
    "cooldown": [
      {
        "exercise": "Chest stretch",
        "duration": "3 minutes"
      }
    ]
  }
}
```

#### Complete Workout
```http
POST /api/workouts/complete
```

**Request Body:**
```json
{
  "workoutId": "optional_workout_id",
  "duration": 42,
  "exercises": [
    {
      "name": "Push-ups",
      "completed": true,
      "reps": 15,
      "sets": 3,
      "notes": "Felt strong today"
    }
  ],
  "caloriesBurned": 320,
  "difficulty": "medium",
  "notes": "Great workout!"
}
```

### Achievement System

#### Get User Achievements
```http
GET /api/achievements
```

**Response:**
```json
{
  "success": true,
  "data": {
    "summary": {
      "earned": ["first_workout", "workout_streak_7"],
      "totalPoints": 60,
      "totalAchievements": 2
    },
    "earned": [
      {
        "id": "first_workout",
        "title": "First Steps",
        "description": "Complete your first workout",
        "icon": "🏃‍♂️",
        "points": 10,
        "earnedAt": "2024-01-01T00:00:00.000Z"
      }
    ],
    "categories": [
      {
        "id": "getting_started",
        "name": "Getting Started",
        "icon": "🌱",
        "progress": {
          "earned": 1,
          "total": 3
        }
      }
    ]
  }
}
```

#### Check Achievements
```http
POST /api/achievements/check
```

**Request Body:**
```json
{
  "activityData": {
    "workouts_completed": 1,
    "workout_streak": 7,
    "total_distance": 5000,
    "calories_logged": 1
  }
}
```

### Social Features

#### Send Friend Request
```http
POST /api/social/friends/request
```

**Request Body:**
```json
{
  "friendId": "user_id_to_add",
  "message": "Let's workout together!"
}
```

#### Create Challenge
```http
POST /api/social/challenges
```

**Request Body:**
```json
{
  "title": "30-Day Fitness Challenge",
  "description": "Complete 30 workouts in 30 days",
  "type": "workouts",
  "target": 30,
  "duration": 30,
  "isPublic": true,
  "maxParticipants": 50
}
```

#### Create Post
```http
POST /api/social/posts
```

**Request Body:**
```json
{
  "content": "Just completed my best workout yet! 💪",
  "type": "workout",
  "attachments": ["image_url"],
  "visibility": "friends"
}
```

### Tracking & Analytics

#### Save Daily Log
```http
POST /api/tracker/daily-log
```

**Request Body:**
```json
{
  "date": "2024-01-01",
  "calories": 2150,
  "water": 2500,
  "weight": 74.5,
  "steps": 8500,
  "sleep": 7.5,
  "mood": 8,
  "notes": "Feeling great today!"
}
```

#### Track Run
```http
POST /api/tracker/runs
```

**Request Body:**
```json
{
  "distance": 5.2,
  "duration": 1800,
  "calories": 400,
  "averagePace": 346,
  "route": [
    {"lat": 37.7749, "lng": -122.4194, "timestamp": "2024-01-01T10:00:00Z"},
    {"lat": 37.7750, "lng": -122.4195, "timestamp": "2024-01-01T10:00:30Z"}
  ],
  "weather": {
    "temperature": 18,
    "condition": "sunny",
    "humidity": 65
  },
  "notes": "Beautiful morning run!"
}
```

#### Get Weekly Summary
```http
GET /api/tracker/weekly-summary?date=2024-01-01
```

#### Get Dashboard
```http
GET /api/tracker/dashboard
```

### Personalization (ML-Powered)

#### Get Personalized Workouts
```http
GET /api/personalization/workouts?count=5&refreshProfile=true
```

**Response:**
```json
{
  "success": true,
  "data": {
    "recommendations": [
      {
        "name": "Personalized HIIT Session",
        "duration": 30,
        "difficulty": "intermediate",
        "score": 0.89,
        "confidence": 0.85,
        "reasoning": "Matches your cardio preferences and available time"
      }
    ],
    "personalizationLevel": "high"
  }
}
```

#### Get Nutrition Recommendations
```http
GET /api/personalization/nutrition
```

#### Provide Feedback
```http
POST /api/personalization/feedback
```

**Request Body:**
```json
{
  "recommendationId": "rec_123",
  "feedback": "liked",
  "rating": 5,
  "comments": "Perfect workout for my schedule!"
}
```

### Admin Features (Admin Only)

#### Get Dashboard
```http
GET /api/admin/dashboard
```

#### Manage Users
```http
GET /api/admin/users?limit=20&status=active
PUT /api/admin/users/{userId}/status
```

#### Content Moderation
```http
GET /api/admin/content/moderation?type=posts&status=pending
PUT /api/admin/content/posts/{postId}/moderate
```

## Webhooks

### Stripe Webhooks (Premium Features)
```http
POST /api/webhooks/stripe
```

Handle subscription events for premium features.

### Achievement Notifications
```http
POST /api/webhooks/achievements
```

Trigger push notifications for achievement unlocks.

## SDK Integration

### JavaScript/TypeScript
```javascript
import { TregoAPI } from '@trego/api-client';

const api = new TregoAPI({
  baseURL: 'https://api.trego.app',
  token: 'your_auth_token'
});

// Generate workout
const workout = await api.workouts.generate({
  fitnessLevel: 'intermediate',
  duration: 30
});

// Track completion
await api.workouts.complete({
  duration: 32,
  exercises: workout.exercises.map(ex => ({
    name: ex.name,
    completed: true
  }))
});
```

### Flutter/Dart Integration
```dart
import 'package:dio/dio.dart';

class TregoApiClient {
  final Dio _dio;
  
  TregoApiClient(String token) : _dio = Dio() {
    _dio.options.baseUrl = 'https://api.trego.app';
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  Future<WorkoutResponse> generateWorkout(WorkoutRequest request) async {
    final response = await _dio.post('/api/workouts/generate', 
      data: request.toJson());
    return WorkoutResponse.fromJson(response.data);
  }
}
```

## Testing

### Health Check
```bash
curl -X GET https://api.trego.app/health
```

### Authentication Test
```bash
curl -X POST https://api.trego.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass"}'
```

### Rate Limit Test
```bash
for i in {1..60}; do
  curl -X GET https://api.trego.app/api/recipes/usage \
    -H "Authorization: Bearer YOUR_TOKEN" &
done
wait
```

## Best Practices

### Error Handling
```javascript
try {
  const response = await api.post('/api/workouts/generate', data);
  return response.data;
} catch (error) {
  if (error.response?.status === 429) {
    // Handle rate limit
    const retryAfter = error.response.headers['retry-after'];
    await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
    return api.post('/api/workouts/generate', data);
  }
  throw error;
}
```

### Caching Recommendations
```javascript
// Cache personalized recommendations
const cacheKey = `recommendations:${userId}:${Date.now()}`;
localStorage.setItem(cacheKey, JSON.stringify(recommendations));
```

### Batch Operations
```javascript
// Batch multiple daily log updates
const logs = await Promise.all([
  api.tracker.saveDailyLog(todayLog),
  api.tracker.saveDailyLog(yesterdayLog)
]);
```

## Support

- **Documentation**: https://docs.trego.app
- **API Status**: https://status.trego.app
- **Support**: support@trego.app
- **GitHub Issues**: https://github.com/trego/backend/issues