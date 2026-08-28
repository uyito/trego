import 'package:flutter/material.dart';
import 'package:trego/auth/auth_service.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';

/// Brand-mandated colors for the Google and Apple sign-in buttons. Google
/// and Apple's sign-in guidelines require these exact fills/marks — they
/// are NOT part of the app's token palette and must not shift with theme.
class _SocialBrand {
  static const googleSurface = Color(0xFFFFFFFF); // ALLOW-HEX: Google brand guideline (white button surface)
  static const googleGlyph = Color(0xFFEA4335); // ALLOW-HEX: Google brand guideline ("G" mark red)
  static const googleLabel = Color(0xFF1F2937); // ALLOW-HEX: Google brand guideline (button label ink)
  static const appleSurface = Color(0xFF000000); // ALLOW-HEX: Apple brand guideline (black button surface)
  static const appleLabel = Color(0xFFFFFFFF); // ALLOW-HEX: Apple brand guideline (white label/mark on black)
  _SocialBrand._();
}

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
    final tokens = context.tokens;
    return Column(
      children: [
        // Google Sign-In Button. Fill/glyph colors are Google
        // brand-mandated (see _SocialBrand) and are not tokenized.
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: _SocialBrand.googleSurface,
            borderRadius: BorderRadius.circular(Radii.button),
            border: Border.all(color: tokens.border),
            boxShadow: [
              BoxShadow(
                // ALLOW-HEX: const-required shadow tint, not a themed surface color
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.button),
              onTap: isLoading ? null : () => _handleGoogleSignIn(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _SocialBrand.googleSurface,
                      ),
                      child: const Icon(
                        Icons.g_mobiledata,
                        size: 20,
                        color: _SocialBrand.googleGlyph,
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Text(
                      'Continue with Google',
                      style: context.typo.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _SocialBrand.googleLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.lg),

        // Apple Sign-In Button. Fill/label colors are Apple
        // brand-mandated (see _SocialBrand) and are not tokenized.
        if (Theme.of(context).platform == TargetPlatform.iOS ||
            Theme.of(context).platform == TargetPlatform.macOS)
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: _SocialBrand.appleSurface,
              borderRadius: BorderRadius.circular(Radii.button),
              boxShadow: [
                BoxShadow(
                  // ALLOW-HEX: const-required shadow tint, not a themed surface color
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.button),
                onTap: isLoading ? null : () => _handleAppleSignIn(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.apple,
                        size: 24,
                        color: _SocialBrand.appleLabel,
                      ),
                      const SizedBox(width: Space.md),
                      Text(
                        'Continue with Apple',
                        style: context.typo.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _SocialBrand.appleLabel,
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
        
        final tokens = context.tokens;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(color: tokens.onDanger),
            ),
            backgroundColor: tokens.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.button),
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
        
        final tokens = context.tokens;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(color: tokens.onDanger),
            ),
            backgroundColor: tokens.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.button),
            ),
          ),
        );
      }
    }
  }
}