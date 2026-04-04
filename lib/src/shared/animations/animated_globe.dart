import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedGlobe extends StatefulWidget {
  final String val;
  final String unit;
  final String subtitle;
  final Color baseColor;
  final Color shadowColor;
  final Color textColor;

  const AnimatedGlobe({
    super.key,
    required this.val,
    required this.unit,
    required this.subtitle,
    required this.baseColor,
    required this.shadowColor,
    required this.textColor,
  });

  @override
  State<AnimatedGlobe> createState() => _AnimatedGlobeState();
}

class _AnimatedGlobeState extends State<AnimatedGlobe>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Faster pulse
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shadowValue = _controller.value;
        return Center(
          child: Container(
            width: 250.w,
            height: 250.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.baseColor.withOpacity(0.5),
                  widget.shadowColor.withOpacity(0.7),
                ],
                stops: const [0.3, 1.0],
              ),
              boxShadow: [
                // Core glow
                BoxShadow(
                  color: widget.shadowColor.withOpacity(
                    0.8 - (shadowValue * 0.4),
                  ),
                  blurRadius: 40 + (shadowValue * 50),
                  spreadRadius: 15 + (shadowValue * 35),
                ),
                // Outer ripple
                BoxShadow(
                  color: widget.shadowColor.withOpacity(
                    0.4 - (shadowValue * 0.3),
                  ),
                  blurRadius: 70 + (shadowValue * 80),
                  spreadRadius: 30 + (shadowValue * 60),
                ),
                // Extreme outer aura for stronger effect
                BoxShadow(
                  color: widget.shadowColor.withOpacity(
                    0.15 - (shadowValue * 0.1),
                  ),
                  blurRadius: 100 + (shadowValue * 100),
                  spreadRadius: 50 + (shadowValue * 90),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.val,
                style: TextStyle(
                  fontSize: 64.sp,
                  color: widget.textColor,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -2,
                ),
              ),
              Text(
                widget.unit,
                style: TextStyle(
                  fontSize: 40.sp,
                  color: widget.textColor,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF8B93A6),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
