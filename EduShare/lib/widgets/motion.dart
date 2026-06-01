import 'package:flutter/material.dart';

import '../utils/constants.dart';

class Reveal extends StatelessWidget {
  final Widget child;
  final int delayMs;
  final Offset beginOffset;

  const Reveal({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.beginOffset = const Offset(0, 0.04),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delayMs),
      curve: AppTheme.motionCurve,
      builder: (context, value, child) {
        final eased = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(
              beginOffset.dx * (1 - eased) * 100,
              beginOffset.dy * (1 - eased) * 100,
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: AppTheme.fastMotion,
        curve: AppTheme.motionCurve,
        child: widget.child,
      ),
    );
  }
}
