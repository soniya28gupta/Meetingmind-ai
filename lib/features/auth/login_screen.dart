import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import 'auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      ref.read(authStateProvider.notifier).loginWithEmail(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Listen to authentication status changes or error messages
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        final isCancelled = next.errorMessage!.contains('cancelled') || 
                            next.errorMessage!.contains('Cancelled');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCancelled ? 'Google Sign-In was cancelled.' : next.errorMessage!),
            backgroundColor: isCancelled ? AppColors.warning : AppColors.error,
          ),
        );
      } else if (next.status == AuthStatus.authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isShortScreen = screenHeight < 680;
    final bool isNarrowScreen = screenWidth < 360;

    final double logoSize = isShortScreen ? 48.0 : 64.0;
    final double spacingTop = isShortScreen ? 20.0 : 40.0;
    final double spacingCard = isShortScreen ? 16.0 : 24.0;
    final double spacingFooter = isShortScreen ? 24.0 : 32.0;
    
    final EdgeInsets cardPadding = isNarrowScreen
        ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0)
        : const EdgeInsets.all(24.0);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo and Brand Header
                          Icon(
                            Icons.insights_rounded,
                            size: logoSize,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'MeetingMind AI',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontSize: isShortScreen ? 26 : null,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Continuous background recording and AI transcripts',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: isShortScreen ? 12 : null,
                                ),
                          ),
                          SizedBox(height: spacingTop),

                          // Credentials Form Card
                          GlassCard(
                            opacity: 0.05,
                            padding: cardPadding,
                            child: Column(
                              children: [
                                Text(
                                  'Sign In',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontSize: isShortScreen ? 18 : null,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: 'Email address',
                                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty || !value.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    hintText: 'Password',
                                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Sign In Button
                                GradientButton(
                                  isLoading: authState.status == AuthStatus.loading,
                                  onPressed: _onLogin,
                                  child: const Text('Login'),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: spacingCard),
                          
                          // Google Login Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: AppColors.surfaceLight, thickness: 1)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text('OR', style: TextStyle(color: AppColors.textMuted)),
                              ),
                              Expanded(child: Divider(color: AppColors.surfaceLight, thickness: 1)),
                            ],
                          ),
                          
                          SizedBox(height: spacingCard),

                          // Google Sign In
                          SizedBox(
                            width: double.infinity,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double buttonWidth = constraints.maxWidth;
                                final bool isSmallScreen = buttonWidth < 320;
                                
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Colors.transparent),
                                    ),
                                    elevation: 1,
                                  ),
                                  onPressed: authState.status == AuthStatus.loading
                                      ? null
                                      : () => ref.read(authStateProvider.notifier).loginWithGoogle(),
                                  child: authState.status == AuthStatus.loading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CustomPaint(
                                              size: const Size(20, 20),
                                              painter: GoogleLogoPainter(),
                                            ),
                                            const SizedBox(width: 12),
                                            Flexible(
                                              child: Text(
                                                isSmallScreen ? 'Google' : 'Continue with Google',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: spacingFooter),

                          // Redirect to Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Don\'t have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                },
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
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

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24.0;
    
    // 1. Red (Top)
    final Paint paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final Path pathRed = Path()
      ..moveTo(12.0 * s, 5.04 * s)
      ..cubicTo(13.62 * s, 5.04 * s, 15.06 * s, 5.6 * s, 16.21 * s, 6.7 * s)
      ..lineTo(19.36 * s, 3.55 * s)
      ..cubicTo(17.45 * s, 1.72 * s, 14.97 * s, 1.0 * s, 12.0 * s, 1.0 * s)
      ..cubicTo(7.35 * s, 1.0 * s, 3.37 * s, 3.67 * s, 1.39 * s, 7.56 * s)
      ..lineTo(5.25 * s, 10.56 * s)
      ..cubicTo(6.17 * s, 7.56 * s, 8.85 * s, 5.04 * s, 12.0 * s, 5.04 * s)
      ..close();
    canvas.drawPath(pathRed, paintRed);

    // 2. Green (Bottom)
    final Paint paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final Path pathGreen = Path()
      ..moveTo(12.0 * s, 18.96 * s)
      ..cubicTo(8.85 * s, 18.96 * s, 6.17 * s, 16.44 * s, 5.25 * s, 13.44 * s)
      ..lineTo(1.39 * s, 16.56 * s)
      ..cubicTo(3.37 * s, 20.33 * s, 7.35 * s, 23.0 * s, 12.0 * s, 23.0 * s)
      ..cubicTo(14.97 * s, 23.0 * s, 17.46 * s, 22.02 * s, 19.28 * s, 20.34 * s)
      ..lineTo(15.71 * s, 17.57 * s)
      ..cubicTo(14.73 * s, 18.23 * s, 13.48 * s, 18.96 * s, 12.0 * s, 18.96 * s)
      ..close();
    canvas.drawPath(pathGreen, paintGreen);

    // 3. Yellow (Left)
    final Paint paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final Path pathYellow = Path()
      ..moveTo(5.25 * s, 13.44 * s)
      ..cubicTo(5.01 * s, 12.72 * s, 4.87 * s, 11.95 * s, 4.87 * s, 11.16 * s)
      ..cubicTo(4.87 * s, 10.37 * s, 5.0 * s, 9.6 * s, 5.25 * s, 8.88 * s)
      ..lineTo(1.39 * s, 5.88 * s)
      ..cubicTo(0.5 * s, 7.66 * s, 0 * s, 9.64 * s, 0 * s, 11.72 * s)
      ..cubicTo(0 * s, 13.8 * s, 0.5 * s, 15.78 * s, 1.39 * s, 17.56 * s)
      ..close();
    canvas.drawPath(pathYellow, paintYellow);

    // 4. Blue (Right / Bar)
    final Paint paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final Path pathBlue = Path()
      ..moveTo(21.83 * s, 11.72 * s)
      ..cubicTo(21.83 * s, 10.93 * s, 21.76 * s, 10.16 * s, 21.64 * s, 9.44 * s)
      ..lineTo(12.0 * s, 9.44 * s)
      ..lineTo(12.0 * s, 13.95 * s)
      ..lineTo(17.52 * s, 13.95 * s)
      ..cubicTo(17.28 * s, 15.23 * s, 16.56 * s, 16.32 * s, 15.48 * s, 17.05 * s)
      ..lineTo(19.05 * s, 19.82 * s)
      ..cubicTo(21.13 * s, 17.9 * s, 22.33 * s, 15.08 * s, 22.33 * s, 11.72 * s)
      ..close();
    canvas.drawPath(pathBlue, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
