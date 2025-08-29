# Trego Backend API

A comprehensive Node.js/Express backend for the Trego fitness and nutrition application. This backend provides secure API endpoints, business logic services, social features, admin tools, and ML-powered personalization.

## 🚀 Features

### Phase 1: Core Infrastructure & Security
- **API Proxy Endpoints**: Secure OpenAI integration with rate limiting
- **Authentication**: Firebase Auth integration with JWT fallback
- **Rate Limiting**: User-based and endpoint-specific limits
- **Error Handling**: Comprehensive error management with logging
- **Caching**: Redis-based caching for performance optimization

### Phase 2: Business Logic Services
- **TDEE Calculator**: Complete metabolic rate calculation with recommendations
- **Achievement System**: Gamified experience with 25+ achievements
- **Workout Services**: AI-powered workout generation and tracking
- **Progress Tracking**: Comprehensive fitness and health monitoring

### Phase 3: Advanced Features
- **Social Platform**: Friends, challenges, posts, and community features
- **Admin Dashboard**: User management, content moderation, system analytics
- **Analytics**: Personal and comparative fitness analytics
- **Content Management**: Automated moderation with admin oversight

### Phase 4: ML Personalization
- **Recommendation Engine**: TensorFlow.js-powered workout recommendations
- **User Profiling**: Comprehensive behavioral and preference analysis
- **Adaptive Learning**: Feedback-driven personalization improvements
- **Advanced Analytics**: ML insights for goal optimization

## 📋 Prerequisites

- Node.js 18+ 
- MongoDB 6+
- Redis 6+
- Firebase project with Auth and Firestore
- OpenAI API key (optional - has fallback)

## 🛠 Installation & Setup

### 1. Environment Setup

```bash
# Clone and install dependencies
cd backend
npm install

# Copy environment template
cp .env.example .env
```

### 2. Configure Environment Variables

Edit `.env` with your configuration:

```env
# Server Configuration
NODE_ENV=development
PORT=3000
HOST=localhost

# Database
MONGODB_URI=mongodb://localhost:27017/trego
REDIS_URL=redis://localhost:6379

# Firebase Admin
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=your-firebase-client-email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----"

# OpenAI API
OPENAI_API_KEY=your-openai-api-key

# JWT Secret
JWT_SECRET=your-super-secret-jwt-key

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### 3. Database Setup

```bash
# Start MongoDB and Redis
brew services start mongodb/brew/mongodb-community
brew services start redis

# Or using Docker
docker run -d -p 27017:27017 --name mongo mongo:6
docker run -d -p 6379:6379 --name redis redis:6
```

### 4. Firebase Setup

1. Create Firebase project at https://console.firebase.google.com/
2. Enable Authentication (Email/Password, Google, Apple)
3. Create Firestore database in test mode
4. Generate service account key
5. Configure environment variables with Firebase credentials

## 🚀 Running the Application

```bash
# Development with auto-restart
npm run dev

# Production
npm start

# Run tests
npm test

# Lint code
npm run lint
```

The API will be available at `http://localhost:3000`

Health check: `http://localhost:3000/health`

## 📚 API Documentation

### Authentication Endpoints
```
POST   /api/auth/register          # Register new user
POST   /api/auth/login             # Login user
POST   /api/auth/firebase-sync     # Sync Firebase user
GET    /api/auth/profile           # Get user profile
PUT    /api/auth/profile           # Update user profile
POST   /api/auth/logout            # Logout user
```

