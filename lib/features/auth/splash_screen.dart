import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _timerFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glowAnimation = Tween<double>(
      begin: 6.0,
      end: 20.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Enforce minimum splash display duration of 2.2s for rich aesthetics
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _timerFinished = true;
        });
        _evaluateNavigation();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _evaluateNavigation() {
    if (!mounted || !_timerFinished) return;

    final authState = ref.read(authStateProvider);
    // Only navigate if we have resolved the auth status to authenticated or unauthenticated
    if (authState.status == AuthStatus.authenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else if (authState.status == AuthStatus.unauthenticated ||
        authState.status == AuthStatus.error) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to authentication changes so we navigate as soon as it resolves
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (_timerFinished) {
        _evaluateNavigation();
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: FuturisticBackground(
        child: Stack(
          children: [
            // Center Animated Brand Logo
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: _glowAnimation.value,
                              spreadRadius: _glowAnimation.value / 4,
                            ),
                          ],
                        ),
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.surface,
                      child: Icon(
                        Icons.insights_rounded,
                        size: 56,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Animated Title Text
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0.0, (1.0 - value) * 16.0),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      'MeetingMind AI',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.6,
                            fontSize: screenWidth < 360 ? 28 : 34,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(opacity: value * 0.7, child: child);
                    },
                    child: const Text(
                      'AI meeting records & action items',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Adaptive loading text
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
