import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/premium_text_field.dart';
import '../../widgets/google_sign_in_button.dart';
import '../dashboard/dashboard_screen.dart';
import 'auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _logoAnimationController;
  late Animation<double> _logoScaleAnimation;

  bool _isGoogleLogin = false;
  bool _hideError = false;

  @override
  void initState() {
    super.initState();
    // Pulse animation for the logo to create a dynamic modern feel
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _logoScaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logoAnimationController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isGoogleLogin = false;
        _hideError = false;
      });
      ref.read(authStateProvider.notifier).loginWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  void _onGoogleLogin() {
    setState(() {
      _isGoogleLogin = true;
      _hideError = false;
    });
    ref.read(authStateProvider.notifier).loginWithGoogle();
  }

  GoogleButtonState _getGoogleButtonState(AuthState state) {
    if (!_isGoogleLogin) return GoogleButtonState.idle;
    
    switch (state.status) {
      case AuthStatus.loading:
        return GoogleButtonState.loading;
      case AuthStatus.authenticated:
        return GoogleButtonState.success;
      case AuthStatus.error:
        return GoogleButtonState.error;
      default:
        return GoogleButtonState.idle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Listen to authentication status changes
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        // Safe navigation to Dashboard Screen after success checkmark animation
        final navigator = Navigator.of(context);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            navigator.pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const DashboardScreen(),
                transitionsBuilder: (_, animation, __, child) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        });
      } else if (next.status == AuthStatus.error) {
        // If Google login fails, reset the flag after a delay so that the user can retry.
        if (_isGoogleLogin) {
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted) {
              setState(() {
                _isGoogleLogin = false;
              });
            }
          });
        }
      }
    });

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    final bool isShortScreen = screenHeight < 680;
    final bool isNarrowScreen = screenWidth < 360;
    final bool isTablet = screenWidth >= 600;

    final double logoSize = isShortScreen ? 44.0 : 56.0;
    final double spacingTop = isShortScreen ? 16.0 : 32.0;
    final double spacingCard = isShortScreen ? 12.0 : 20.0;
    final double spacingFooter = isShortScreen ? 20.0 : 28.0;
    
    final EdgeInsets cardPadding = isNarrowScreen
        ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0)
        : const EdgeInsets.all(24.0);

    return Scaffold(
      body: Stack(
        children: [
          // Background Premium Dark Gradients & Blobs
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.darkGradient,
            ),
          ),
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                          // Pulse Animated Logo and Header
                          ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: CircleAvatar(
                              radius: logoSize / 2 + 10,
                              backgroundColor: AppColors.surface,
                              child: Icon(
                                Icons.insights_rounded,
                                size: logoSize,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'MeetingMind AI',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontSize: isShortScreen ? 24 : 28,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Continuous background recording and AI transcripts',
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

                          // Credentials Form Card
                          GlassCard(
                            opacity: 0.05,
                            padding: cardPadding,
                            borderColor: Colors.white10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Sign In',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontSize: isShortScreen ? 18 : 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                
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
                                  hintText: 'Password',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Sign In Button
                                GradientButton(
                                  isLoading: authState.status == AuthStatus.loading && !_isGoogleLogin,
                                  onPressed: authState.status == AuthStatus.loading ? null : _onLogin,
                                  child: const Text('Login'),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: spacingCard),
                          
                          // Google Login Divider
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white10, thickness: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text('OR', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(child: Divider(color: Colors.white10, thickness: 1)),
                            ],
                          ),
                          
                          SizedBox(height: spacingCard),

                          // Google Sign In Button
                          GoogleSignInButton(
                            onPressed: authState.status == AuthStatus.loading ? null : _onGoogleLogin,
                            state: _getGoogleButtonState(authState),
                          ),

                          SizedBox(height: spacingFooter),

                          // Redirect to Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Don\'t have an account? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              GestureDetector(
                                onTap: authState.status == AuthStatus.loading
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                        );
                                      },
                                child: const Text(
                                  'Sign Up',
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
