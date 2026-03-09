import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app_iot/src/features/chatbot/presentation/views/ai_chatbot_sheet.dart';
import 'package:app_iot/src/features/chatbot/presentation/controllers/chatbot_controller.dart';

class CurrentDiseaseCardWidget extends ConsumerWidget {
  final DetectionItem? latestDetection;

  const CurrentDiseaseCardWidget({super.key, this.latestDetection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (latestDetection == null) {
      return const SizedBox.shrink();
    }

    final Map<String, String> diseaseTranslations = {
      'healthy': 'Khỏe mạnh',
      'tomato leaf late blight': 'Bệnh mốc sương trên lá cà chua',
      'tomato leaf early blight': 'Bệnh đốm vòng trên lá cà chua',
      'tomato leaf mold': 'Bệnh nấm lá cà chua',
      'tomato yellow leaf curl virus': 'Bệnh xoăn vàng lá do virus',
      'tomato mosaic virus': 'Bệnh khảm lá do virus',
      'tomato septoria leaf spot': 'Bệnh đốm lá Septoria',
      'tomato spider mites two-spotted spider mite': 'Nhện đỏ',
      'tomato target spot': 'Bệnh đốm vòng (Target Spot)',
      'tomato bacterial spot': 'Bệnh đốm vi khuẩn',
      // Thêm các bệnh khác nếu cần
    };

    String translateDisease(String diseaseName) {
      return diseaseTranslations[diseaseName.toLowerCase()] ?? diseaseName;
    }

    final isHealthy = latestDetection!.diseaseClass.toLowerCase() == 'healthy';
    final cardColor = isHealthy ? Colors.green.shade50 : Colors.red.shade50;
    final iconColor = isHealthy ? Colors.green : Colors.red;
    final iconData = isHealthy
        ? Icons.check_circle_outline
        : Icons.warning_amber_rounded;

    return InkWell(
      onTap: () {
        if (!isHealthy) {
          final translated = translateDisease(latestDetection!.diseaseClass);
          final prompt =
              "Cây của tôi đang bị '$translated'. Bạn có thể cho tôi biết nguyên nhân và cách phòng trị bệnh này không?";

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AiChatbotSheet(),
          );

          Future.delayed(const Duration(milliseconds: 300), () {
            ref.read(chatbotControllerProvider.notifier).sendMessage(prompt);
          });
        }
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
                  translateDisease(latestDetection!.diseaseClass).bodyCustom(
                    size: 16.sp,
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      "Độ tin cậy: ${(latestDetection!.confidence * 100).toStringAsFixed(1)}%"
                          .bodyCustom(
                            size: 12.sp,
                            color: AppColors.disabledText,
                          ),
                      Text(
                        latestDetection!.time,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.disabledText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