### Core Features
```
# Recipe Generation (AI-powered)
POST   /api/recipes/generate                    # Generate personalized recipe
POST   /api/recipes/analyze-nutrition          # Analyze food nutrition
POST   /api/recipes/meal-plan                  # Generate weekly meal plan (Premium)
GET    /api/recipes/usage                      # Get AI usage stats

# TDEE & Nutrition
POST   /api/tdee/calculate                     # Complete TDEE calculation
POST   /api/tdee/bmr                          # BMR calculation only
POST   /api/tdee/progress                     # Track body measurements
GET    /api/tdee/progress                     # Get progress history
GET    /api/tdee/options                      # Get form options
POST   /api/tdee/macros                       # Calculate macro targets

# Workout Management
POST   /api/workouts/generate                  # Generate AI workout
POST   /api/workouts/complete                  # Track workout completion
GET    /api/workouts/history                   # Get workout history
GET    /api/workouts/stats                     # Get workout statistics
GET    /api/workouts/recommendations           # Get recommended workouts
GET    /api/workouts/exercises/search          # Search exercises
GET    /api/workouts/exercises/:id             # Get exercise details
```

### Tracking & Analytics
```
# Progress Tracking
POST   /api/tracker/daily-log                  # Save daily log
GET    /api/tracker/daily-log/:date           # Get daily log
POST   /api/tracker/runs                      # Track run/exercise
GET    /api/tracker/runs                      # Get run history
GET    /api/tracker/weekly-summary            # Get weekly summary
GET    /api/tracker/dashboard                 # Get dashboard overview

# Analytics
GET    /api/analytics/personal                # Personal analytics
GET    /api/analytics/comparative             # Compare with friends/community
GET    /api/analytics/goals                   # Goal tracking analytics
```

### Achievement System
```
GET    /api/achievements                      # Get user achievements
POST   /api/achievements/check                # Check for new achievements
GET    /api/achievements/next-goals           # Get next achievement goals
GET    /api/achievements/all                  # Get all available achievements
GET    /api/achievements/leaderboard          # Get leaderboard
POST   /api/achievements/share/:id            # Share achievement
GET    /api/achievements/:id                  # Get specific achievement
```

### Social Features
```
# Friends & Social
GET    /api/social/profile                    # Get social profile
POST   /api/social/friends/request            # Send friend request
POST   /api/social/friends/respond/:id        # Respond to friend request
GET    /api/social/friends                    # Get friends list

# Challenges
POST   /api/social/challenges                 # Create challenge
POST   /api/social/challenges/:id/join        # Join challenge
GET    /api/social/challenges                 # Get challenges

# Posts & Feed
POST   /api/social/posts                      # Create post
GET    /api/social/feed                       # Get social feed
POST   /api/social/posts/:id/like            # Like/unlike post

# Notifications
GET    /api/social/notifications              # Get notifications
POST   /api/social/notifications/mark-read   # Mark notifications as read
```

### ML Personalization
```
GET    /api/personalization/workouts          # Personalized workout recommendations
GET    /api/personalization/nutrition         # Personalized nutrition recommendations
GET    /api/personalization/profile           # Get personalization profile
GET    /api/personalization/advanced-recommendations  # Advanced ML recommendations (Premium)
POST   /api/personalization/feedback          # Provide recommendation feedback
GET    /api/personalization/insights          # Get personalization insights
```

### Admin Features
```
GET    /api/admin/dashboard                   # Admin dashboard overview
GET    /api/admin/users                      # User management
PUT    /api/admin/users/:id/status           # Update user status
GET    /api/admin/content/moderation         # Content moderation queue
PUT    /api/admin/content/:type/:id/moderate # Moderate content
GET    /api/admin/analytics                  # System analytics
GET    /api/admin/logs                       # Admin action logs
GET    /api/admin/config                     # System configuration
PUT    /api/admin/config                     # Update system configuration
```

## 🏗 Architecture

### Tech Stack
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Cache**: Redis
- **Authentication**: Firebase Auth + JWT
- **ML/AI**: TensorFlow.js + OpenAI API
- **Logging**: Winston
- **Testing**: Jest + Supertest

