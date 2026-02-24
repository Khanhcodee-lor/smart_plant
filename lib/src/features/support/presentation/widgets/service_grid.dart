import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        "Phục vụ tự động".h2Custom(size: 16.sp),
        SizedBox(height: 16.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 20.h,
          crossAxisSpacing: 10.w,
          children: [
            _buildServiceItem(
              Icons.grid_view,
              "Đăng ký Sản Phẩm",
              Colors.redAccent,
            ),
            _buildServiceItem(
              Icons.help_outline,
              "Tự trợ giúp",
              Colors.blueAccent,
            ),
            _buildServiceItem(
              Icons.analytics_outlined,
              "Chẩn đoán thông minh",
              Colors.orangeAccent,
            ),
            _buildServiceItem(
              Icons.build_outlined,
              "Yêu cầu dịch vụ",
              Colors.grey,
            ),
            _buildServiceItem(
              Icons.headset_mic_outlined,
              "Liên hệ chúng tôi",
              Colors.blue,
            ),
            _buildServiceItem(
              Icons.verified_user_outlined,
              "Chính sách bảo hành",
              Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24.sp),
        ),
        SizedBox(height: 8.h),
        Expanded(
          child: label.bodyCustom(
            size: 10.sp,
            align: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
