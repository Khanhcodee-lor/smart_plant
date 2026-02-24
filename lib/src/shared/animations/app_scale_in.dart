import 'package:flutter/material.dart';
import 'animation_utils.dart';

class AppScaleIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double startScale;

  const AppScaleIn({
    super.key,
    required this.child,
    this.duration = kDefaultAnimationDuration,
    this.delay = Duration.zero,
    this.startScale = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return AppDelayedAnimation(
      delay: delay,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: startScale, end: 1.0),
        duration: duration,
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: ((scale - startScale) / (1.0 - startScale)).clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }
}