### Project Structure
```
src/
├── app.js                 # Main application entry
├── config/                # Configuration files
│   ├── database.js        # MongoDB connection
│   ├── redis.js           # Redis connection
│   └── firebase.js        # Firebase Admin SDK
├── controllers/           # Route controllers
├── middleware/            # Custom middleware
│   ├── auth.js            # Authentication middleware
│   └── errorHandler.js    # Global error handler
├── models/                # Database models
├── routes/                # API route definitions
│   ├── auth.js            # Authentication routes
│   ├── recipes.js         # Recipe management
│   ├── tdee.js            # TDEE calculations
│   ├── workouts.js        # Workout management
│   ├── tracker.js         # Progress tracking
│   ├── achievements.js    # Achievement system
│   ├── social.js          # Social features
│   ├── admin.js           # Admin panel
│   ├── analytics.js       # Analytics endpoints
│   └── personalization.js # ML recommendations
├── services/              # Business logic services
│   ├── ai/                # AI/ML services
│   │   ├── openaiService.js      # OpenAI integration
│   │   └── personalizationService.js # ML recommendations
│   ├── fitness/           # Fitness services
│   │   ├── achievementService.js  # Achievement logic
│   │   └── workoutService.js      # Workout generation
│   └── nutrition/         # Nutrition services
│       └── tdeeService.js         # TDEE calculations
├── utils/                 # Utility functions
│   └── logger.js          # Winston logger configuration
└── scripts/               # Utility scripts
    └── migrate.js         # Database migrations
```

### Security Features
- Firebase Authentication integration
- JWT token validation
- Rate limiting (per user/endpoint)
- Request validation with express-validator
- Helmet.js security headers
- CORS configuration
- Input sanitization
- Secure password handling with bcrypt

### Performance Optimizations
- Redis caching for frequently accessed data
- MongoDB connection pooling
- Compressed responses
- Request rate limiting
- Efficient database queries with proper indexing
- Background task processing for heavy operations

## 🧪 Testing

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch

# Lint code
npm run lint

# Fix linting issues
npm run lint:fix
```

## 📊 Monitoring & Logging

### Logging
- Winston logger with multiple transports
- Structured logging with metadata
- Error tracking with stack traces
- Request/response logging
- Performance metrics

### Health Checks
- Database connectivity
- Redis connectivity
- External API availability
- System resource usage

### Metrics
- API request counts and response times
- User activity patterns
- Achievement completion rates
- Recommendation accuracy
- System performance metrics

## 🚀 Deployment

### Environment Setup
1. Set `NODE_ENV=production`
2. Configure production database URLs
3. Set up SSL certificates
4. Configure load balancers
5. Set up monitoring and alerting

### Docker Deployment
```bash
# Build Docker image
npm run docker:build

# Run with Docker Compose
docker-compose up -d
```

### Production Checklist
- [ ] Environment variables configured
- [ ] Database migrations run
- [ ] SSL certificates installed
- [ ] Monitoring systems active
- [ ] Backup procedures in place
- [ ] Load testing completed
- [ ] Security audit performed

## 🔧 Configuration

### Rate Limiting
```javascript
// Per-user rate limits
recipeGeneration: { requests: 50, window: 3600 }    // 50 requests per hour
nutritionAnalysis: { requests: 100, window: 3600 }  // 100 requests per hour
workoutPlanning: { requests: 30, window: 3600 }     // 30 requests per hour
```

### Caching Strategy
- User profiles: 24 hours
- TDEE calculations: 24 hours
- Recipe data: 7 days
- Achievement data: 1 hour
- System metrics: 5 minutes

### Database Indexes
```javascript
// Recommended MongoDB indexes
db.users.createIndex({ "email": 1 }, { unique: true })
db.daily_logs.createIndex({ "userId": 1, "date": -1 })
db.workout_completions.createIndex({ "userId": 1, "completedAt": -1 })
db.runs.createIndex({ "userId": 1, "completedAt": -1 })
db.achievements.createIndex({ "userId": 1, "earnedAt": -1 })
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow ESLint configuration
- Write tests for new features
- Update documentation
- Use semantic commit messages
- Ensure all tests pass before submitting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the API endpoints
- Check logs for error messages

## 🔄 Changelog

### Version 1.0.0
- Initial release with all core features
- AI-powered recipe generation
- Comprehensive achievement system
- Social features and challenges
- ML-powered personalization
- Admin dashboard and analytics
- Complete API documentation