# Trego - Flutter Fitness & Nutrition Companion

Trego is a comprehensive Flutter mobile application designed to help users track their fitness journey, manage nutrition, and achieve their health goals. The app integrates with Firebase for authentication and real-time data synchronization.

## What the App Does

### Core Functionality

**Fitness Tracking**
- **Dashboard**: Central hub displaying daily metrics including calories consumed, water intake, distance traveled, and workout streaks
- **Run Tracking**: GPS-enabled live run tracking with distance, pace, and route mapping using Google Maps
- **Workout Planning**: Custom workout plans with exercise libraries and progress tracking
- **Achievement System**: Gamified experience with badges and milestones to motivate users

**Nutrition Management**
- **TDEE Calculator**: Calculate Total Daily Energy Expenditure based on age, gender, height, weight, activity level, and goals
- **Recipe Management**: AI-powered recipe generation using OpenAI API based on dietary preferences, meal types, and calorie targets
- **Calorie Tracking**: Daily calorie intake monitoring with goals and progress visualization

**Health Monitoring**
- **Water Intake Tracking**: Daily hydration goals with visual progress indicators
- **Weight Tracking**: Historical weight data with trends and goal setting
- **Weekly Summaries**: Comprehensive weekly recaps showing progress across all metrics

### Technical Architecture

**Frontend (Flutter)**
- Material Design 3 with custom Nike-inspired theme (red, green, black color scheme)
- Cross-platform support (iOS, Android, Web)
- Animated UI components with smooth transitions
- Responsive design with proper state management

**Backend Integration**
- **Firebase Authentication**: Email/password, Google Sign-In, Apple Sign-In
- **Cloud Firestore**: Real-time database for user data, workout logs, recipes, and progress tracking
- **Firebase Analytics**: User behavior tracking and app performance monitoring

**Key Features**
- **GPS Integration**: Real-time location tracking for runs using Geolocator
- **Camera Integration**: Photo capture for recipe scanning and progress photos
- **Push Notifications**: Local notifications for workout reminders and goal achievements
- **Health Kit Integration**: Access to device health data (iOS Health app, Android health sensors)
- **Maps Integration**: Google Maps for route visualization and tracking

### Main Screens

1. **Dashboard**: Main hub with daily metrics, quick actions, and progress overview
2. **Workout Plans**: Exercise library, custom workout creation, and progress tracking
3. **Recipes**: AI-generated recipes based on nutritional needs and preferences
4. **TDEE Calculator**: Comprehensive metabolic rate calculation and goal setting
5. **Profile**: User settings, achievements, and account management
6. **Run Tracker**: Live GPS tracking with real-time metrics and route mapping

### Data Models

**User Data**
- Personal information (age, gender, height, weight)
- Fitness goals and preferences
- TDEE calculations and calorie targets
- Achievement progress and workout streaks

**Tracking Data**
- Daily logs (calories, water, workouts, measurements)
- Run history with GPS data and performance metrics
- Weekly and monthly progress summaries
- Recipe favorites and meal plans

### Technology Stack

- **Framework**: Flutter 3.6+ with Dart
- **State Management**: StatefulWidgets with AnimationControllers
- **Database**: Firebase Cloud Firestore
- **Authentication**: Firebase Auth with social sign-in
- **Maps**: Google Maps Flutter plugin
- **HTTP**: HTTP package for API calls
- **AI Integration**: OpenAI API for recipe generation
- **Local Storage**: Device preferences and cached data

### Development Setup

The app requires:
- Flutter SDK (latest stable)
- Firebase project with Authentication and Firestore enabled
- Google Maps API key
- OpenAI API key (optional, has mock data fallback)
- Platform-specific configuration files (google-services.json for Android, GoogleService-Info.plist for iOS)

### App Flow

1. **Authentication**: Users sign up/login via email or social providers
2. **Onboarding**: Initial profile setup and goal configuration
3. **Dashboard**: Daily tracking hub with quick access to all features
4. **Activity Tracking**: Log workouts, runs, meals, and measurements
5. **Progress Monitoring**: View trends, achievements, and weekly summaries
6. **Goal Adjustment**: Update targets based on progress and preferences

The app follows a modular architecture with separate services for each feature domain (auth, tracking, workouts, recipes, etc.) and shared utilities for common functionality like themes, notifications, and Firebase configuration.