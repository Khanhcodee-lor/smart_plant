import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class AppLoadingWidget extends StatelessWidget {
  /// Hiển thị chữ phía dưới loading (VD: "Đang tải dữ liệu...")
  final String? text;

  /// Kích hoạt hiệu ứng nền kính mờ (Glassmorphism) khi đè lên UI khác
  final bool showOverlay;

  /// Màu của indicator, mặc định là AppColors.primary
  final Color? color;

  const AppLoadingWidget({
    super.key,
    this.text,
    this.showOverlay = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Hộp chứa loading với shadow mềm mại, tạo cảm giác 3D nổi bật
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (color ?? AppColors.primary).withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SpinKitDualRing(
            color: color ?? AppColors.primary,
            size: 32.r,
            lineWidth: 3.5,
          ),
        ),
        if (text != null) ...[
          SizedBox(height: 16.h),
          Text(
            text!,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14.sp,
              color: AppColors.textMain,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    // Nếu không phải overlay thì chỉ hiển thị ở giữa màn hình/vùng chứa
    if (!showOverlay) {
      return Center(child: content);
    }

    // Nếu là overlay, tạo nền kính mờ (Glassmorphism effect) rất đẹp
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              color: AppColors.background.withOpacity(0.4),
            ),
          ),
        ),
        Center(child: content),
      ],
    );
  }
}
