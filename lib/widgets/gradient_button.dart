import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final List<Color>? gradientColors;
  final double height;
  final double width;
  final bool isLoading;
  final BorderRadiusGeometry? borderRadius;

  const GradientButton({
    super.key,
    required this.child,
    this.onPressed,
    this.gradientColors,
    this.height = 52.0,
    this.width = double.infinity,
    this.isLoading = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColors = gradientColors ?? [AppColors.primary, AppColors.secondary];
    final defaultRadius = borderRadius ?? BorderRadius.circular(12);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? LinearGradient(
                colors: defaultColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: onPressed == null ? Colors.white10 : null,
        borderRadius: defaultRadius,
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: defaultColors[0].withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.all(Radius.circular(
            (defaultRadius as BorderRadius).topLeft.x,
          )),
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
                : child,
          ),
        ),
      ),
    );
  }
}
