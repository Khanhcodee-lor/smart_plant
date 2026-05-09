import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/services/firebase/firebase_firestore_service.dart';
import 'package:app_iot/src/features/chatbot/presentation/views/ai_chatbot_sheet.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/disease_display_utils.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/latest_snapshot_card_widget.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CaptureHistoryListWidget extends StatelessWidget {
  final List<DetectionItem> items;
  final String emptyMessage;

  const CaptureHistoryListWidget({
    super.key,
    required this.items,
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final item = items[index];
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
                builder: (_) => _CaptureHistoryDetailSheet(item: item),
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
  final DetectionItem item;

  const _CaptureHistoryDetailSheet({required this.item});

  @override
  ConsumerState<_CaptureHistoryDetailSheet> createState() =>
      _CaptureHistoryDetailSheetState();
}

class _CaptureHistoryDetailSheetState
    extends ConsumerState<_CaptureHistoryDetailSheet> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final snapshotPath = item.snapshotUrl.trim();
    final snapshotAsync = snapshotPath.isEmpty
        ? const AsyncValue<String>.data('')
        : ref.watch(latestSnapshotUrlProvider(snapshotPath));
    final diseaseLabel = translateDiseaseLabel(item.diseaseClass);
    final isHealthy = isHealthyDisease(item.diseaseClass);

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
                        child: snapshotAsync.when(
                          data: (resolvedUrl) {
                            if (resolvedUrl.isEmpty) {
                              return const _HistorySnapshotPlaceholder(
                                icon: Icons.photo_outlined,
                                message: 'Không có ảnh lưu cho lần chụp này',
                              );
                            }

                            return Image.network(
                              resolvedUrl,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }

                                    return const _HistorySnapshotPlaceholder(
                                      icon: Icons.image_search_outlined,
                                      message: 'Đang tải ảnh...',
                                      showLoader: true,
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return const _HistorySnapshotPlaceholder(
                                  icon: Icons.broken_image_outlined,
                                  message: 'Không tải được ảnh chụp',
                                );
                              },
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
                        value: diseaseLabel,
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
                        value: item.confidence > 0
                            ? '${(item.confidence * 100).toStringAsFixed(1)}%'
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
    final item = widget.item;
    final diseaseLabel = translateDiseaseLabel(item.diseaseClass);
    final confidence = item.confidence > 0
        ? '${(item.confidence * 100).toStringAsFixed(1)}%'
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

  Future<void> _handleDeletePressed() async {
    final documentPath = widget.item.sourceDocumentPath.trim();
    if (documentPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy đường dẫn Firebase để xóa'),
        ),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref.read(firebaseFirestoreServiceProvider).deleteData(documentPath);
      if (!mounted) {
        return;
      }

      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xóa lần chụp khỏi Firebase')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text('Xóa thất bại: $error')));
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
