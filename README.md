# Trego - Fitness & Nutrition Companion

A comprehensive Flutter app for tracking fitness, nutrition, and health goals with Firebase integration.

## Features

- **Firebase Authentication** - Secure user sign-up and sign-in
- **TDEE Calculator** - Calculate Total Daily Energy Expenditure
- **Workout Tracking** - Log and track your workouts
- **Recipe Management** - Save and organize your favorite recipes
- **Progress Tracking** - Monitor weight, measurements, and goals
- **Cloud Firestore** - Real-time data synchronization

## Project Structure

```
/lib
 ├── /auth          # Authentication services and screens
 ├── /tdee          # TDEE calculation and management
 ├── /workouts      # Workout tracking and exercise library
 ├── /recipes       # Recipe management and meal planning
 ├── /tracker       # Progress tracking and goal management
 ├── /shared        # Shared models, configs, and utilities
 └── main.dart      # App entry point
```

## Setup Instructions

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Firebase project
- Android Studio / VS Code

### 1. Clone and Setup

```bash
# Navigate to the project directory
cd trego

# Install dependencies
flutter pub get
```

### 2. Firebase Setup

#### Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Enable Authentication and Cloud Firestore

#### Configure Authentication

1. In Firebase Console, go to Authentication > Sign-in method
2. Enable Email/Password authentication
3. Optionally enable other providers (Google, Apple, etc.)

#### Configure Cloud Firestore

1. In Firebase Console, go to Firestore Database
2. Create a new database
3. Start in test mode (for development)
4. Set up security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /{collection}/{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    match /{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

#### Add Firebase Configuration Files

**For Android:**
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`
3. Update `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

4. Update `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'
```

**For iOS:**
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/`
3. Add it to your Xcode project

**For Web:**
1. Add Firebase configuration to `web/index.html`:

```html
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-auth.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-firestore.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-analytics.js"></script>
```

### 3. Run the App

```bash
# Run on connected device/emulator
flutter run

# Run on specific platform
flutter run -d chrome  # Web
flutter run -d android # Android
flutter run -d ios     # iOS
```

## Dependencies

The app uses the following main dependencies:

- `firebase_core: ^3.6.0` - Firebase core functionality
- `firebase_auth: ^5.3.3` - Firebase Authentication
- `cloud_firestore: ^5.5.0` - Cloud Firestore database
- `firebase_analytics: ^11.3.3` - Firebase Analytics

## Development

### Adding New Features

1. Create appropriate service files in the relevant folder
2. Add models in the `shared` folder if needed
3. Create UI components following Material Design guidelines
4. Update navigation in `main.dart`

### Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## Deployment

### Android

```bash
# Build APK
flutter build apk

# Build App Bundle
flutter build appbundle
```

### iOS

```bash
# Build for iOS
flutter build ios
```

### Web

```bash
# Build for web
flutter build web
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions, please open an issue on GitHub.
