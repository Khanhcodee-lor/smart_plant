import 'package:app_iot/src/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

extension StringToText on String {
  // ==================== 1. DÙNG NHANH (MẶC ĐỊNH) ====================
  Text get h1 => _buildText(style: AppTextStyles.h1);
  Text get h2 => _buildText(style: AppTextStyles.h2);
  Text get title => _buildText(style: AppTextStyles.title);
  Text get body => _buildText(style: AppTextStyles.body);
  Text get label => _buildText(style: AppTextStyles.label);

  // ==================== 2. DÙNG CUSTOM (CÓ CHỈNH SỬA) ====================

  // H1 Custom
  Text h1Custom({
    Color? color,
    TextAlign? align,
    int? maxLines,
    TextOverflow? overflow,
    double? size,
    List<Shadow>? shadows,
    FontWeight? fontweight,
  }) => _buildText(
    style: AppTextStyles.h1,
    color: color,
    align: align,
    maxLines: maxLines,
    overflow: overflow,
    fontSize: size,
    shadows: shadows,
    fontWeight: fontweight,
  );

  // H2 Custom
  Text h2Custom({
    Color? color,
    TextAlign? align,
    int? maxLines,
    TextOverflow? overflow,
    double? size,
    List<Shadow>? shadows,
    FontWeight? fontweight,
  }) => _buildText(
    style: AppTextStyles.h2,
    color: color,
    align: align,
    maxLines: maxLines,
    overflow: overflow,
    fontSize: size,
    shadows: shadows,
    fontWeight: fontweight,
  );

  // H3 Custom
  Text h3Custom({
    Color? color,
    TextAlign? align,
    int? maxLines,
    TextOverflow? overflow,
    double? size,
    List<Shadow>? shadows,
    FontWeight? fontweight,
  }) => _buildText(
    style: AppTextStyles.h3,
    color: color,
    align: align,
    maxLines: maxLines,
    overflow: overflow,
    fontSize: size,
    shadows: shadows,
    fontWeight: fontweight,
  );

  // Title Custom
  Text titleCustom({
    Color? color,
    TextAlign? align,
    int? maxLines,
    TextOverflow? overflow,
    double? size,
    List<Shadow>? shadows,
    required FontWeight fontweight,
    TextDecoration? decoration,
  }) => _buildText(
    style: AppTextStyles.title,
    color: color,
    align: align,
    maxLines: maxLines,
    overflow: overflow,
    fontSize: size,
    shadows: shadows,
    fontWeight: fontweight,
    decoration: decoration,
  );

  // Body Custom (Thêm fontWeight vì body hay cần in đậm/nhạt)
  Text bodyCustom({
    Color? color,
    TextAlign? align,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? size,
    List<Shadow>? shadows,
    TextDecoration? decoration,
  }) => _buildText(
    style: AppTextStyles.body,
    color: color,
    align: align,
    maxLines: maxLines,
    overflow: overflow,
    fontWeight: fontWeight,
    fontSize: size,
    shadows: shadows,
    decoration: decoration,
  );

  // Label Custom
  Text labelCustom({
    Color? color,
    TextAlign? align,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? size,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    Color? decorationColor,
  }) => _buildText(
    style: AppTextStyles.label,
    color: color,
    align: align,
    maxLines: maxLines,
    overflow: overflow,
    fontWeight: fontWeight,
    fontSize: size,
    shadows: shadows,
    decoration: decoration,
    decorationColor: decorationColor,
  );

  // ==================== 3. HÀM DỰNG CHUNG (CORE) ====================
  Text _buildText({
    required TextStyle style,
    Color? color,
    TextAlign? align,
    int? maxLines,
    TextOverflow? overflow,
    FontWeight? fontWeight,
    double? fontSize, // Mới thêm
    List<Shadow>? shadows, // Mới thêm
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return Text(
      this, // 'this' chính là chuỗi String
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      style: style.copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
        shadows: shadows,
        decoration: decoration,
        decorationColor: decorationColor,
      ),
    );
  }
}
