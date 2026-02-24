import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    final user = authState.value;

    final String currentDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'vi_VN',
    ).format(DateTime.now());
    return Row(
      children: [
        //avata
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accent.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 22.r, // Kích thước avatar
            backgroundColor: Colors.grey[200], // Màu nền khi chưa load ảnh
            // Logic: Nếu có link ảnh Google thì load, không thì để null
            backgroundImage: user?.photoUrl != null
                ? NetworkImage(user!.photoUrl!)
                : null,
            // Logic: Nếu không có ảnh thì hiện icon hình người
            child: user?.photoUrl == null
                ? Icon(Icons.person, color: Colors.grey[400], size: 18.r)
                : null,
          ),
        ),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                "Chào, ".bodyCustom(
                  color: AppColors.textSecondary,
                  size: 12.sp,
                ),
                (user?.name ?? "Người dùng").bodyCustom(),
              ],
            ),
            SizedBox(height: 2.h),
            currentDate.bodyCustom(color: AppColors.accent, size: 10.sp),
          ],
        ),
        Spacer(),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9), // Màu xám siêu nhạt cho nút
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications,
              color: AppColors.accent,
              size: 28,
            ),
            onPressed: () {
              // TODO: Mở menu cài đặt hoặc Đăng xuất
            },
          ),
        ),
      ],
    );
  }
}
