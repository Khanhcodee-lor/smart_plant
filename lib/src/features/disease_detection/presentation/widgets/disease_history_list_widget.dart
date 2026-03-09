import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DiseaseHistoryListWidget extends StatelessWidget {
  final List<DetectionItem> history;

  const DiseaseHistoryListWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: "Chưa có lịch sử phát hiện bệnh".bodyCustom(
            color: AppColors.disabledText,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final item = history[index];
        final isHealthy = item.diseaseClass.toLowerCase() == 'healthy';

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

        String translatedDisease =
            diseaseTranslations[item.diseaseClass.toLowerCase()] ??
            item.diseaseClass;

        return Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHealthy ? Icons.eco : Icons.bug_report,
                  color: isHealthy ? Colors.green : Colors.red,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    translatedDisease.bodyCustom(
                      size: 14.sp,
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w600,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        "Độ tin cậy: ${(item.confidence * 100).toStringAsFixed(1)}%"
                            .bodyCustom(
                              size: 12.sp,
                              color: AppColors.disabledText,
                            ),
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: 10.sp,
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
        );
      },
    );
  }
}
