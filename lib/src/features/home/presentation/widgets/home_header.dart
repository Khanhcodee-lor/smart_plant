import 'dart:async';

import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/disease_display_utils.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:app_iot/src/core/services/firebase/firebase_messaging_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    ref.listen(plantControllerProvider, (previous, next) {
      next.whenData((plants) {
        unawaited(
          ref.read(firebaseMessagingServiceProvider).syncPlantTopics(
            plants.map((plant) => plant.id),
          ),
        );
      });
    });
    final plants = ref.watch(plantControllerProvider).asData?.value ??
        const <Plant>[];
    final alertCount = plants
        .where(
          (plant) =>
              plant.latestDetection != null &&
              !isHealthyDisease(plant.latestDetection!.diseaseClass),
        )
        .length;

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
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'Thông báo',
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.accent,
                  size: 28,
                ),
                onPressed: () => context.pushNamed('notifications'),
              ),
            ),
            if (alertCount > 0)
              Positioned(
                top: 1,
                right: 1,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    alertCount > 9 ? '9+' : '$alertCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
