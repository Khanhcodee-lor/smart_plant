import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/chatbot/presentation/views/ai_chatbot_sheet.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/capture_command_controller.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/disease_image_upload_controller.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/plant_detections_provider.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/capture_history_list_widget.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/current_disease_card_widget.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/disease_history_list_widget.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/latest_snapshot_card_widget.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:app_iot/src/shared/widgets/app_refresh_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class DiseaseDetectionScreen extends BaseView {
  final String plantId;

  const DiseaseDetectionScreen({super.key, required this.plantId});

  @override
  bool extendBodyBehindAppBar() => true;

  @override
  Widget? buildFloatingActionButton(BuildContext context, WidgetRef ref) =>
      null;

  @override
  AppBar? buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textMain),
      titleTextStyle: const TextStyle(
        color: AppColors.textMain,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      centerTitle: true,
      title: ref
          .watch(plantControllerProvider)
          .when(
            data: (plants) {
              final plant = _resolvePlantForScreen(plants, plantId);
              if (plant == null) {
                return const Text('Không tìm thấy dữ liệu cây');
              }
              return Text(plant.name);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Lỗi tải dữ liệu: $error')),
          ),
    );
  }

  @override
  Decoration? bodyDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        transform: const GradientRotation(0.3),
        tileMode: TileMode.clamp,
        stops: const [0.0, 0.7],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.accentSecond.withOpacity(0.09),
          AppColors.backgroundGreen.withOpacity(0.8),
        ],
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    final plantAsyncValue = ref.watch(plantControllerProvider);
    final detectionsAsyncValue = ref.watch(plantDetectionsProvider(plantId));

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: AppRefreshScrollView(
              onRefresh: () async {
                ref.invalidate(plantControllerProvider);
                ref.invalidate(plantDetectionsProvider(plantId));

                await Future.wait([
                  ref.read(plantControllerProvider.future),
                  ref.read(plantDetectionsProvider(plantId).future),
                ]);
              },
              child: plantAsyncValue.when(
                data: (plants) {
                  final plant = _resolvePlantForScreen(plants, plantId);
                  if (plant == null) {
                    return Center(
                      child: Text('Không tìm thấy dữ liệu cây ($plantId)'),
                    );
                  }

                  final firestoreDetections =
                      detectionsAsyncValue.asData?.value;
                  final latestDetection =
                      firestoreDetections?.latestDetection ??
                      plant.latestDetection;
                  final history =
                      (firestoreDetections?.history.isNotEmpty ?? false)
                      ? firestoreDetections!.history
                      : plant.history;
                  final latestDetections =
                      (firestoreDetections?.latestDetections.isNotEmpty ??
                          false)
                      ? firestoreDetections!.latestDetections
                      : (latestDetection != null
                            ? <DetectionItem>[latestDetection]
                            : history.take(1).toList());
                  final uniqueLatestDetections = _uniqueDetectionsByDisease(
                    latestDetections,
                  );
                  final latestSnapshotUrl =
                      _firstNonEmptySnapshot([
                        ...latestDetections,
                        ...history,
                      ]) ??
                      firestoreDetections?.latestSnapshotUrl.trim() ??
                      latestDetection?.snapshotUrl.trim() ??
                      '';
                  final latestCapturedAt =
                      _firstNonEmptyTime([...latestDetections, ...history]) ??
                      firestoreDetections?.latestCapturedAt.trim() ??
                      latestDetection?.time.trim() ??
                      '';

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LatestSnapshotCardWidget(
                          snapshotUrl: latestSnapshotUrl,
                          capturedAt: latestCapturedAt,
                        ),
                        SizedBox(height: 20.h),
                        CurrentDiseaseCardWidget(
                          latestDetection: latestDetection,
                        ),
                        SizedBox(height: 20.h),
                        "Danh sách bệnh mới nhất".h1Custom(
                          size: 16.sp,
                          color: AppColors.textMain,
                        ),
                        SizedBox(height: 12.h),
                        DiseaseHistoryListWidget(
                          items: uniqueLatestDetections,
                          emptyMessage: 'Chưa có dữ liệu bệnh mới nhất',
                        ),
                        SizedBox(height: 24.h),
                        "Lịch sử chụp".h1Custom(
                          size: 16.sp,
                          color: AppColors.textMain,
                        ),
                        SizedBox(height: 12.h),
                        CaptureHistoryListWidget(
                          items: history,
                          emptyMessage: 'Chưa có lịch sử chụp để hiển thị',
                        ),
                        SizedBox(height: 120.h),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Lỗi tải dữ liệu: $error')),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8.h,
            child: _BottomActionButtons(
              plantId: plantId,
              onCapturePressed: () => _handleCapturePressed(context, ref),
              onPhoneImagePressed: () =>
                  _showPhoneImageSourcePicker(context, ref),
              onAiPressed: () => _showAiAssistant(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showAiAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiChatbotSheet(),
    );
  }

  void _showPhoneImageSourcePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: EdgeInsets.all(16.r),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                'Gửi ảnh lên server'.h1Custom(
                  size: 17.sp,
                  color: AppColors.textMain,
                ),
                SizedBox(height: 6.h),
                'Chụp ảnh mới hoặc chọn ảnh từ thư viện để gửi qua API.'
                    .bodyCustom(size: 12.sp, color: AppColors.textSecondary),
                SizedBox(height: 14.h),
                _ImageSourceTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Chụp bằng camera điện thoại',
                  subtitle: 'Mở camera, chụp ảnh cây rồi gửi server',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickAndUploadImage(context, ref, ImageSource.camera);
                  },
                ),
                SizedBox(height: 8.h),
                _ImageSourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Chọn từ thư viện ảnh',
                  subtitle: 'Lấy ảnh có sẵn trong máy rồi gửi server',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickAndUploadImage(context, ref, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final inFlight = ref.read(
      diseaseImageUploadInFlightProvider(plantId).notifier,
    );
    if (inFlight.state) {
      return;
    }

    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (image == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    inFlight.state = true;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(diseaseImageUploadServiceProvider)
          .uploadImage(plantId: plantId, image: image);
      if (!context.mounted) {
        return;
      }

      ref.invalidate(plantDetectionsProvider(plantId));
      ref.invalidate(plantControllerProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã gửi ảnh lên server để phân tích')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      inFlight.state = false;
    }
  }

  Future<void> _handleCapturePressed(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final inFlight = ref.read(
      plantCaptureCommandInFlightProvider(plantId).notifier,
    );
    if (inFlight.state) {
      return;
    }

    inFlight.state = true;
    try {
      await ref
          .read(plantCaptureCommandServiceProvider)
          .requestCapture(plantId);
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lệnh chụp hình cho thiết bị')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gửi lệnh chụp thất bại: $error')));
    } finally {
      inFlight.state = false;
    }
  }
}

