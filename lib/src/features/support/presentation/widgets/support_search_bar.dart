import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SupportSearchBar extends StatelessWidget {
  const SupportSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      padding: EdgeInsets.only(left: 16.w, right: 6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.textHint, size: 24.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              style: TextStyle(color: AppColors.textMain, fontSize: 15.sp),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: "Bạn cần hỗ trợ gì hôm nay...",
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 15.sp,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 22.sp,
            ),
          ),
        ],
      ),
    );
  }
}
