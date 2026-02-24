import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeviceSelectorSection extends StatelessWidget {
  const DeviceSelectorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        "Chọn thiết bị".h2Custom(size: 16.sp),
        SizedBox(height: 12.h),
        SizedBox(
          height: 140.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildDeviceCard(
                icon: Icons.kitchen,
                name: "Tủ lạnh",
                isSelected: true,
              ),
              _buildDeviceCard(
                icon: Icons.list_alt,
                name: "Thêm thiết bị",
                isSelected: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard({
    required IconData icon,
    required String name,
    bool isSelected = false,
  }) {
    return Container(
      width: 140.w,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40.sp,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          SizedBox(height: 12.h),
          name.bodyCustom(
            size: 12.sp,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ],
      ),
    );
  }
}
