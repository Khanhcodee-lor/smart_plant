import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/disease_display_utils.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DiseaseHistoryListWidget extends StatelessWidget {
  final List<DetectionItem> items;
  final String emptyMessage;

  const DiseaseHistoryListWidget({
    super.key,
    required this.items,
    this.emptyMessage = 'Chưa có lịch sử phát hiện bệnh',
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
        final translatedDisease = translateDiseaseLabel(item.diseaseClass);
        final metadataWidgets = <Widget>[
          if (item.confidence > 0)
            "Độ tin cậy: ${(item.confidence * 100).toStringAsFixed(1)}%"
                .bodyCustom(size: 12.sp, color: AppColors.disabledText),
          if (item.time.trim().isNotEmpty)
            Text(
              item.time,
              style: TextStyle(fontSize: 10.sp, color: AppColors.disabledText),
            ),
        ];

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
                    if (metadataWidgets.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 4.h,
                        alignment: WrapAlignment.spaceBetween,
                        children: metadataWidgets,
                      ),
                    ],
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
