import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/chatbot/presentation/controllers/chatbot_controller.dart';
import 'package:app_iot/src/features/chatbot/presentation/views/ai_chatbot_sheet.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/disease_display_utils.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CurrentDiseaseCardWidget extends ConsumerWidget {
  final DetectionItem? latestDetection;

  const CurrentDiseaseCardWidget({super.key, this.latestDetection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (latestDetection == null) {
      return const SizedBox.shrink();
    }

    final detection = latestDetection!;
    final isHealthy = isHealthyDisease(detection.diseaseClass);
    final cardColor = isHealthy ? Colors.green.shade50 : Colors.red.shade50;
    final iconColor = isHealthy ? Colors.green : Colors.red;
    final iconData = isHealthy
        ? Icons.check_circle_outline
        : Icons.warning_amber_rounded;
    final metadataWidgets = <Widget>[
      if (detection.confidence > 0)
        "Độ tin cậy: ${(detection.confidence * 100).toStringAsFixed(1)}%"
            .bodyCustom(size: 12.sp, color: AppColors.disabledText),
      if (detection.time.trim().isNotEmpty)
        Text(
          detection.time,
          style: TextStyle(fontSize: 12.sp, color: AppColors.disabledText),
        ),
    ];

    return InkWell(
      onTap: () {
        if (isHealthy) {
          return;
        }

        final translated = translateDiseaseLabel(detection.diseaseClass);
        final confidencePercent =
            (detection.confidence * 100).toStringAsFixed(1);
        final prompt =
            "Cây của tôi đang bị '$translated' với độ tin cậy $confidencePercent%. "
            "Bạn có thể cho tôi biết mức độ tin cậy này có đáng lo không, nguyên nhân và cách phòng trị bệnh này không?";

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AiChatbotSheet(
            initialMessage: prompt,
            autoSendInitialMessage: true,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: iconColor.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: iconColor, size: 32.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  "Cảnh báo hiện tại".bodyCustom(
                    size: 14.sp,
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 4.h),
                  translateDiseaseLabel(detection.diseaseClass).bodyCustom(
                    size: 16.sp,
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                  if (metadataWidgets.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 4.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: metadataWidgets,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
