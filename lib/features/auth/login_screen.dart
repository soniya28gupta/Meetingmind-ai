import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isGoogleLogin = false;
  bool _hideError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isGoogleLogin = false;
        _hideError = false;
      });
      ref
          .read(authStateProvider.notifier)
          .loginWithEmail(
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

  void _onMockSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider Sign-In is coming soon!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF8B5CF6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _onForgotPassword() {
    final email = _emailController.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          email.isNotEmpty
              ? 'Password recovery link sent to $email!'
              : 'Please enter your email first to recover password.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF8B5CF6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Listen to authentication status changes
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        final navigator = Navigator.of(context);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            navigator.pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const DashboardScreen(),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        });
      } else if (next.status == AuthStatus.error) {
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
    final bool isTablet = screenWidth >= 600;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient and Decorative Shapes
          const CuteNeumorphicBackground(),

          // Main Scrollable Panel
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 420 : 380),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          // Heart above Welcome Back
                          const Center(
                            child: Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFFF8A9E),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Welcome Back Title
                          const Text(
                            'Welcome Back 👋',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF7C3AED),
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          const Text(
                            'Login to continue your journey',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: Color(0xFF777777),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Avatar + Card Stack
                          Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              // Main Card Container
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 80),
                                padding: const EdgeInsets.only(
                                  top: 90,
                                  left: 24,
                                  right: 24,
                                  bottom: 28,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                    BoxShadow(
                                      color: const Color(
                                        0xFFA855F7,
                                      ).withOpacity(0.08),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Inline Error Display
                                    if (authState.status == AuthStatus.error &&
                                        authState.errorMessage != null &&
                                        !_hideError) ...[
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          begin: 0.0,
                                          end: 1.0,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0.0,
                                                (1.0 - value) * -10.0,
                                              ),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 20,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.error_outline_rounded,
                                                color: Color(0xFFDC2626),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  authState.errorMessage!,
                                                  style: const TextStyle(
                                                    color: Color(0xFF991B1B),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 16,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _hideError = true;
                                                  });
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                color: const Color(0xFF991B1B),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],

                                    // Email input
                                    CuteNeumorphicTextField(
                                      controller: _emailController,
                                      hintText: 'Email or Username',
                                      prefixIcon: Icons.person_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty ||
                                            !value.contains('@')) {
                                          return 'Enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Password input
                                    CuteNeumorphicTextField(
                                      controller: _passwordController,
                                      hintText: 'Password',
                                      prefixIcon: Icons.lock_rounded,
                                      isPassword: true,
                                      validator: (value) {
                                        if (value == null || value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),

                                    // Forgot Password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: AnimatedUnderlineText(
                                        text: 'Forgot Password?',
                                        onTap: _onForgotPassword,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Login button
                                    CuteNeumorphicButton(
                                      isLoading:
                                          authState.status ==
                                              AuthStatus.loading &&
                                          !_isGoogleLogin,
                                      onPressed:
                                          authState.status == AuthStatus.loading
                                          ? null
                                          : _onLogin,
                                      child: const Text('Login'),
                                    ),
                                    const SizedBox(height: 24),

                                    // Social divider
                                    const Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Color(0xFFE5E7EB),
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: Text(
                                            'or continue with',
                                            style: TextStyle(
                                              color: Color(0xFF777777),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Color(0xFFE5E7EB),
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Social Login Buttons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Google
                                        SocialLoginButton(
                                          logo: CustomPaint(
                                            size: const Size(22, 22),
                                            painter: _GoogleLogoPainter(),
                                          ),
                                          onTap:
                                              authState.status ==
                                                  AuthStatus.loading
                                              ? () {}
                                              : _onGoogleLogin,
                                        ),
                                        const SizedBox(width: 20),
                                        // Apple
                                        SocialLoginButton(
                                          logo: const Icon(
                                            Icons.apple,
                                            color: Colors.black,
                                            size: 26,
                                          ),
                                          onTap: () =>
                                              _onMockSocialLogin('Apple'),
                                        ),
                                        const SizedBox(width: 20),
                                        // Facebook
                                        SocialLoginButton(
                                          logo: const Icon(
                                            Icons.facebook,
                                            color: Color(0xFF1877F2),
                                            size: 28,
                                          ),
                                          onTap: () =>
                                              _onMockSocialLogin('Facebook'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // Redirect to Sign Up
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "Don't have an account? ",
                                          style: TextStyle(
                                            color: Color(0xFF777777),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        AnimatedPressable(
                                          onTap:
                                              authState.status ==
                                                  AuthStatus.loading
                                              ? null
                                              : () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          const RegisterScreen(),
                                                    ),
                                                  );
                                                },
                                          child: const Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              color: Color(0xFF8B5CF6),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Avatar Sitting on top of the Card
                              const Positioned(
                                top: -10,
                                child: AnimatedAvatar(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
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

// ==========================================
// BACKGROUND & DECORATIVE ELEMENTS WIDGETS
// ==========================================

class CuteNeumorphicBackground extends StatelessWidget {
  const CuteNeumorphicBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base pastel soft gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE7D8FF), Color(0xFFCFAFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Large soft blurred circles representing Neumorphic aura
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD6E7).withOpacity(0.4),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -100,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD6F0FF).withOpacity(0.45),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),

        // Floating Animated Clouds
        const AnimatedCloud(
          initialTop: 70,
          initialLeft: 30,
          size: 110,
          duration: Duration(seconds: 7),
        ),
        const AnimatedCloud(
          initialTop: 240,
          initialLeft: 270,
          size: 95,
          duration: Duration(seconds: 9),
        ),

        // Plant decoration at bottom left
        const Positioned(
          bottom: -15,
          left: -15,
          child: Opacity(opacity: 0.95, child: PottedPlantWidget()),
        ),

        // Flower decoration at bottom right
        const Positioned(
          bottom: -15,
          right: -15,
          child: Opacity(opacity: 0.95, child: PottedFlowerWidget()),
        ),
      ],
    );
  }
}

// Floating cloud widget
class AnimatedCloud extends StatefulWidget {
  final double initialTop;
  final double initialLeft;
  final double size;
  final Duration duration;

  const AnimatedCloud({
    super.key,
    required this.initialTop,
    required this.initialLeft,
    required this.size,
    required this.duration,
  });

  @override
  State<AnimatedCloud> createState() => _AnimatedCloudState();
}

class _AnimatedCloudState extends State<AnimatedCloud>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);
    _animation = Tween<double>(
      begin: -15.0,
      end: 15.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: widget.initialTop,
          left: widget.initialLeft + _animation.value,
          child: child!,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size * 0.6),
        painter: ClayCloudPainter(),
      ),
    );
  }
}

