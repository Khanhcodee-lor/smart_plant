import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ScheduleRegimeList extends StatelessWidget {
  const ScheduleRegimeList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            "Danh sách lịch tưới".h1Custom(size: 14.sp),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.add_circle,
                size: 24,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _buildScheduleItem(
          time: "06:00 AM",
          duration: "5 phút",
          days: "Thứ 2, 4, 6",
          isActive: true,
        ),
        SizedBox(height: 12.h),
        _buildScheduleItem(
          time: "17:30 PM",
          duration: "10 phút",
          days: "Mỗi ngày",
          isActive: false,
        ),
      ],
    );
  }

  Widget _buildScheduleItem({
    required String time,
    required String duration,
    required String days,
    required bool isActive,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.water_drop,
              color: AppColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                time.h3Custom(size: 16.sp),
                SizedBox(height: 4.h),
                "$days • $duration".bodyCustom(
                  color: AppColors.textSecondary,
                  size: 12.sp,
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (v) {},
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
