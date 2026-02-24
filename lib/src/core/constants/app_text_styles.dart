import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static final _headingFont = GoogleFonts.beVietnamPro;
  static final _bodyFont = GoogleFonts.inter;

  static TextStyle _beVietnam({
    double? size,
    FontWeight? weight,
    Color? color,
  }) {
    return _headingFont(
      fontSize: size ?? 24,
      fontWeight: weight ?? FontWeight.w400,
      color: color ?? AppColors.textMain,
    );
  }

  static TextStyle h1Bold = _beVietnam(weight: FontWeight.w700);
  static TextStyle h1Light = _beVietnam(weight: FontWeight.w300);

  // ===== DISPLAY (SỐ LIỆU IOT) =====
  static TextStyle display = _headingFont(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
  );

  // ===== HEADINGS =====
  static TextStyle h1 = _headingFont(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textMain,
  );

  static TextStyle h2 = _headingFont(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );

  static TextStyle h3 = _headingFont(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );

  // ===== TITLE =====
  static TextStyle title = _bodyFont(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textMain,
  );

  // ===== BODY =====
  static TextStyle body = _bodyFont(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMain,
  );

  static TextStyle bodySmall = _bodyFont(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle caption = _bodyFont(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ===== LABEL / BUTTON =====
  static TextStyle label = _bodyFont(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
  );

  static TextStyle button = _bodyFont(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static TextStyle link = _bodyFont(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.secondary,
    decoration: TextDecoration.underline,
  );

  // ===== STATUS =====
  static TextStyle error = _bodyFont(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );

  static TextStyle success = _bodyFont(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
  );
}
