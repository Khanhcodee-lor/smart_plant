import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/services/firebase/firebase_firestore_service.dart';
import 'package:app_iot/src/core/services/firebase/firebase_realtime_database_service.dart';
import 'package:app_iot/src/features/chatbot/presentation/views/ai_chatbot_sheet.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/capture_history_cleanup_controller.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/disease_image_upload_controller.dart';
import 'package:app_iot/src/features/disease_detection/presentation/controllers/plant_detections_provider.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/disease_feedback_snack_bar.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/disease_display_utils.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/latest_snapshot_card_widget.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/snapshot_image_viewer.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CaptureHistoryListWidget extends StatelessWidget {
  final List<DetectionItem> items;
  final String? plantId;
  final String emptyMessage;

  const CaptureHistoryListWidget({
    super.key,
    required this.items,
    this.plantId,
    this.emptyMessage = 'Chưa có lịch sử chụp',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: emptyMessage.bodyCustom(color: AppColors.disabledText),
        ),
      );
    }

    final displayGroups = <List<DetectionItem>>[];
    final seenTimes = <String>{};

    for (final item in items) {
      final key = item.time.trim();
      if (key.isEmpty) {
        displayGroups.add([item]);
      } else {
        if (!seenTimes.contains(key)) {
          seenTimes.add(key);
          displayGroups.add(items.where((i) => i.time.trim() == key).toList());
        }
      }
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayGroups.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final group = displayGroups[index];
        final item = group.reduce((a, b) => a.confidence > b.confidence ? a : b);
        final isHealthy = isHealthyDisease(item.diseaseClass);
        final hasSnapshot = item.snapshotUrl.trim().isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _CaptureHistoryDetailSheet(
                  items: group,
                  plantId: plantId,
                ),
              );
            },
            child: Ink(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46.w,
                    height: 46.w,
                    decoration: BoxDecoration(
                      color: hasSnapshot
                          ? AppColors.accent.withOpacity(0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      hasSnapshot
                          ? Icons.photo_camera_back_outlined
                          : Icons.photo_outlined,
                      color: hasSnapshot
                          ? AppColors.accent
                          : AppColors.disabledText,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: translateDiseaseLabel(item.diseaseClass)
                                  .bodyCustom(
                                    size: 14.sp,
                                    color: AppColors.textMain,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              isHealthy
                                  ? Icons.check_circle_outline
                                  : Icons.arrow_forward_ios,
                              color: isHealthy
                                  ? Colors.green
                                  : AppColors.disabledText,
                              size: 14.sp,
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        if (item.time.trim().isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                color: AppColors.disabledText,
                                size: 14.sp,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: item.time.bodyCustom(
                                  size: 12.sp,
                                  color: AppColors.disabledText,
                                ),
                              ),
                            ],
                          ),
                        if (item.confidence > 0) ...[
                          SizedBox(height: 4.h),
                          "Độ tin cậy ${(item.confidence * 100).toStringAsFixed(1)}%"
                              .bodyCustom(
                                size: 12.sp,
                                color: AppColors.disabledText,
                              ),
                        ],
                        SizedBox(height: 6.h),
                        (hasSnapshot
                                ? 'Xem ảnh và thông tin lần chụp'
                                : 'Không có ảnh lưu cho lần chụp này')
                            .bodyCustom(
                              size: 12.sp,
                              color: hasSnapshot
                                  ? AppColors.accent
                                  : AppColors.disabledText,
                              fontWeight: FontWeight.w500,
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CaptureHistoryDetailSheet extends ConsumerStatefulWidget {
  final List<DetectionItem> items;
  final String? plantId;

  const _CaptureHistoryDetailSheet({
    required this.items,
    this.plantId,
  });

  @override
  ConsumerState<_CaptureHistoryDetailSheet> createState() =>
      _CaptureHistoryDetailSheetState();
}

class _CaptureHistoryDetailSheetState
    extends ConsumerState<_CaptureHistoryDetailSheet> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.items;
    final item = group.reduce((a, b) => a.confidence > b.confidence ? a : b);
    final snapshotPath = item.snapshotUrl.trim();
    final shouldResolveSnapshot =
        snapshotPath.isNotEmpty &&
        !isLocalSnapshotImagePath(snapshotPath) &&
        !isInlineSnapshotImageData(snapshotPath);
    final snapshotAsync = shouldResolveSnapshot
        ? ref.watch(latestSnapshotUrlProvider(snapshotPath))
        : const AsyncValue<String>.data('');
    final effectiveSnapshotAsync = shouldResolveSnapshot
        ? snapshotAsync
        : (snapshotPath.isEmpty
              ? const AsyncValue<String>.data('')
              : AsyncValue<String>.data(snapshotPath));
    final isHealthy = group.every((i) => isHealthyDisease(i.diseaseClass));

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 46.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      "Chi tiết lần chụp".h1Custom(
                        size: 18.sp,
                        color: AppColors.textMain,
                      ),
                      SizedBox(height: 6.h),
                      "Ảnh cũ và bệnh đã phát hiện".bodyCustom(
                        size: 13.sp,
                        color: AppColors.disabledText,
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        height: 260.h,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGreen,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: effectiveSnapshotAsync.when(
                          data: (resolvedUrl) {
                            if (resolvedUrl.isEmpty) {
                              return const _HistorySnapshotPlaceholder(
                                icon: Icons.photo_outlined,
                                message: 'Không có ảnh lưu cho lần chụp này',
                              );
                            }

                            return GestureDetector(
                              onTap: () => showSnapshotImageViewer(
                                context,
                                imageUrl: resolvedUrl,
                                title: 'Ảnh lịch sử chụp',
                                subtitle: item.time,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  SnapshotImage(
                                    imageUrl: resolvedUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context) {
                                      return const _HistorySnapshotPlaceholder(
                                        icon: Icons.image_search_outlined,
                                        message: 'Đang tải ảnh...',
                                        showLoader: true,
                                      );
                                    },
                                    errorBuilder: (context) {
                                      return const _HistorySnapshotPlaceholder(
                                        icon: Icons.broken_image_outlined,
                                        message: 'Không tải được ảnh chụp',
                                      );
                                    },
                                  ),
                                  Positioned(
                                    top: 12.h,
                                    right: 12.w,
                                    child: Container(
                                      width: 34.w,
                                      height: 34.w,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.42),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.zoom_out_map_rounded,
                                        color: Colors.white,
                                        size: 18.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loading: () => const _HistorySnapshotPlaceholder(
                            icon: Icons.image_search_outlined,
                            message: 'Đang tải ảnh...',
                            showLoader: true,
                          ),
                          error: (_, _) => const _HistorySnapshotPlaceholder(
                            icon: Icons.broken_image_outlined,
                            message: 'Không tải được ảnh chụp',
                          ),
                        ),
                      ),
                      SizedBox(height: 18.h),
                      _HistoryInfoRow(
                        icon: isHealthy
                            ? Icons.eco_outlined
                            : Icons.bug_report_outlined,
                        label: 'Bệnh phát hiện',
                        value: group.map((i) => translateDiseaseLabel(i.diseaseClass)).toSet().join('\n'),
                        accentColor: isHealthy
                            ? Colors.green
                            : AppColors.warning,
                      ),
                      SizedBox(height: 12.h),
                      _HistoryInfoRow(
                        icon: Icons.schedule_outlined,
                        label: 'Thời gian chụp',
                        value: item.time.trim().isEmpty
                            ? 'Chưa có thời gian'
                            : item.time,
                      ),
                      SizedBox(height: 12.h),
                      _HistoryInfoRow(
                        icon: Icons.analytics_outlined,
                        label: 'Độ tin cậy',
                        value: group.any((i) => i.confidence > 0)
                            ? group.where((i) => i.confidence > 0).map((i) => '${translateDiseaseLabel(i.diseaseClass)}: ${(i.confidence * 100).toStringAsFixed(1)}%').join('\n')
                            : 'Chưa có dữ liệu',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton.icon(
                    onPressed: _handleAiAnalyzePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    icon: Icon(Icons.auto_awesome, size: 20.sp),
                    label: const Text('AI phân tích & khắc phục'),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton.icon(
                    onPressed: _isDeleting ? null : _handleDeletePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.disabled,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    icon: _isDeleting
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.delete_outline, size: 20.sp),
                    label: Text(_isDeleting ? 'Đang xóa...' : 'Xóa lần chụp'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAiAnalyzePressed() {
    final group = widget.items;
    final item = group.reduce((a, b) => a.confidence > b.confidence ? a : b);
    final diseaseLabel = group.map((i) => translateDiseaseLabel(i.diseaseClass)).toSet().join(', ');
    final confidence = group.any((i) => i.confidence > 0)
        ? group.where((i) => i.confidence > 0).map((i) => '${translateDiseaseLabel(i.diseaseClass)} (${(i.confidence * 100).toStringAsFixed(1)}%)').join(', ')
        : 'Chưa có dữ liệu';
    final capturedAt = item.time.trim().isEmpty
        ? 'Chưa có thời gian'
        : item.time.trim();
    final snapshotPath = item.snapshotUrl.trim();
    final prompt =
        '''
Bạn là trợ lý nông nghiệp cho ứng dụng IoT trồng cây. Hãy phân tích lần chụp bệnh cây này và đưa ra hướng khắc phục thực tế bằng tiếng Việt.

Dữ liệu phát hiện:
- Bệnh/triệu chứng: $diseaseLabel
- Nhãn gốc AI: ${item.diseaseClass}
- Độ tin cậy: $confidence
- Thời gian chụp: $capturedAt
- Có ảnh lưu: ${snapshotPath.isEmpty ? 'Không' : 'Có'}

Yêu cầu trả lời ngắn gọn theo các mục:
1. Nhận định mức độ bệnh.
2. Việc cần làm ngay.
3. Cách xử lý/khắc phục trong vài ngày tới.
4. Phòng ngừa tái phát.
5. Lưu ý an toàn nếu dùng thuốc hoặc chế phẩm sinh học.
''';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AiChatbotSheet(initialMessage: prompt, autoSendInitialMessage: true),
    );
  }

  String _tryResolvePlantId() {
    final direct = widget.plantId?.trim() ?? '';
    if (direct.isNotEmpty) {
      return direct;
    }

    for (final item in widget.items) {
      final path = item.sourceDocumentPath.trim();
      final match = RegExp(r'plants?/([^/]+)').firstMatch(path);
      if (match != null && (match.group(1)?.isNotEmpty ?? false)) {
        return match.group(1)!;
      }
      final snapshot = item.snapshotUrl.trim();
      final snapMatch = RegExp(r'plants/([^/]+)').firstMatch(snapshot);
      if (snapMatch != null && (snapMatch.group(1)?.isNotEmpty ?? false)) {
        return snapMatch.group(1)!;
      }
    }

    final plants =
        ref.read(plantControllerProvider).asData?.value ?? const <Plant>[];
    if (plants.length == 1) {
      return plants.first.id;
    }
    return '';
  }

  Future<void> _handleDeletePressed() async {
    final plantId = _tryResolvePlantId();
    final documentPaths = widget.items
        .map((i) => i.sourceDocumentPath.trim())
        .where((p) => p.isNotEmpty)
        .toSet();

    setState(() {
      _isDeleting = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (documentPaths.isEmpty && plantId.isNotEmpty) {
        for (final item in widget.items) {
          final snapshot = item.snapshotUrl.trim();
          final match =
              RegExp(r'(mobile_upload_[0-9]+_[a-f0-9]+)').firstMatch(snapshot);
          if (match != null) {
            documentPaths.add('plants/$plantId/plant_captures/${match.group(1)!}');
            break;
          }
        }
      }

      final rtdb = ref.read(firebaseRealtimeDatabaseServiceProvider);

      if (documentPaths.isEmpty && plantId.isNotEmpty) {
        for (final base in ['plants/$plantId', 'plant/$plantId']) {
          try {
            final captures = await rtdb.getData('$base/plant_captures');
            if (captures is Map) {
              for (final entry in captures.entries) {
                final captureMap =
                    entry.value is Map ? entry.value as Map : const {};
                final capTime = (captureMap['time'] ??
                        captureMap['timestamp'] ??
                        captureMap['captured_at'] ??
                        '')
                    .toString();
                final capSnapshot = (captureMap['snapshot_url'] ??
                        captureMap['image_url'] ??
                        captureMap['annotated_frame_storage_path'] ??
                        '')
                    .toString();

                final matches = widget.items.any((item) {
                  return (item.time.trim().isNotEmpty &&
                          capTime.contains(item.time.trim())) ||
                      (item.snapshotUrl.trim().isNotEmpty &&
                          capSnapshot.contains(item.snapshotUrl.trim()));
                });
                if (matches) {
                  documentPaths.add('$base/plant_captures/${entry.key}');
                }
              }
            }
          } catch (_) {}
        }
      }

      if (plantId.isNotEmpty) {
        final uploadedResult =
            ref.read(diseaseImageUploadLatestResultProvider(plantId));
        if (uploadedResult != null) {
          final matchesUploaded = widget.items.any((i) =>
              (i.time.trim().isNotEmpty &&
                  uploadedResult.capturedAt == i.time.trim()) ||
              (i.snapshotUrl.trim().isNotEmpty &&
                  uploadedResult.snapshotUrl == i.snapshotUrl.trim()) ||
              (uploadedResult.requestId.isNotEmpty &&
                  i.snapshotUrl.contains(uploadedResult.requestId)));
          if (matchesUploaded) {
            if (uploadedResult.requestId.isNotEmpty) {
              documentPaths.add(
                  'plants/$plantId/plant_captures/${uploadedResult.requestId}');
            }
            ref
                .read(diseaseImageUploadLatestResultProvider(plantId).notifier)
                .state = null;
          }
        }
      }

      if (documentPaths.isEmpty && plantId.isEmpty) {
        showDiseaseFeedbackSnackBar(
          context,
          'Không tìm thấy đường dẫn Firebase để xóa',
          isError: true,
        );
        return;
      }

      final deletedIdentifiers = <String>{};
      for (final item in widget.items) {
        final docPath = item.sourceDocumentPath.trim();
        if (docPath.isNotEmpty) {
          deletedIdentifiers.add(docPath);
          final docId = docPath.split('/').last.trim();
          if (docId.isNotEmpty) {
            deletedIdentifiers.add(docId);
          }
        }
        final time = item.time.trim();
        if (time.isNotEmpty) {
          deletedIdentifiers.add(time);
        }
        final snapshot = item.snapshotUrl.trim();
        if (snapshot.isNotEmpty) {
          deletedIdentifiers.add(snapshot);
          final match = RegExp(
            r'(mobile_upload_[0-9]+_[a-f0-9]+|manual_[0-9]+_[a-zA-Z0-9_]+)',
          ).firstMatch(snapshot);
          if (match != null) {
            deletedIdentifiers.add(match.group(1)!);
          }
        }
      }

      for (final path in documentPaths) {
        final docId = path.split('/').last.trim();
        if (docId.isNotEmpty) {
          deletedIdentifiers.add(docId);
        }
        deletedIdentifiers.add(path);
      }

      if (plantId.isNotEmpty) {
        ref.read(deletedCapturesProvider(plantId).notifier).update((current) {
          return {...current, ...deletedIdentifiers};
        });

        for (final identifier in deletedIdentifiers) {
          final safeKey = identifier.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
          if (safeKey.isNotEmpty) {
            try {
              await rtdb.setData('plants/$plantId/deleted_captures/$safeKey', true);
              await rtdb.setData('plant/$plantId/deleted_captures/$safeKey', true);
            } catch (_) {}
          }
        }
      }

      for (final path in documentPaths) {
        try {
          await rtdb.deleteData(path);
        } catch (_) {}

        final mirror = path.startsWith('plants/')
            ? 'plant/${path.substring(7)}'
            : (path.startsWith('plant/') ? 'plants/${path.substring(6)}' : null);
        if (mirror != null) {
          try {
            await rtdb.deleteData(mirror);
          } catch (_) {}
        }
      }

      final firestore = ref.read(firebaseFirestoreServiceProvider);
      for (final path in documentPaths) {
        try {
          if (!path.contains('/plant_captures') && !path.contains('/detections')) {
            await firestore.updateData(path, clearLatestDetectionFields());
          } else {
            await firestore.deleteData(path);
          }
        } catch (_) {}

        final mirror = path.startsWith('plants/')
            ? 'plant/${path.substring(7)}'
            : (path.startsWith('plant/') ? 'plants/${path.substring(6)}' : null);
        if (mirror != null) {
          try {
            if (!mirror.contains('/plant_captures') &&
                !mirror.contains('/detections')) {
              await firestore.updateData(mirror, clearLatestDetectionFields());
            } else {
              await firestore.deleteData(mirror);
            }
          } catch (_) {}
        }
      }

      for (final item in widget.items) {
        final url = item.snapshotUrl.trim();
        if (url.isEmpty) {
          continue;
        }
        try {
          if (url.startsWith('http://') ||
              url.startsWith('https://') ||
              url.startsWith('gs://')) {
            await FirebaseStorage.instance.refFromURL(url).delete();
          } else if (!url.startsWith('/')) {
            await FirebaseStorage.instance.ref(url).delete();
          }
        } catch (_) {}
      }

      if (plantId.isNotEmpty) {
        ref.invalidate(plantDetectionsProvider(plantId));
        ref.invalidate(plantControllerProvider);
      }

      if (!mounted) {
        return;
      }

      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildDiseaseFeedbackSnackBar('Đã xóa lần chụp khỏi Firebase'),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildDiseaseFeedbackSnackBar('Xóa thất bại: $error', isError: true),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}

class _HistoryInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  const _HistoryInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = accentColor ?? AppColors.accent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: iconColor, size: 18.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label.bodyCustom(size: 12.sp, color: AppColors.disabledText),
              SizedBox(height: 4.h),
              value.bodyCustom(
                size: 14.sp,
                color: AppColors.textMain,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistorySnapshotPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool showLoader;

  const _HistorySnapshotPlaceholder({
    required this.icon,
    required this.message,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLoader) ...[
              SizedBox(
                width: 28.w,
                height: 28.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(height: 12.h),
            ] else ...[
              Icon(icon, size: 34.sp, color: AppColors.disabledText),
              SizedBox(height: 10.h),
            ],
            message.bodyCustom(
              size: 14.sp,
              color: AppColors.disabledText,
              fontWeight: FontWeight.w500,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
