import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    return Column(
      children: [
        Container(
          width: 90.w,
          height: 90.w,
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _buildAvatar(user?.photoUrl),
        ),
        SizedBox(height: 12.h),
        (user?.name ?? "Người dùng").h2Custom(size: 20.sp),
      ],
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Icon(
        Icons.person_rounded,
        color: AppColors.textSecondary.withOpacity(0.5),
        size: 40.sp,
      );
    }

    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.person_rounded,
          color: AppColors.textSecondary.withOpacity(0.5),
          size: 40.sp,
        );
      },
    );
  }
}
