import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThirdPartyServices extends StatelessWidget {
  const ThirdPartyServices({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          "Dịch vụ bên thứ ba".h2Custom(size: 14.sp),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildServiceItem("MAIKA", Colors.orange),
              _buildServiceItem("Google Home", Colors.green),
              _buildServiceItem("Amazon Alexa", Colors.blue),
              _buildServiceItem("IFTTT", Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 45.w,
          height: 45.w,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(Icons.hub, color: color, size: 24.sp),
        ),
        SizedBox(height: 8.h),
        name.bodyCustom(size: 10.sp, align: TextAlign.center),
      ],
    );
  }
}
