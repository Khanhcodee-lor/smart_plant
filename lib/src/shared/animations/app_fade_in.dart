import 'package:flutter/material.dart';
import 'animation_utils.dart';

class AppFadeIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const AppFadeIn({
    super.key,
    required this.child,
    this.duration = kDefaultAnimationDuration,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AppDelayedAnimation(
      delay: delay,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: duration,
        curve: kDefaultAnimationCurve,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}