// Clay Cloud Painter
class ClayCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.7)
      ..arcToPoint(
        Offset(size.width * 0.35, size.height * 0.4),
        radius: Radius.circular(size.width * 0.2),
      )
      ..arcToPoint(
        Offset(size.width * 0.65, size.height * 0.35),
        radius: Radius.circular(size.width * 0.25),
      )
      ..arcToPoint(
        Offset(size.width * 0.85, size.height * 0.6),
        radius: Radius.circular(size.width * 0.2),
      )
      ..arcToPoint(
        Offset(size.width * 0.9, size.height * 0.8),
        radius: Radius.circular(size.width * 0.1),
      )
      ..lineTo(size.width * 0.1, size.height * 0.8)
      ..close();

    // Cloud drop shadow for 3D clay look
    canvas.drawPath(
      path.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x12000000)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Clay Potted Plant
class PottedPlantWidget extends StatelessWidget {
  const PottedPlantWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Pot
        Container(
          width: 50,
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFE2C29D),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        // Leaves CustomPaint on top
        Positioned(
          bottom: 40,
          child: CustomPaint(
            size: const Size(55, 70),
            painter: ClayPlantPainter(),
          ),
        ),
      ],
    );
  }
}

// Clay Plant Painter
class ClayPlantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw stem
    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.5,
        size.width * 0.5,
        size.height * 0.1,
      );
    canvas.drawPath(path, stemPaint);

    final leafPaint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.fill;

    final leafPositions = [
      Offset(size.width * 0.45, size.height * 0.35),
      Offset(size.width * 0.55, size.height * 0.5),
      Offset(size.width * 0.42, size.height * 0.65),
      Offset(size.width * 0.5, size.height * 0.1),
    ];

    final leafSizes = [
      const Size(18, 9),
      const Size(20, 10),
      const Size(22, 11),
      const Size(16, 8),
    ];

    final leafAngles = [-0.6, 0.6, -0.5, 0.0];

    for (int i = 0; i < leafPositions.length; i++) {
      canvas.save();
      canvas.translate(leafPositions[i].dx, leafPositions[i].dy);
      canvas.rotate(leafAngles[i]);

      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(
          -leafSizes[i].width / 2,
          -leafSizes[i].height / 2,
          -leafSizes[i].width,
          0,
        )
        ..quadraticBezierTo(
          -leafSizes[i].width / 2,
          leafSizes[i].height / 2,
          0,
          0,
        )
        ..close();

      canvas.drawPath(
        leafPath.shift(const Offset(0, 1)),
        Paint()
          ..color = const Color(0x10000000)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );

      canvas.drawPath(leafPath, leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Clay Potted Flower
class PottedFlowerWidget extends StatelessWidget {
  const PottedFlowerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Pot
        Container(
          width: 50,
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFFFC1CC),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        // Flower CustomPaint on top
        Positioned(
          bottom: 40,
          child: CustomPaint(
            size: const Size(60, 70),
            painter: ClayFlowerPainter(),
          ),
        ),
      ],
    );
  }
}

