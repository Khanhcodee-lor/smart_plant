import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/regime/presentation/controllers/regime_realtime_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

class SensorStatus extends ConsumerWidget {
  const SensorStatus({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realtimeAsyncValue = ref.watch(regimeRealtimeDataProvider(plantId));

    return realtimeAsyncValue.when(
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            "Trạng thái môi trường".h1Custom(
              size: 16.sp,
              color: AppColors.textMain,
              fontweight: FontWeight.w600,
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildTemperatureCard(
                    context,
                    data.temperature,
                    plantId,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildHumidityCard(context, data.humidity, plantId),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildSoilMoistureCard(context, data.soilMoisture, plantId),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          const Center(child: Text("Lỗi tải dữ liệu cảm biến")),
    );
  }

  Widget _buildTemperatureCard(
    BuildContext context,
    double temp,
    String plantId,
  ) {
    return InkWell(
      onTap: () {
        context.push('/temperature/$plantId');
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            "Nhiệt độ".bodyCustom(
              size: 14.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 16.h),
            Center(
              child: CircularPercentIndicator(
                radius: 46.r,
                lineWidth: 8.w,
                percent: (temp / 50.0).clamp(0.0, 1.0), // Assuming 50C is max
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.thermostat,
                      color: const Color(0xFFFF7043),
                      size: 18.sp,
                    ),
                    "${temp.round()}°C".h1Custom(
                      size: 20.sp,
                      color: AppColors.textMain,
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                linearGradient: const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFF5252)],
                ),
                backgroundColor: const Color(0xFFFFB74D).withOpacity(0.2),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHumidityCard(
    BuildContext context,
    double humidity,
    String plantId,
  ) {
    return InkWell(
      onTap: () {
        context.push('/humidity/$plantId');
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            "Độ ẩm".bodyCustom(
              size: 14.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 16.h),
            Center(
              child: CircularPercentIndicator(
                radius: 46.r,
                lineWidth: 8.w,
                percent: (humidity / 100.0).clamp(0.0, 1.0),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: const Color(0xFF42A5F5),
                      size: 18.sp,
                    ),
                    "${humidity.round()}%".h1Custom(
                      size: 20.sp,
                      color: AppColors.textMain,
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                linearGradient: const LinearGradient(
                  colors: [Color(0xFF64B5F6), Color(0xFF3F51B5)],
                ),
                backgroundColor: const Color(0xFF64B5F6).withOpacity(0.2),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilMoistureCard(
    BuildContext context,
    double soilMoisture,
    String plantId,
  ) {
    return InkWell(
      onTap: () {
        context.push('/soil-moisture/$plantId');
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 36.r,
              lineWidth: 8.w,
              percent: (soilMoisture / 100.0).clamp(0.0, 1.0),
              center: Icon(
                Icons.eco,
                color: const Color(0xFF2E7D32),
                size: 28.sp,
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: const Color(0xFF2E7D32),
              backgroundColor: const Color(0xFF81C784).withOpacity(0.3),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  "Độ ẩm đất".bodyCustom(
                    size: 14.sp,
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 4.h),
                  "${soilMoisture.toStringAsFixed(1)}%".h1Custom(
                    size: 26.sp,
                    color: const Color(0xFF1B5E20),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF81C784).withOpacity(0.25),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: "Lý tưởng".bodyCustom(
                size: 13.sp,
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
