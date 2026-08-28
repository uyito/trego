import 'package:flutter/material.dart';
import 'package:trego/auth/auth_service.dart';
import 'package:trego/auth/login_screen.dart';
import 'package:trego/auth/social_sign_in_buttons.dart';
import '../shared/theme/context_tokens.dart';
import '../shared/theme/trego_tokens.dart';
import '../widgets/core/trego_button.dart';
import '../widgets/core/trego_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  // Lazily constructed: touches Firebase on first access, which must not
  // happen synchronously during State construction (it would crash build()
  // before a frame is ever produced, including in test hosts where Firebase
  // isn't initialized). See also _buildSocialSignIn below.
  late final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TregoScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: Space.xxxl),
                // Logo and Brand
                Container(
                  padding: const EdgeInsets.all(Space.xl),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(Radii.screenWrapper),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 60,
                    color: tokens.brand,
                  ),
                ),
                const SizedBox(height: Space.xxl),
                Text(
                  'Create Account',
                  style: context.typo.display,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  'Join us on your fitness journey',
                  style: context.typo.body.copyWith(color: tokens.inkMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.xxl),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  style: context.typo.body,
                  decoration: _inputDecoration(
                    context,
                    label: 'Email',
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Space.lg),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  style: context.typo.body,
                  decoration: _inputDecoration(
                    context,
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: tokens.inkMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Space.lg),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  style: context.typo.body,
                  decoration: _inputDecoration(
                    context,
                    label: 'Confirm Password',
                    hint: 'Confirm your password',
                    icon: Icons.lock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: tokens.inkMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Space.xxl),

                // Register Button
                TregoButton(
                  label: 'Create Account',
                  fullWidth: true,
                  size: TregoButtonSize.lg,
                  loading: _isLoading,
                  onPressed: _isLoading ? null : _handleRegister,
                ),
                const SizedBox(height: Space.xl),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: tokens.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                      child: Text(
                        'or continue with',
                        style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
                      ),
                    ),
                    Expanded(child: Divider(color: tokens.border)),
                  ],
                ),
                const SizedBox(height: Space.xl),

                // Social Sign-In Buttons
                _buildSocialSignIn(context),

                const SizedBox(height: Space.xxl),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: context.typo.body.copyWith(color: tokens.inkMuted),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: tokens.brand,
                      ),
                      child: Text(
                        'Sign In',
                        style: context.typo.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens.brand,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final tokens = context.tokens;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: context.typo.body.copyWith(color: tokens.inkMuted),
      hintStyle: context.typo.body.copyWith(color: tokens.inkFaint),
      prefixIcon: Icon(icon, color: tokens.inkMuted),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: tokens.surface,
      border: border(tokens.border),
      enabledBorder: border(tokens.border),
      focusedBorder: border(tokens.brand),
      errorBorder: border(tokens.danger),
      focusedErrorBorder: border(tokens.danger),
      errorStyle: context.typo.bodySmall.copyWith(color: tokens.danger),
    );
  }

  Widget _buildSocialSignIn(BuildContext context) {
    // AuthService() touches FirebaseAuth.instance on first access; guard so
    // the screen still renders in Firebase-less test hosts. In production
    // Firebase is always initialized before this screen mounts, so this
    // catch never triggers there.
    try {
      return SocialSignInButtons(
        authService: _authService,
        onSuccess: () {
          // AppStateProvider flips to isAuthenticated=true after
          // AuthService.signUp completes; TregoApp's Consumer2
          // then swaps in AppShell. Just pop the auth route.
          Navigator.pop(context);
        },
        isLoading: _isLoading,
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _emailController.text.split('@')[0], // Use email prefix as name
      );

      // Auth state change will automatically trigger navigation via AppStateProvider
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Registration failed';

        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'An account with this email already exists';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Password is too weak';
        } else if (e.toString().contains('operation-not-allowed')) {
          errorMessage = 'Email/password accounts are not enabled';
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
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
