import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExploreSection extends StatelessWidget {
  const ExploreSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            "Khám phá".h2Custom(size: 16.sp),
            Row(
              children: [
                "Cách sử dụng".bodyCustom(
                  size: 12.sp,
                  color: AppColors.textSecondary,
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 180.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildExploreCard(
                image:
                    "https://via.placeholder.com/300x200", // Will be replaced by generate_image later if needed
                title: "Kết nối thiết bị thông minh",
                color: Colors.blue.withOpacity(0.1),
              ),
              _buildExploreCard(
                image: "https://via.placeholder.com/300x200",
                title: "Mẹo tiết kiệm điện năng",
                color: Colors.green.withOpacity(0.1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExploreCard({
    required String image,
    required String title,
    required Color color,
  }) {
    return Container(
      width: 250.w,
      margin: EdgeInsets.only(right: 16.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi, color: Colors.blue, size: 20.sp),
          ),
          const Spacer(),
          title.h3Custom(size: 14.sp),
          SizedBox(height: 4.h),
          "Xem thêm...".bodyCustom(size: 10.sp, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
