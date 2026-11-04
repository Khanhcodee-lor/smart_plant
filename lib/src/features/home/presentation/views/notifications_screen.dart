import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/disease_display_utils.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/plant_detections_provider.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: plantsAsync.when(
          data: (plants) {
            final notifications = _notificationsFromPlants(plants, ref);
            if (notifications.isEmpty) {
              return const _EmptyNotifications();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 14.h),
                  child: Text(
                    'Kết quả nhận diện được đồng bộ từ Firebase',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final healthy = isHealthyDisease(
                        notification.detection.diseaseClass,
                      );
                      final color = healthy
                          ? AppColors.success
                          : AppColors.error;

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18.r),
                          onTap: () => context.pushNamed(
                            'plant_detail',
                            pathParameters: {'id': notification.plant.id},
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(15.r),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44.w,
                                  height: 44.w,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.11),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    healthy
                                        ? Icons.eco_outlined
                                        : Icons.warning_amber_rounded,
                                    color: color,
                                    size: 23.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification.plant.name,
                                        style: TextStyle(
                                          color: AppColors.textMain,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        translateDiseaseLabel(
                                          notification.detection.diseaseClass,
                                        ),
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (notification.detection.confidence > 0) ...[
                                        SizedBox(height: 4.h),
                                        Text(
                                          'Độ tin cậy: ${(notification.detection.confidence * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ],
                                      if (notification.detection.time
                                          .trim()
                                          .isNotEmpty) ...[
                                        SizedBox(height: 5.h),
                                        Text(
                                          notification.detection.time,
                                          style: TextStyle(
                                            color: AppColors.disabledText,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.disabledText,
                                  size: 22.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => _EmptyNotifications(
            message: 'Không tải được thông báo: $error',
            icon: Icons.cloud_off_outlined,
          ),
        ),
      ),
    );
  }
}

List<_PlantNotification> _notificationsFromPlants(
  List<Plant> plants,
  WidgetRef ref,
) {
  final notifications = <_PlantNotification>[];
  for (final plant in plants) {
    final seen = <String>{};
    final remote = ref
        .watch(plantDetectionsProvider(plant.id))
        .asData
        ?.value;
    final detections = <DetectionItem>[
      ...?remote?.history,
      ...?remote?.latestDetections,
      if (remote?.latestDetections.isEmpty ?? true)
        if (remote?.latestDetection != null) remote!.latestDetection!,
      if (remote == null || !remote.hasAnyData) ...[
        if (plant.latestDetection != null) plant.latestDetection!,
        ...plant.history,
      ],
    ];
    for (final detection in detections) {
      final key = [
        detection.time.trim(),
        detection.diseaseClass.trim().toLowerCase(),
        detection.sourceDocumentPath.trim(),
      ].join('|');
      if (seen.add(key)) {
        notifications.add(_PlantNotification(plant, detection));
      }
    }
  }

  notifications.sort((a, b) {
    final aTime = DateTime.tryParse(a.detection.time);
    final bTime = DateTime.tryParse(b.detection.time);
    if (aTime != null && bTime != null) return bTime.compareTo(aTime);
    if (aTime != null) return -1;
    if (bTime != null) return 1;
    return b.detection.time.compareTo(a.detection.time);
  });
  return notifications;
}

class _PlantNotification {
  const _PlantNotification(this.plant, this.detection);

  final Plant plant;
  final DetectionItem detection;
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({
    this.message = 'Chưa có thông báo. Kết quả mới từ Firebase sẽ hiển thị tại đây.',
    this.icon = Icons.notifications_none_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.disabledText, size: 42.sp),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