// Clay Flower Painter
class ClayFlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.5, size.height),
      Offset(size.width * 0.5, size.height * 0.4),
      stemPaint,
    );

    final center = Offset(size.width * 0.5, size.height * 0.35);
    final double petalRadius = size.width * 0.13;

    final petalPaint = Paint()
      ..color = const Color(0xFFFF8A9E)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * pi / 5) - pi / 2;
      final offset = Offset(
        center.dx + (size.width * 0.16) * cos(angle),
        center.dy + (size.width * 0.16) * sin(angle),
      );

      canvas.drawCircle(
        offset + const Offset(0, 1),
        petalRadius,
        Paint()
          ..color = const Color(0x10000000)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );

      canvas.drawCircle(offset, petalRadius, petalPaint);
    }

    final centerPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center + const Offset(0, 1),
      size.width * 0.1,
      Paint()
        ..color = const Color(0x12000000)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );

    canvas.drawCircle(center, size.width * 0.1, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated Floating Avatar
class AnimatedAvatar extends StatefulWidget {
  const AnimatedAvatar({super.key});

  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: Image.asset(
        'assets/images/cute_3d_avatar.png',
        height: 160,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ==========================================
// CUTE INPUTS & BUTTON WIDGETS
// ==========================================

class CuteNeumorphicTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const CuteNeumorphicTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<CuteNeumorphicTextField> createState() =>
      _CuteNeumorphicTextFieldState();
}

class _CuteNeumorphicTextFieldState extends State<CuteNeumorphicTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.isPassword ? _obscureText : false,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        style: const TextStyle(
          color: Color(0xFF2C2C2C),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 15),
          filled: true,
          fillColor: const Color(0xFFF8F6FD),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 12.0),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFEFE4FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.prefixIcon,
                color: const Color(0xFFA855F7),
                size: 20,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 54,
            minHeight: 44,
          ),
          suffixIcon: widget.isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: const Color(0xFF9E9E9E),
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// Premium Neumorphic Gradient Button
class CuteNeumorphicButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;

  const CuteNeumorphicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: isLoading ? null : onPressed,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFA855F7), Color(0xFF8B5CF6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  child: child,
                ),
        ),
      ),
    );
  }
}

// Social circular button
class SocialLoginButton extends StatelessWidget {
  final Widget logo;
  final VoidCallback onTap;

  const SocialLoginButton({super.key, required this.logo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFFA855F7).withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: logo),
      ),
    );
  }
}

// Animated underline text for Forgot Password
class AnimatedUnderlineText extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const AnimatedUnderlineText({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  State<AnimatedUnderlineText> createState() => _AnimatedUnderlineTextState();
}

class _AnimatedUnderlineTextState extends State<AnimatedUnderlineText> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2,
              width: _isPressed ? 115 : 0, // Approx text length width
              color: const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Scale & Press feedback helper
class AnimatedPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AnimatedPressable({super.key, required this.child, this.onTap});

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedScale(
            scale: _isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// Google Painter for vector Google Logo G icon
class _GoogleLogoPainter extends CustomPainter {
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

    // 4. Blue (Right)
    final Paint paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final Path pathBlue = Path()
      ..moveTo(21.83 * s, 11.72 * s)
      ..cubicTo(21.83 * s, 10.93 * s, 21.76 * s, 10.16 * s, 21.64 * s, 9.44 * s)
      ..lineTo(12.0 * s, 9.44 * s)
      ..lineTo(12.0 * s, 13.95 * s)
      ..lineTo(17.52 * s, 13.95 * s)
      ..cubicTo(
        17.28 * s,
        15.23 * s,
        16.56 * s,
        16.32 * s,
        15.48 * s,
        17.05 * s,
      )
      ..lineTo(19.05 * s, 19.82 * s)
      ..cubicTo(21.13 * s, 17.9 * s, 22.33 * s, 15.08 * s, 22.33 * s, 11.72 * s)
      ..close();
    canvas.drawPath(pathBlue, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
