import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/regime/presentation/controllers/regime_realtime_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SensorStatus extends ConsumerWidget {
  const SensorStatus({super.key, required this.plantId});

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realtimeAsyncValue = ref.watch(regimeRealtimeDataProvider(plantId));

    return realtimeAsyncValue.when(
      data: (data) {
        final missingReadings = <String>[
          if (!data.hasTemperature) 'nhiệt độ',
          if (!data.hasHumidity) 'độ ẩm',
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trạng thái môi trường',
              style: TextStyle(
                color: AppColors.textMain,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Theo dõi các chỉ số cảm biến',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: _buildAirMetricCard(
                    title: 'Nhiệt độ',
                    value: data.hasTemperature
                        ? data.temperature.toStringAsFixed(1)
                        : '—',
                    unit: data.hasTemperature ? '°C' : '',
                    icon: Icons.thermostat_rounded,
                    accent: const Color(0xFFF08A58),
                    softAccent: const Color(0xFFFFF1E8),
                    hasValue: data.hasTemperature,
                    onTap: () => context.push('/temperature/$plantId'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildAirMetricCard(
                    title: 'Độ ẩm không khí',
                    value: data.hasHumidity
                        ? data.humidity.toStringAsFixed(0)
                        : '—',
                    unit: data.hasHumidity ? '%' : '',
                    icon: Icons.water_drop_rounded,
                    accent: const Color(0xFF4B9EE8),
                    softAccent: const Color(0xFFEAF5FF),
                    hasValue: data.hasHumidity,
                    onTap: () => context.push('/humidity/$plantId'),
                  ),
                ),
              ],
            ),
            if (missingReadings.isNotEmpty) ...[
              SizedBox(height: 9.h),
              _buildMissingReadingsNote(missingReadings),
            ],
            SizedBox(height: 14.h),
            _buildSoilMoistureCard(
              context: context,
              soilMoisture: data.soilMoisture,
              hasValue: data.hasSoilMoisture,
            ),
            if (data.light != null ||
                data.gasMq2 != null ||
                data.waterLevel != null) ...[
              SizedBox(height: 12.h),
              _buildAdditionalReadingsCard(data),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (error, _) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Text(
          'Không tải được dữ liệu cảm biến.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
        ),
      ),
    );
  }

  Widget _buildAirMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accent,
    required Color softAccent,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: hasValue ? onTap : null,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          height: 144.h,
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.84),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.035),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: softAccent,
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    child: Icon(icon, color: accent, size: 19.sp),
                  ),
                  const Spacer(),
                  if (hasValue)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.disabledText,
                      size: 16.sp,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3.h),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: hasValue
                        ? AppColors.textMain
                        : AppColors.disabledText,
                    fontSize: 25.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                  children: [
                    TextSpan(text: value),
                    if (unit.isNotEmpty)
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissingReadingsNote(List<String> missingReadings) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 15.sp,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            'Chưa có ${missingReadings.join(' và ')} từ cảm biến.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.sp,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSoilMoistureCard({
    required BuildContext context,
    required double soilMoisture,
    required bool hasValue,
  }) {
    final statusLabel = !hasValue
        ? 'Chưa có'
        : soilMoisture <= 0
        ? 'Cần kiểm tra'
        : 'Đã đo';
    final statusColor = !hasValue || soilMoisture <= 0
        ? AppColors.warning
        : AppColors.success;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: hasValue ? () => context.push('/soil-moisture/$plantId') : null,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.86),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.035),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F7EE),
                      borderRadius: BorderRadius.circular(17.r),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      color: const Color(0xFF34834A),
                      size: 25.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Độ ẩm đất',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          hasValue
                              ? '${soilMoisture.toStringAsFixed(1)}%'
                              : '—',
                          style: TextStyle(
                            color: AppColors.textMain,
                            fontSize: 23.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(999.r),
                child: LinearProgressIndicator(
                  value: hasValue
                      ? (soilMoisture / 100).clamp(0.0, 1.0).toDouble()
                      : 0.0,
                  minHeight: 6.h,
                  backgroundColor: const Color(0xFFE8F0EB),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalReadingsCard(RegimeRealtimeData data) {
    final readings = <_AdditionalSensorReading>[
      if (data.light != null)
        _AdditionalSensorReading(
          icon: Icons.wb_sunny_outlined,
          label: 'Ánh sáng',
          value: data.light!,
          accent: const Color(0xFFDA9A32),
          softAccent: const Color(0xFFFFF4DF),
        ),
      if (data.gasMq2 != null)
        _AdditionalSensorReading(
          icon: Icons.air_rounded,
          label: 'Khí gas',
          value: data.gasMq2!,
          accent: const Color(0xFF4B9EE8),
          softAccent: const Color(0xFFEAF5FF),
        ),
      if (data.waterLevel != null)
        _AdditionalSensorReading(
          icon: Icons.water_drop_outlined,
          label: 'Mực nước',
          value: data.waterLevel!,
          accent: AppColors.accent,
          softAccent: const Color(0xFFE4F7F3),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F4),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  Icons.sensors_rounded,
                  color: AppColors.accent,
                  size: 17.sp,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  'Cảm biến khác',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${readings.length} chỉ số',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < readings.length; index++) ...[
                if (index > 0) SizedBox(width: 12.w),
                Expanded(child: _buildAdditionalMetric(readings[index])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalMetric(_AdditionalSensorReading reading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: reading.softAccent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            reading.icon,
            size: 16.sp,
            color: reading.accent,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          reading.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          _formatSensorValue(reading.value),
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _AdditionalSensorReading {
  const _AdditionalSensorReading({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.softAccent,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color accent;
  final Color softAccent;
}

String _formatSensorValue(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
