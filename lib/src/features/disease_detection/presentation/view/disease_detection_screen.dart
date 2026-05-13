import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/chatbot/presentation/views/ai_chatbot_sheet.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/capture_command_controller.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/capture_history_cleanup_controller.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/disease_image_upload_controller.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/plant_detections_provider.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/capture_history_list_widget.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/current_disease_card_widget.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/disease_feedback_snack_bar.dart';
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
    final uploadedImageResult = ref.watch(
      diseaseImageUploadLatestResultProvider(plantId),
    );
    final isDeletingHistory = ref.watch(
      captureHistoryCleanupInFlightProvider(plantId),
    );
    final captureSnapshotRefreshKey = ref.watch(
      plantCaptureSnapshotRefreshKeyProvider(plantId),
    );

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
                  final hasFirestoreDetections =
                      firestoreDetections?.hasAnyData ?? false;
                  var latestDetection = hasFirestoreDetections
                      ? firestoreDetections!.latestDetection
                      : plant.latestDetection;
                  var history = hasFirestoreDetections
                      ? firestoreDetections!.history
                      : plant.history;
                  var latestDetections =
                      (firestoreDetections?.latestDetections.isNotEmpty ??
                          false)
                      ? firestoreDetections!.latestDetections
                      : (latestDetection != null
                            ? <DetectionItem>[latestDetection]
                            : history.take(1).toList());
                  final firestoreLatestSnapshot =
                      firestoreDetections?.latestSnapshotUrl.trim() ?? '';
                  final firestoreLatestCapturedAt =
                      firestoreDetections?.latestCapturedAt.trim() ?? '';
                  final displayItems = [...latestDetections, ...history];
                  var latestSnapshotUrl = firestoreLatestSnapshot.isNotEmpty
                      ? firestoreLatestSnapshot
                      : (_firestoreCaptureIsNewerThanItems(
                              firestoreLatestCapturedAt,
                              displayItems,
                            )
                            ? ''
                            : (_firstNonEmptySnapshot(displayItems) ??
                                  latestDetection?.snapshotUrl.trim() ??
                                  ''));
                  var latestCapturedAt = firestoreLatestCapturedAt.isNotEmpty
                      ? firestoreLatestCapturedAt
                      : (_firstNonEmptyTime(displayItems) ??
                            latestDetection?.time.trim() ??
                            '');
                  if (_shouldUseUploadedImageResult(
                    uploadedImageResult,
                    latestSnapshotUrl,
                    latestCapturedAt,
                    latestDetections,
                  )) {
                    final uploadDetections = uploadedImageResult!.detections;
                    if (_shouldUseUploadedSnapshot(uploadedImageResult)) {
                      latestSnapshotUrl =
                          uploadedImageResult.snapshotUrl.trim().isNotEmpty
                          ? uploadedImageResult.snapshotUrl.trim()
                          : latestSnapshotUrl;
                      latestCapturedAt =
                          uploadedImageResult.capturedAt.trim().isNotEmpty
                          ? uploadedImageResult.capturedAt.trim()
                          : latestCapturedAt;
                    }
                    latestDetection = uploadedImageResult.latestDetection;
                    latestDetections = uploadDetections;
                    history = [
                      if (uploadedImageResult.latestDetection != null)
                        uploadedImageResult.latestDetection!,
                      ...history,
                    ];
                  }
                  final uniqueLatestDetections = _uniqueDetectionsByDisease(
                    latestDetections,
                  );

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LatestSnapshotCardWidget(
                          snapshotUrl: latestSnapshotUrl,
                          capturedAt: latestCapturedAt,
                          cacheBustKey: captureSnapshotRefreshKey,
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
                        Row(
                          children: [
                            Expanded(
                              child: "Lịch sử chụp".h1Custom(
                                size: 16.sp,
                                color: AppColors.textMain,
                              ),
                            ),
                            if (history.isNotEmpty || hasFirestoreDetections)
                              TextButton.icon(
                                onPressed: isDeletingHistory
                                    ? null
                                    : () => _handleDeleteAllCaptureHistory(
                                        context,
                                        ref,
                                      ),
                                icon: isDeletingHistory
                                    ? SizedBox(
                                        width: 16.w,
                                        height: 16.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.delete_sweep_outlined,
                                        size: 18.sp,
                                      ),
                                label: Text(
                                  isDeletingHistory ? 'Đang xóa' : 'Xóa tất cả',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
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
      final uploadResult = await ref
          .read(diseaseImageUploadServiceProvider)
          .uploadImage(plantId: plantId, image: image);
      if (!context.mounted) {
        return;
      }

      ref.read(diseaseImageUploadLatestResultProvider(plantId).notifier).state =
          uploadResult;
      ref.invalidate(plantDetectionsProvider(plantId));
      ref.invalidate(plantControllerProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildDiseaseFeedbackSnackBar('Đã gửi ảnh lên server để phân tích'),
        );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildDiseaseFeedbackSnackBar(error.toString(), isError: true),
        );
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

    final previousMarker = _captureResultMarkerFromDetections(
      ref.read(plantDetectionsProvider(plantId)).asData?.value,
    );

    inFlight.state = true;
    try {
      ref.read(diseaseImageUploadLatestResultProvider(plantId).notifier).state =
          null;
      final requestId = await ref
          .read(plantCaptureCommandServiceProvider)
          .requestCapture(plantId);
      ref.read(plantCaptureSnapshotRefreshKeyProvider(plantId).notifier).state =
          requestId;
      ref.invalidate(plantDetectionsProvider(plantId));
      ref.invalidate(plantControllerProvider);
      final hasNewResult = await _waitForPiCaptureResult(
        context,
        ref,
        plantId: plantId,
        previousMarker: previousMarker,
        requestId: requestId,
      );
      ref.invalidate(plantControllerProvider);
      if (!context.mounted || hasNewResult) {
        return;
      }

      showDiseaseFeedbackSnackBar(
        context,
        'Pi xử lý lâu hơn dự kiến, app đã mở lại nút chụp.',
        isError: true,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      showDiseaseFeedbackSnackBar(
        context,
        'Gửi lệnh chụp thất bại: $error',
        isError: true,
      );
    } finally {
      inFlight.state = false;
    }
  }

  Future<void> _handleDeleteAllCaptureHistory(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa toàn bộ lịch sử chụp?'),
          content: const Text(
            'Thao tác này sẽ xóa các lần chụp đang lưu trên Firebase và không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Xóa tất cả'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final inFlight = ref.read(
      captureHistoryCleanupInFlightProvider(plantId).notifier,
    );
    if (inFlight.state) {
      return;
    }

    inFlight.state = true;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(captureHistoryCleanupServiceProvider)
          .deleteAll(plantId);
      if (!context.mounted) {
        return;
      }

      ref.read(diseaseImageUploadLatestResultProvider(plantId).notifier).state =
          null;
      ref.invalidate(plantDetectionsProvider(plantId));
      ref.invalidate(plantControllerProvider);

      final deletedText = result.deletedDocuments > 0
          ? 'Đã xóa ${result.deletedDocuments} lần chụp khỏi Firebase'
          : 'Đã dọn lịch sử chụp trên Firebase';
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(buildDiseaseFeedbackSnackBar(deletedText));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildDiseaseFeedbackSnackBar(
            'Xóa lịch sử chụp thất bại: $error',
            isError: true,
          ),
        );
    } finally {
      inFlight.state = false;
    }
  }
}

const _piCaptureResultWaitTimeout = Duration(seconds: 45);
const _piCaptureResultPollInterval = Duration(milliseconds: 900);
const _piCaptureSnapshotRefreshPolls = 4;
const _piCaptureFirestoreRefreshPolls = 7;

Future<bool> _waitForPiCaptureResult(
  BuildContext context,
  WidgetRef ref, {
  required String plantId,
  required _CaptureResultMarker previousMarker,
  required String requestId,
}) async {
  final stopwatch = Stopwatch()..start();
  var polls = 0;

  while (stopwatch.elapsed < _piCaptureResultWaitTimeout) {
    await Future.delayed(_piCaptureResultPollInterval);
    if (!context.mounted) {
      return false;
    }

    polls += 1;
    final currentMarker = _captureResultMarkerFromDetections(
      ref.read(plantDetectionsProvider(plantId)).asData?.value,
    );
    if (currentMarker.isNewerThan(previousMarker)) {
      ref.read(plantCaptureSnapshotRefreshKeyProvider(plantId).notifier).state =
          '${requestId}_${DateTime.now().millisecondsSinceEpoch}';
      return true;
    }

    if (polls % _piCaptureSnapshotRefreshPolls == 0) {
      ref.read(plantCaptureSnapshotRefreshKeyProvider(plantId).notifier).state =
          '${requestId}_${DateTime.now().millisecondsSinceEpoch}';
    }

    if (polls % _piCaptureFirestoreRefreshPolls == 0) {
      ref.invalidate(plantDetectionsProvider(plantId));
    }
  }

  return false;
}

class _CaptureResultMarker {
  const _CaptureResultMarker({
    required this.capturedAt,
    required this.snapshotKey,
    required this.historyLength,
    required this.latestFingerprint,
    required this.historyFingerprint,
  });

  final String capturedAt;
  final String snapshotKey;
  final int historyLength;
  final String latestFingerprint;
  final String historyFingerprint;

  bool get hasData =>
      capturedAt.isNotEmpty ||
      snapshotKey.isNotEmpty ||
      latestFingerprint.isNotEmpty ||
      historyFingerprint.isNotEmpty ||
      historyLength > 0;

  bool isNewerThan(_CaptureResultMarker previous) {
    if (!hasData) {
      return false;
    }
    if (!previous.hasData) {
      return true;
    }
    if (_markerTimeIsNewer(capturedAt, previous.capturedAt)) {
      return true;
    }
    if (historyLength > previous.historyLength) {
      return true;
    }
    if (snapshotKey.isNotEmpty && snapshotKey != previous.snapshotKey) {
      return true;
    }
    if (latestFingerprint.isNotEmpty &&
        latestFingerprint != previous.latestFingerprint) {
      return true;
    }
    return historyFingerprint.isNotEmpty &&
        historyFingerprint != previous.historyFingerprint &&
        historyLength >= previous.historyLength;
  }
}

_CaptureResultMarker _captureResultMarkerFromDetections(
  PlantDetectionsData? detections,
) {
  if (detections == null) {
    return const _CaptureResultMarker(
      capturedAt: '',
      snapshotKey: '',
      historyLength: 0,
      latestFingerprint: '',
      historyFingerprint: '',
    );
  }

  final latestItems = detections.latestDetections.isNotEmpty
      ? detections.latestDetections
      : <DetectionItem>[
          if (detections.latestDetection != null) detections.latestDetection!,
        ];
  final allItems = <DetectionItem>[...latestItems, ...detections.history];
  final capturedAt = detections.latestCapturedAt.trim().isNotEmpty
      ? detections.latestCapturedAt.trim()
      : (_firstNonEmptyTime(allItems) ?? '');
  final snapshotUrl = detections.latestSnapshotUrl.trim().isNotEmpty
      ? detections.latestSnapshotUrl.trim()
      : (_firstNonEmptySnapshot(allItems) ?? '');

  return _CaptureResultMarker(
    capturedAt: capturedAt,
    snapshotKey: _normalizeSnapshotKey(snapshotUrl),
    historyLength: detections.history.length,
    latestFingerprint: latestItems.take(4).map(_detectionMarkerKey).join('||'),
    historyFingerprint: detections.history
        .take(4)
        .map(_detectionMarkerKey)
        .join('||'),
  );
}

String _detectionMarkerKey(DetectionItem item) {
  return [
    item.diseaseClass.trim().toLowerCase(),
    item.time.trim(),
    _normalizeSnapshotKey(item.snapshotUrl),
    item.sourceDocumentPath.trim(),
    item.confidence.toStringAsFixed(4),
  ].join('|');
}

bool _markerTimeIsNewer(String current, String previous) {
  final currentTime = current.trim();
  final previousTime = previous.trim();
  if (currentTime.isEmpty) {
    return false;
  }
  if (previousTime.isEmpty) {
    return true;
  }

  final currentDate = _tryParseDetectionTime(currentTime);
  final previousDate = _tryParseDetectionTime(previousTime);
  if (currentDate != null && previousDate != null) {
    return currentDate.isAfter(previousDate);
  }

  return currentTime != previousTime;
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
                onPressed: isUploadingImage || isSendingCapture
                    ? null
                    : onPhoneImagePressed,
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
                onPressed: isSendingCapture ? null : onAiPressed,
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

bool _shouldUseUploadedImageResult(
  DiseaseImageUploadResult? uploadResult,
  String remoteSnapshotUrl,
  String remoteCapturedAt,
  List<DetectionItem> remoteLatestDetections,
) {
  if (uploadResult == null) {
    return false;
  }

  final uploadedSnapshotUrl = uploadResult.snapshotUrl.trim();
  final remoteSnapshot = remoteSnapshotUrl.trim();
  final uploadDetections = uploadResult.detections;
  final hasUploadData =
      uploadedSnapshotUrl.isNotEmpty || uploadDetections.isNotEmpty;
  final hasRemoteData =
      remoteSnapshot.isNotEmpty ||
      remoteCapturedAt.trim().isNotEmpty ||
      remoteLatestDetections.isNotEmpty;

  if (!hasUploadData) {
    return false;
  }

  if (!hasRemoteData) {
    return true;
  }

  if (uploadedSnapshotUrl.isNotEmpty &&
      _normalizeSnapshotKey(uploadedSnapshotUrl) ==
          _normalizeSnapshotKey(remoteSnapshot)) {
    return false;
  }

  final uploadedTime = _tryParseDetectionTime(uploadResult.capturedAt);
  final remoteTime =
      _newestDetectionTime(remoteLatestDetections) ??
      _tryParseDetectionTime(remoteCapturedAt);
  if (uploadedTime != null && remoteTime != null) {
    return remoteTime.isBefore(uploadedTime);
  }

  if (uploadDetections.isEmpty) {
    return uploadedSnapshotUrl.isNotEmpty;
  }

  if (remoteSnapshot.isNotEmpty &&
      _remoteSnapshotLooksLikeUploadedResult(
        uploadResult,
        remoteCapturedAt,
        remoteLatestDetections,
      )) {
    return false;
  }

  if (uploadResult.hasServerSnapshot) {
    return true;
  }

  return true;
}

bool _shouldUseUploadedSnapshot(DiseaseImageUploadResult uploadResult) {
  final uploadedSnapshotUrl = uploadResult.snapshotUrl.trim();
  if (uploadedSnapshotUrl.isEmpty) {
    return false;
  }

  if (uploadResult.hasServerSnapshot) {
    return true;
  }

  return uploadResult.detections.isEmpty ||
      uploadResult.detections.every(_isNoDiseaseDetection);
}

bool _remoteSnapshotLooksLikeUploadedResult(
  DiseaseImageUploadResult uploadResult,
  String remoteCapturedAt,
  List<DetectionItem> remoteLatestDetections,
) {
  final uploadDiseaseKeys = _diseaseKeys(uploadResult.detections);
  if (uploadDiseaseKeys.isEmpty || remoteLatestDetections.isEmpty) {
    return false;
  }

  final remoteDiseaseKeys = _diseaseKeys(remoteLatestDetections);
  if (!remoteDiseaseKeys.any(uploadDiseaseKeys.contains)) {
    return false;
  }

  final uploadedTime = _tryParseDetectionTime(uploadResult.capturedAt);
  final remoteTime =
      _newestDetectionTime(remoteLatestDetections) ??
      _tryParseDetectionTime(remoteCapturedAt);
  if (uploadedTime == null || remoteTime == null) {
    return true;
  }

  return remoteTime.difference(uploadedTime).abs() <= const Duration(hours: 12);
}

Set<String> _diseaseKeys(List<DetectionItem> items) {
  return {
    for (final item in items)
      if (item.diseaseClass.trim().isNotEmpty)
        item.diseaseClass.trim().toLowerCase(),
  };
}

bool _isNoDiseaseDetection(DetectionItem item) {
  final normalized = item.diseaseClass
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  return normalized == 'khong phat hien benh' ||
      normalized == 'không phát hiện bệnh' ||
      normalized == 'no disease detected';
}

DateTime? _newestDetectionTime(List<DetectionItem> items) {
  DateTime? newest;
  for (final item in items) {
    final parsed = _tryParseDetectionTime(item.time);
    if (parsed == null) {
      continue;
    }
    if (newest == null || parsed.isAfter(newest)) {
      newest = parsed;
    }
  }
  return newest;
}

String _normalizeSnapshotKey(String value) {
  return value.trim().replaceAll('\\', '/').toLowerCase();
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

bool _firestoreCaptureIsNewerThanItems(
  String firestoreCapturedAt,
  List<DetectionItem> items,
) {
  final firestoreTime = firestoreCapturedAt.trim();
  if (firestoreTime.isEmpty || items.isEmpty) {
    return false;
  }

  final newestItemTime =
      _newestDetectionTime(items) ??
      _tryParseDetectionTime(_firstNonEmptyTime(items) ?? '');
  final firestoreDate = _tryParseDetectionTime(firestoreTime);
  if (firestoreDate != null && newestItemTime != null) {
    return firestoreDate.isAfter(newestItemTime);
  }

  final itemTime = _firstNonEmptyTime(items);
  if (itemTime == null || itemTime.trim().isEmpty) {
    return false;
  }

  return firestoreTime.compareTo(itemTime) > 0;
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
