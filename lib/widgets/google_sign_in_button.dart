import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

enum GoogleButtonState { idle, loading, success, error }

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final GoogleButtonState state;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.state = GoogleButtonState.idle,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _PremiumGoogleLogoPainter extends CustomPainter {
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

class _GoogleSignInButtonState extends State<GoogleSignInButton> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void didUpdateWidget(covariant GoogleSignInButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == GoogleButtonState.error && oldWidget.state != GoogleButtonState.error) {
      _shakeController.forward(from: 0.0).then((_) => _shakeController.reverse());
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  double _getScale() {
    if (widget.state != GoogleButtonState.idle) return 1.0;
    if (_isPressed) return 0.96;
    if (_isHovered) return 1.02;
    return 1.0;
  }

  Widget _buildContent() {
    switch (widget.state) {
      case GoogleButtonState.loading:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Signing you in...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        );
      case GoogleButtonState.success:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            SizedBox(width: 12),
            Text(
              'Signed in successfully!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        );
      case GoogleButtonState.error:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 12),
            Text(
              'Sign in failed',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        );
      case GoogleButtonState.idle:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(20, 20),
              painter: _PremiumGoogleLogoPainter(),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: Colors.black87,
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = widget.state == GoogleButtonState.idle && widget.onPressed != null;

    Color buttonColor;
    BorderSide borderSide;

    switch (widget.state) {
      case GoogleButtonState.loading:
      case GoogleButtonState.success:
      case GoogleButtonState.error:
        buttonColor = AppColors.surface;
        borderSide = BorderSide(
          color: widget.state == GoogleButtonState.success
              ? AppColors.success.withValues(alpha: 0.4)
              : widget.state == GoogleButtonState.error
                  ? AppColors.error.withValues(alpha: 0.4)
                  : AppColors.surfaceLight,
          width: 1.0,
        );
        break;
      case GoogleButtonState.idle:
        buttonColor = Colors.white;
        borderSide = BorderSide.none;
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = isInteractive),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = isInteractive),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: isInteractive ? widget.onPressed : null,
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            // Apply shake translation
            double shakeTranslation = 0.0;
            if (_shakeController.isAnimating) {
              // Sine wave displacement
              shakeTranslation = widget.state == GoogleButtonState.error
                  ? _shakeAnimation.value * (1.0 - _shakeController.value) * (Theme.of(context).platform == TargetPlatform.android ? -1.0 : 1.0) * (3.0 * (1.0 - _shakeController.value))
                  : 0.0;
            }

            return Transform.translate(
              offset: Offset(shakeTranslation, 0.0),
              child: AnimatedScale(
                scale: _getScale(),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 52,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(12),
                    border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
                    boxShadow: [
                      BoxShadow(
                        color: widget.state == GoogleButtonState.idle
                            ? Colors.black.withValues(alpha: _isHovered ? 0.25 : 0.15)
                            : Colors.transparent,
                        blurRadius: _isHovered ? 12 : 8,
                        spreadRadius: _isHovered ? 1 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _buildContent(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
