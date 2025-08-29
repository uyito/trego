import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

class FirebaseTest {
  static Future<void> testFirebaseConnection() async {
    try {
      print('Testing Firebase connection...');
      
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      print('✅ Firebase initialized successfully');

      // Test Firestore connection
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').doc('connection').get();
      
      print('✅ Firestore connection successful');

      // Test Auth connection
      final auth = FirebaseAuth.instance;
      print('✅ Firebase Auth initialized');
      print('Current user: ${auth.currentUser?.email ?? 'No user logged in'}');

    } catch (e) {
      print('❌ Firebase connection failed: $e');
      rethrow;
    }
  }
} 