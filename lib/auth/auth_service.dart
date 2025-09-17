import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import '../shared/api_client.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiClient _apiClient = ApiClient.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize auth service and sync with backend
  Future<void> initialize() async {
    await _apiClient.loadAuthToken();
    
    // Listen to auth state changes and sync with backend
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _syncWithBackend();
      } else {
        await _apiClient.clearAuthToken();
      }
    });
  }

  // Sync Firebase user with backend using login endpoint
  Future<void> _syncWithBackend() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final idToken = await user.getIdToken();
      
      // Use the backend login endpoint to sync Firebase user
      final response = await _apiClient.post('/auth/login', data: {
        'idToken': idToken,
        'provider': 'firebase',
      });

      if (response.data['success'] == true || response.data['token'] != null) {
        final backendToken = response.data['token'];
        await _apiClient.setAuthToken(backendToken);
        print('Successfully synced with backend using /auth/login');
      }
    } catch (e) {
      print('Failed to sync with backend: $e');
      // Continue with Firebase-only flow
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // First, register with backend
      await _apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });

      // Then create Firebase user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update Firebase profile
      if (result.user != null) {
        await result.user!.updateDisplayName(name);
        
        // Create user profile in Firestore
        await _firestore.collection('users').doc(result.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Sync with backend to get JWT token
        await _syncWithBackend();
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Try backend login first for validation and JWT token
      try {
        final response = await _apiClient.post('/auth/login', data: {
          'email': email,
          'password': password,
        });

        if (response.data['token'] != null) {
          await _apiClient.setAuthToken(response.data['token']);
        }
      } catch (backendError) {
        print('Backend login failed, continuing with Firebase: $backendError');
      }

      // Sign in with Firebase
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sync with backend using Firebase token if backend login failed
      if (result.user != null) {
        await _syncWithBackend();
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String name,
    String? photoURL,
  }) async {
    try {
      await _auth.currentUser?.updateDisplayName(name);
      if (photoURL != null) {
        await _auth.currentUser?.updatePhotoURL(photoURL);
      }

      // Update in Firestore
      if (_auth.currentUser != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          'name': name,
          'photoURL': photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In process...');
      
      // For web platform, check if client ID is configured
      if (kIsWeb) {
        print('Running on web platform');
      }
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google sign in was cancelled by user');
        throw Exception('Google sign in was cancelled');
      }

      return await _completeGoogleSignIn(googleUser);
    } catch (e) {
      print('Google Sign-In error: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      
      // For web, provide a more helpful error message
      if (kIsWeb && e.toString().contains('ClientID not set')) {
        throw Exception('Google Sign-In not configured for web. Please check the client ID configuration.');
      }
      
      rethrow;
    }
  }

  // Helper method to complete Google sign-in
  Future<UserCredential> _completeGoogleSignIn(GoogleSignInAccount googleUser) async {
    print('Google user obtained: ${googleUser.email}');

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    print('Google authentication obtained - ID Token: ${googleAuth.idToken != null ? 'Present' : 'Missing'}');

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    print('Firebase credential created');

    // Sign in to Firebase with the credential
    final userCredential = await _auth.signInWithCredential(credential);
    print('Firebase sign in successful: ${userCredential.user?.email}');

    // Create or update user profile in Firestore
    if (userCredential.user != null) {
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName ?? googleUser.displayName,
          'email': userCredential.user!.email,
          'photoURL': userCredential.user!.photoURL,
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('User profile saved to Firestore');
      } catch (firestoreError) {
        print('Firestore error (non-critical): $firestoreError');
        // Don't rethrow - user is still signed in, just profile wasn't saved
      }

      // Sync with backend to get JWT token
      await _syncWithBackend();
    }

    return userCredential;
  }

  // Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    try {
      // Check if Apple Sign In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign In is not available on this device');
      }

      // Request credential for the currently signed in Apple account
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an `OAuthCredential` from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Create or update user profile in Firestore
      if (userCredential.user != null) {
        try {
          final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
          
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'name': displayName.isNotEmpty ? displayName : userCredential.user!.displayName,
            'email': userCredential.user!.email,
            'provider': 'apple',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('User profile saved to Firestore');
        } catch (firestoreError) {
          print('Firestore error (non-critical): $firestoreError');
          // Don't rethrow - user is still signed in, just profile wasn't saved
        }

        // Sync with backend to get JWT token
        await _syncWithBackend();
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out from all providers
  Future<void> signOut() async {
    try {
      // Notify backend of logout (optional - JWT will expire anyway)
      try {
        await _apiClient.post('/auth/logout');
      } catch (e) {
        print('Backend logout failed: $e');
      }

      // Clear backend token
      await _apiClient.clearAuthToken();
      
      // Sign out from social providers
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
} 