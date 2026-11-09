import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

enum _GardenMenuAction { addGarden }

class HeaderRegime extends ConsumerWidget {
  const HeaderRegime({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsyncValue = ref.watch(plantControllerProvider);
    final plants = plantAsyncValue.asData?.value;
    final plantName = plants == null || plants.isEmpty
        ? null
        : plants.first.name;

    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<_GardenMenuAction>(
            tooltip: 'Chọn khu vườn',
            position: PopupMenuPosition.under,
            offset: Offset(0, 8.h),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: 220.w,
              maxWidth: 260.w,
            ),
            color: Colors.white,
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
            onSelected: (action) {
              switch (action) {
                case _GardenMenuAction.addGarden:
                  debugPrint('Thêm vườn');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<_GardenMenuAction>(
                enabled: false,
                height: 62.h,
                child: Row(
                  children: [
                    Container(
                      width: 34.w,
                      height: 34.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F7F3),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: AppColors.accent,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plantName ?? 'Đang tải vườn…',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMain,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Vườn đang xem',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuDivider(height: 1.h),
              PopupMenuItem<_GardenMenuAction>(
                value: _GardenMenuAction.addGarden,
                height: 52.h,
                child: Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.accent,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Thêm vườn',
                      style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                Container(
                  width: 46.w,
                  height: 46.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.82),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.yard_rounded,
                    color: AppColors.accent,
                    size: 23.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KHU VƯỜN',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plantName ?? 'Đang tải vườn…',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textMain,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: IconButton(
            tooltip: 'Thông báo',
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.notifications_outlined,
              size: 22.sp,
              color: AppColors.accent,
            ),
            onPressed: () => context.pushNamed('notifications'),
          ),
        ),
      ],
    );
  }
}
