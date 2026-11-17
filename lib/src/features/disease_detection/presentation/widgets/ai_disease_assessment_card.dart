import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/chatbot/presentation/views/ai_chatbot_sheet.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:app_iot/src/features/regime/presentation/controllers/regime_realtime_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiDiseaseAssessmentCard extends StatelessWidget {
  const AiDiseaseAssessmentCard({
    super.key,
    required this.plantName,
    required this.latestDetection,
    required this.previousDetections,
    required this.sensorData,
  });

  final String plantName;
  final DetectionItem? latestDetection;
  final List<DetectionItem> previousDetections;
  final RegimeRealtimeData? sensorData;

  Map<String, dynamic> _buildContext() {
    final sensors = <String, dynamic>{};
    final data = sensorData;
    if (data != null) {
      if (data.hasTemperature) sensors['temperatureC'] = data.temperature;
      if (data.hasHumidity) sensors['humidityPercent'] = data.humidity;
      if (data.hasSoilMoisture) {
        sensors['soilMoisturePercent'] = data.soilMoisture;
      }
      if (data.light != null) sensors['lightReading'] = data.light;
      if (data.gasMq2 != null) sensors['gasMq2Reading'] = data.gasMq2;
      if (data.waterLevel != null) {
        sensors['waterLevelReading'] = data.waterLevel;
      }
      if (data.updatedAt.trim().isNotEmpty) {
        sensors['updatedAt'] = data.updatedAt.trim();
      }
    }

    return {
      'type': 'disease_assessment',
      'plantName': plantName.trim(),
      if (latestDetection != null)
        'currentDetection': {
          'disease': latestDetection!.diseaseClass,
          'confidence': latestDetection!.confidence,
          'time': latestDetection!.time,
        },
      'previousDetections': previousDetections.take(5).map((item) {
        return {
          'disease': item.diseaseClass,
          'confidence': item.confidence,
          'time': item.time,
        };
      }).toList(growable: false),
      'sensors': sensors,
    };
  }

  void _openAssessment(BuildContext context) {
    final previousCount = previousDetections.take(5).length;
    final historyInstruction = previousCount == 0
        ? 'Chưa có lần nhận diện trước đó để đối chiếu; hãy nói rõ giới hạn này.'
        : 'So sánh lần hiện tại với tối đa $previousCount lần nhận diện trước đó, bao gồm cả kết quả không phát hiện bệnh. Phân biệt bệnh từng xuất hiện với tình trạng hiện tại.';
    final initialMessage =
        'Hãy phân tích kết quả nhận diện hiện tại của cây cùng dữ liệu cảm biến môi trường mới nhất. '
        '$historyInstruction '
        'Nêu xu hướng và bằng chứng ủng hộ hoặc chưa phù hợp, đánh giá độ tin cậy, rồi đề xuất phương án chăm sóc hoặc bước kiểm tra cụ thể ngay lúc này. '
        'Chỉ đề nghị xử lý bệnh nếu kết quả hiện tại hoặc triệu chứng hỗ trợ; không khuyến nghị thuốc chỉ dựa vào bệnh trong lịch sử. '
        'Dùng đúng nhãn và số đo đã gửi, không tự thêm dữ liệu; hãy phân tích trước, không chỉ hỏi thêm thông tin.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiChatbotSheet(
        initialMessage: initialMessage,
        initialContext: _buildContext(),
        autoSendInitialMessage: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previousCount = previousDetections.take(5).length;
    final subtitle = previousCount == 0
        ? 'Lần hiện tại + cảm biến môi trường; chưa có lần trước để so sánh'
        : 'So sánh lần mới nhất với $previousCount lần trước + cảm biến môi trường';

    return Material(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: () => _openAssessment(context),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(15.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.accent,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    'AI phân tích tình trạng cây'.bodyCustom(
                      size: 14.sp,
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: 3.h),
                    subtitle.bodyCustom(
                      size: 11.sp,
                      color: AppColors.textSecondary,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.accent,
                size: 15.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
