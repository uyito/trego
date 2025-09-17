# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Trego - Flutter Fitness & Nutrition Companion

Trego is a comprehensive Flutter mobile application with a Spring Boot backend for fitness tracking, nutrition management, and health monitoring. The app features Firebase integration, AI-powered recommendations, and real-time progress tracking.

## Architecture Overview

This is a **hybrid project** containing both Flutter frontend and Spring Boot backend:

### Frontend (Flutter)
- **Location**: Root directory (`/lib/`)
- **Framework**: Flutter 3.6+ with Dart SDK ^3.6.1
- **State Management**: Provider pattern with StatefulWidgets
- **Theme**: Material Design 3 with custom Nike-inspired theme (red, green, black)
- **Database**: Firebase Firestore for real-time data sync
- **Authentication**: Firebase Auth with social sign-in (Google, Apple)

### Backend (Spring Boot)
- **Location**: `/backend/` directory
- **Framework**: Spring Boot 3.2.0 with Java 17
- **Database**: Firebase Firestore (no traditional SQL database)
- **Authentication**: Firebase Auth + JWT tokens + Spring Security
- **Build Tool**: Maven with wrapper (`./mvnw`)
- **External APIs**: OpenAI for AI features, Stripe for premium features

## Key Development Commands

### Flutter Frontend Commands
```bash
# Run the Flutter app
flutter run

# Run on specific platform
flutter run -d chrome   # Web
flutter run -d android  # Android
flutter run -d ios      # iOS

# Install dependencies
flutter pub get

# Build for production
flutter build apk          # Android APK
flutter build appbundle    # Android App Bundle
flutter build ios          # iOS
flutter build web          # Web

# Testing and linting
flutter test               # Run tests
flutter test --coverage   # Run with coverage
flutter analyze           # Static analysis
```

### Spring Boot Backend Commands
```bash
# Navigate to backend directory first
cd backend

# Run the backend API
./mvnw spring-boot:run

# Run with specific profile
./mvnw spring-boot:run -Dspring-boot.run.profiles=development

# Testing
./mvnw test                    # Run all tests
./mvnw test -Dtest=ClassName   # Run specific test class
./mvnw verify                  # Run integration tests

# Build for production
./mvnw clean package           # Build JAR
./mvnw clean package -DskipTests  # Build without tests

# Docker deployment
docker-compose up --build      # Full stack with monitoring
```

## Project Structure

### Flutter App Structure
```
/lib/
├── auth/                    # Authentication screens and services
├── achievements/            # Achievement system and badges
├── navigation/             # Main app navigation
├── personalization/        # AI-powered recommendations
├── profile/               # User profile and settings
├── recipes/               # Recipe management and AI generation
├── shared/                # Common utilities, themes, API clients
├── social/                # Social features and challenges
├── tdee/                  # TDEE calculator
├── tracker/               # Run tracking and fitness monitoring
├── workouts/              # Workout plans and exercise library
└── widgets/               # Reusable UI components
```

### Backend Structure
```
backend/src/main/java/com/trego/
├── TregoApplication.java    # Main Spring Boot application
├── config/                 # Firebase and security configuration
├── controller/             # REST API endpoints
├── dto/                   # Data Transfer Objects
├── model/                 # Entity models (User, UserProfile, etc.)
├── repository/            # Firestore data access layer
├── security/              # Firebase Auth + JWT integration
└── service/               # Business logic services
```

## Configuration Files

### Firebase Setup
- **Backend**: Requires `backend/config/firebase-credentials.json` (service account key)
- **Frontend**: Platform-specific config files already included:
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`

### Environment Variables
Backend requires `.env` file in `backend/` directory with:
- `FIREBASE_PROJECT_ID`, `FIREBASE_CREDENTIALS_PATH`
- `JWT_SECRET`, `OPENAI_API_KEY`, `STRIPE_SECRET_KEY`
- See `backend/.env.example` for complete list

## Key Integration Points

### Flutter ↔ Backend Communication
- **API Client**: `lib/shared/api_client.dart` handles HTTP requests
- **Base URL**: Configured in `lib/shared/api_config.dart`
- **Authentication**: Firebase tokens are sent to backend for validation
- **Data Flow**: Flutter → Firebase Auth → Backend JWT validation → Firestore

### Firebase Integration
- **Authentication**: Shared between Flutter (client-side) and Spring Boot (server-side validation)
- **Database**: Firestore is accessed directly from Flutter and through backend services
- **Real-time**: Flutter uses Firestore streams for live data updates

## Testing Strategy

### Flutter Testing
- **Unit Tests**: Service layer testing in `test/` directory
- **Widget Tests**: UI component testing with `flutter_test`
- **Integration**: End-to-end testing for critical user flows

### Backend Testing
- **Unit Tests**: Service and controller testing with JUnit
- **Integration Tests**: Full API testing with TestContainers
- **Security Tests**: Authentication and authorization testing

## Development Workflow

### Working with Both Systems
1. **Backend First**: Start backend API for testing: `cd backend && ./mvnw spring-boot:run`
2. **Frontend Development**: Run Flutter app: `flutter run`
3. **API Testing**: Backend runs on `http://localhost:8080/api`
4. **Database**: Monitor Firestore through Firebase Console

### Key Architectural Patterns
- **Repository Pattern**: Used in backend for Firestore access
- **Service Layer**: Business logic separation in both Flutter and Spring Boot
- **DTO Pattern**: Data transfer between frontend/backend via standardized objects
- **Provider Pattern**: Flutter state management using Provider package

## Firebase Firestore Collections
- `users/` - User profiles and authentication data
- `users/{uid}/workouts/` - User workout logs and plans
- `users/{uid}/recipes/` - Saved recipes and meal plans
- `users/{uid}/tracking/` - Daily progress and metrics
- `users/{uid}/achievements/` - Unlocked achievements and badges

## Production Deployment

### Flutter Deployment
- **Android**: Build signed APK/AAB for Play Store
- **iOS**: Build through Xcode for App Store
- **Web**: Deploy built files to hosting service

### Backend Deployment
- **Docker**: Full production stack with `docker-compose.yml`
- **Monitoring**: Included Prometheus, Grafana, and health checks
- **Scaling**: Horizontal scaling via Docker Compose

## Important Notes for Development

### Firebase Rules
- Firestore security rules are crucial for data protection
- Users can only access their own data (`users/{uid}/`)
- Backend service account has elevated permissions for cross-user operations

### API Integration
- Flutter communicates with backend through REST APIs
- Authentication flow: Firebase Auth → Custom JWT for backend
- Error handling implemented in `lib/widgets/error_handler_widget.dart`

### Performance Considerations
- Use Firestore offline persistence for Flutter
- Implement proper pagination for large datasets
- Cache frequently accessed data in Flutter providers
- Backend includes rate limiting and monitoring