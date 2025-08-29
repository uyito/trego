import 'package:flutter/material.dart';
import 'package:trego/auth/auth_service.dart';

class SocialSignInButtons extends StatelessWidget {
  final AuthService authService;
  final VoidCallback? onSuccess;
  final bool isLoading;

  const SocialSignInButtons({
    super.key,
    required this.authService,
    this.onSuccess,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Sign-In Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isLoading ? null : () => _handleGoogleSignIn(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.g_mobiledata,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Apple Sign-In Button
        if (Theme.of(context).platform == TargetPlatform.iOS || 
            Theme.of(context).platform == TargetPlatform.macOS)
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isLoading ? null : () => _handleAppleSignIn(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.apple,
                        size: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Apple',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      print('SocialSignInButtons: Starting Google Sign-In...');
      await authService.signInWithGoogle();
      print('SocialSignInButtons: Google Sign-In successful');
      if (onSuccess != null) {
        onSuccess!();
      }
    } catch (e) {
      print('SocialSignInButtons: Google Sign-In error: $e');
      if (context.mounted) {
        String errorMessage = 'Google sign in failed';
        
        if (e.toString().contains('cancelled')) {
          errorMessage = 'Sign in was cancelled';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection';
        } else if (e.toString().contains('popup_closed')) {
          errorMessage = 'Sign in popup was closed';
        } else if (e.toString().contains('sign_in_failed')) {
          errorMessage = 'Google Sign-In failed. Please try again.';
        } else if (e.toString().contains('invalid_client')) {
          errorMessage = 'Google Sign-In not configured properly. Please contact support.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    try {
      await authService.signInWithApple();
      if (onSuccess != null) {
        onSuccess!();
      }
    } catch (e) {
      if (context.mounted) {
        String errorMessage = 'Apple sign in failed';
        
        if (e.toString().contains('cancelled')) {
          errorMessage = 'Sign in was cancelled';
        } else if (e.toString().contains('not available')) {
          errorMessage = 'Apple Sign In is not available on this device';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
} 