import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/premium_text_field.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hideError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _hideError = false;
      });
      ref.read(authStateProvider.notifier).signUpWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        // Pop back to main shell
        Navigator.of(context).pop();
      }
    });

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    final bool isShortScreen = screenHeight < 680;
    final bool isNarrowScreen = screenWidth < 360;
    final bool isTablet = screenWidth >= 600;

    final double spacingTop = isShortScreen ? 16.0 : 28.0;
    final double spacingFooter = isShortScreen ? 20.0 : 28.0;
    
    final EdgeInsets cardPadding = isNarrowScreen
        ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0)
        : const EdgeInsets.all(24.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient blobs
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.darkGradient,
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 420 : 380,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isShortScreen ? 26 : 30,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start transcribing and capturing decisions instantly',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: isShortScreen ? 12 : 13,
                                ),
                          ),
                          SizedBox(height: spacingTop),

                          // Dynamic Inline Error Card
                          if (authState.status == AuthStatus.error &&
                              authState.errorMessage != null &&
                              !_hideError) ...[
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0.0, (1.0 - value) * -10.0),
                                    child: child,
                                  ),
                                );
                              },
                              child: GlassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                borderColor: AppColors.error.withValues(alpha: 0.3),
                                borderWidth: 1.0,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        authState.errorMessage!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          _hideError = true;
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // Registration Form Card
                          GlassCard(
                            opacity: 0.05,
                            padding: cardPadding,
                            borderColor: Colors.white10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Name field
                                PremiumTextField(
                                  controller: _nameController,
                                  keyboardType: TextInputType.name,
                                  hintText: 'Full Name',
                                  prefixIcon: Icons.person_outline_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Email field
                                PremiumTextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  hintText: 'Email address',
                                  prefixIcon: Icons.email_outlined,
                                  validator: (value) {
                                    if (value == null || value.isEmpty || !value.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password field
                                PremiumTextField(
                                  controller: _passwordController,
                                  isPassword: true,
                                  hintText: 'Password (min. 6 chars)',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Sign Up Button
                                GradientButton(
                                  isLoading: authState.status == AuthStatus.loading,
                                  onPressed: authState.status == AuthStatus.loading ? null : _onRegister,
                                  child: const Text('Create Account'),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: spacingFooter),

                          // Redirect to Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              GestureDetector(
                                onTap: authState.status == AuthStatus.loading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
