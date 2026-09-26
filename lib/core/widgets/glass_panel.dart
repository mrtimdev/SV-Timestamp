import 'dart:ui';
import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 22,
    this.blur = 20,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.gradient,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null
              ? (backgroundColor ?? Colors.black.withValues(alpha: 0.38))
              : null,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: 0.18),
            width: borderWidth,
          ),
          boxShadow:
              boxShadow ??
              [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
        ),
        child: child,
      ),
    ),
  );
}
