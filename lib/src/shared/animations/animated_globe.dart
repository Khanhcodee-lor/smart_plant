import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnimatedGlobe extends StatefulWidget {
  final String val;
  final String unit;
  final String subtitle;
  final Color baseColor;
  final Color shadowColor;
  final Color textColor;
  final Color? accentColor;
  final IconData? icon;

  const AnimatedGlobe({
    super.key,
    required this.val,
    required this.unit,
    required this.subtitle,
    required this.baseColor,
    required this.shadowColor,
    required this.textColor,
    this.accentColor,
    this.icon,
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
      duration: const Duration(milliseconds: 1800),
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
          child: SizedBox(
            width: 292.w,
            height: 292.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: (232 + shadowValue * 18).w,
                  height: (232 + shadowValue * 18).w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.shadowColor.withOpacity(
                      0.18 - shadowValue * 0.08,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.shadowColor.withOpacity(
                          0.28 - shadowValue * 0.12,
                        ),
                        blurRadius: 42 + shadowValue * 30,
                        spreadRadius: 8 + shadowValue * 16,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 238.w,
                  height: 238.w,
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.96),
                        widget.baseColor.withOpacity(0.88),
                        widget.shadowColor.withOpacity(0.54),
                      ],
                      stops: const [0.0, 0.62, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.86),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.shadowColor.withOpacity(0.28),
                        blurRadius: 38,
                        offset: const Offset(0, 18),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.88),
                        blurRadius: 12,
                        offset: const Offset(-8, -10),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: (widget.accentColor ?? widget.textColor).withOpacity(
                  0.12,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.75),
                  width: 1,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 22.sp,
                color: widget.accentColor ?? widget.textColor,
              ),
            ),
            SizedBox(height: 12.h),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.val,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 58.sp,
                      color: widget.textColor,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              Text(
                widget.unit,
                style: TextStyle(
                  fontSize: 28.sp,
                  color: widget.textColor,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF8B93A6),
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