class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundGreen.withOpacity(0.72),
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, color: AppColors.accent, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title.bodyCustom(
                      size: 14.sp,
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: 3.h),
                    subtitle.bodyCustom(
                      size: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.disabledText,
                size: 14.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionButtons extends ConsumerWidget {
  final String plantId;
  final VoidCallback onCapturePressed;
  final VoidCallback onPhoneImagePressed;
  final VoidCallback onAiPressed;

  const _BottomActionButtons({
    required this.plantId,
    required this.onCapturePressed,
    required this.onPhoneImagePressed,
    required this.onAiPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSendingCapture = ref.watch(
      plantCaptureCommandInFlightProvider(plantId),
    );
    final isUploadingImage = ref.watch(
      diseaseImageUploadInFlightProvider(plantId),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        height: 56.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FloatingActionButton(
                heroTag: 'phone_image_$plantId',
                tooltip: 'Chụp hoặc chọn ảnh',
                backgroundColor: AppColors.primary,
                elevation: 4,
                onPressed: isUploadingImage ? null : onPhoneImagePressed,
                child: isUploadingImage
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.white,
                        size: 24.sp,
                      ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: FloatingActionButton(
                heroTag: 'capture_$plantId',
                tooltip: 'Chụp hình',
                backgroundColor: AppColors.accent,
                elevation: 4,
                onPressed: isSendingCapture ? null : onCapturePressed,
                child: isSendingCapture
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.photo_camera_outlined,
                        color: Colors.white,
                        size: 24.sp,
                      ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FloatingActionButton(
                heroTag: 'ai_$plantId',
                tooltip: 'AI',
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                elevation: 4,
                onPressed: onAiPressed,
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _firstNonEmptySnapshot(Iterable<DetectionItem> items) {
  for (final item in items) {
    final snapshot = item.snapshotUrl.trim();
    if (snapshot.isNotEmpty) {
      return snapshot;
    }
  }

  return null;
}

String? _firstNonEmptyTime(Iterable<DetectionItem> items) {
  for (final item in items) {
    final time = item.time.trim();
    if (time.isNotEmpty) {
      return time;
    }
  }

  return null;
}

List<DetectionItem> _uniqueDetectionsByDisease(List<DetectionItem> items) {
  final uniqueItems = <String, DetectionItem>{};

  for (final item in items) {
    final key = item.diseaseClass.trim().toLowerCase();
    if (key.isEmpty) {
      continue;
    }

    final existing = uniqueItems[key];
    if (existing == null || _isBetterDiseaseItem(item, existing)) {
      uniqueItems[key] = item;
    }
  }

  return uniqueItems.values.toList();
}

bool _isBetterDiseaseItem(DetectionItem candidate, DetectionItem current) {
  final confidenceCompare = candidate.confidence.compareTo(current.confidence);
  if (confidenceCompare != 0) {
    return confidenceCompare > 0;
  }

  final candidateHasSnapshot = candidate.snapshotUrl.trim().isNotEmpty;
  final currentHasSnapshot = current.snapshotUrl.trim().isNotEmpty;
  if (candidateHasSnapshot != currentHasSnapshot) {
    return candidateHasSnapshot;
  }

  final candidateTime = _tryParseDetectionTime(candidate.time);
  final currentTime = _tryParseDetectionTime(current.time);
  if (candidateTime != null && currentTime != null) {
    return candidateTime.isAfter(currentTime);
  }

  return candidate.time.compareTo(current.time) > 0;
}

DateTime? _tryParseDetectionTime(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }

  return DateTime.tryParse(normalized.replaceFirst(' ', 'T'));
}

Plant? _resolvePlantForScreen(List<Plant> plants, String plantId) {
  for (final plant in plants) {
    if (plant.id == plantId) {
      return plant;
    }
  }

  for (final plant in plants) {
    if (plant.id == 'all') {
      return plant;
    }
  }

  return null;
}
