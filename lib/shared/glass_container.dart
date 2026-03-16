import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? borderColor;
  final List<Color>? gradientColors;

  const GlassContainer({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
    this.borderRadius = 24,
    this.borderColor,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ), // The "Frost" effect
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: height,
              width: width,
              padding: padding,
              decoration: BoxDecoration(
                // Translucent gradient
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      gradientColors ??
                      [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                ),
                // Subtle border for definition
                border: Border.all(
                  color: borderColor ?? Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
