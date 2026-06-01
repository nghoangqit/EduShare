import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/constants.dart';

class GlassSurface extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final double opacity;
  final double blur;
  final Color color;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const GlassSurface({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.opacity = 0.78,
    this.blur = 18,
    this.color = Colors.white,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.46),
            ),
            boxShadow:
                boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class SubtleGlassSurface extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;

  const SubtleGlassSurface({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      width: width,
      height: height,
      padding: padding,
      borderRadius: borderRadius,
      opacity: 0.88,
      blur: 12,
      borderColor: AppColors.border.withValues(alpha: 0.72),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      child: child,
    );
  }
}
