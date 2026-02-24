import 'package:flutter/material.dart';
import 'animation_utils.dart';

class AppSlideIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;

  const AppSlideIn({
    super.key,
    required this.child,
    this.duration = kDefaultAnimationDuration,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 50),
  });

  @override
  Widget build(BuildContext context) {
    return AppDelayedAnimation(
      delay: delay,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(begin: offset, end: Offset.zero),
        duration: duration,
        curve: kDefaultAnimationCurve,
        builder: (context, value, child) {
          return Transform.translate(
            offset: value,
            child: Opacity(
              opacity: (1 - (value.dy / offset.dy).abs().clamp(0.0, 1.0)),
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }
}