import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trego/auth/auth_service.dart';
import 'package:trego/auth/social_sign_in_buttons.dart';

import '../helpers/test_app.dart';

/// A Firebase-free stand-in for [AuthService]. `implements` (rather than
/// `extends`) never invokes AuthService's own constructor, so its
/// `FirebaseAuth.instance` field initializer never runs — this lets the
/// widget render in a test host with no Firebase app. Only the public API
/// surface needs implementing; AuthService's fields are private to its own
/// library and aren't part of this interface.
class _FakeAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> resetPassword(String email) => throw UnimplementedError();

  @override
  Future<void> updateUserProfile({required String name, String? photoURL}) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<UserCredential> signInWithApple() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

void main() {
  initTestEnv();

  testWidgets('SocialSignInButtons renders Google and Apple buttons', (tester) async {
    // Apple button only renders on iOS/macOS — force it for determinism
    // regardless of the host running the test suite.
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    try {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: SocialSignInButtons(
              authService: _FakeAuthService(),
              onSuccess: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });
}
