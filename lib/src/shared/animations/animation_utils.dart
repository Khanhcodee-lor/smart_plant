import 'package:flutter/material.dart';

/// Thời gian mặc định cho animation
const Duration kDefaultAnimationDuration = Duration(milliseconds: 600);
const Curve kDefaultAnimationCurve = Curves.easeOutQuart;

/// Widget hỗ trợ delay animation
class AppDelayedAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AppDelayedAnimation({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<AppDelayedAnimation> createState() => _AppDelayedAnimationState();
}

class _AppDelayedAnimationState extends State<AppDelayedAnimation> {
  bool _start = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _start = true;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _start = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _start ? widget.child : const SizedBox.shrink();
  }
}