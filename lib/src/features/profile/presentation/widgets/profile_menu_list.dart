import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileMenuList extends StatelessWidget {
  const ProfileMenuList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGroup([
          _buildMenuItem(Icons.bolt, "Bảng điều khiển năng lượng"),
          _buildMenuItem(Icons.layers, "Quản lý thiết bị"),
          _buildMenuItem(Icons.home_outlined, "Quản lý nhà"),
        ]),
        SizedBox(height: 16.h),
        _buildGroup([_buildMenuItem(Icons.apps, "Thêm công cụ")]),
        SizedBox(height: 16.h),
        _buildGroup([
          _buildMenuItem(Icons.system_update, "Cập nhật phần mềm thiết bị"),
          _buildMenuItem(Icons.chat_bubble_outline, "Phản ánh"),
          _buildMenuItem(Icons.star_outline, "Đánh giá"),
        ]),
      ],
    );
  }

  Widget _buildGroup(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textMain, size: 22.sp),
      title: title.bodyCustom(size: 14.sp),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textHint,
        size: 20.sp,
      ),
      onTap: () {},
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
    );
  }
}
