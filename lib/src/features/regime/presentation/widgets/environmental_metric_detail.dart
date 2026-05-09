import 'dart:math' as math;

import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/environmental_chart_card.dart';
import 'package:app_iot/src/shared/animations/animated_globe.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EnvironmentalMetricDetail extends StatelessWidget {
  final String metricName;
  final String chartTitle;
  final double currentValue;
  final String heroUnit;
  final String chartUnit;
  final int fractionDigits;
  final IconData icon;
  final Color accentColor;
  final Color baseColor;
  final Color shadowColor;
  final Color textColor;
  final double idealMin;
  final double idealMax;
  final List<FlSpot> spots;
  final List<String> xLabels;

  const EnvironmentalMetricDetail({
    super.key,
    required this.metricName,
    required this.chartTitle,
    required this.currentValue,
    required this.heroUnit,
    required this.chartUnit,
    required this.icon,
    required this.accentColor,
    required this.baseColor,
    required this.shadowColor,
    required this.textColor,
    required this.idealMin,
    required this.idealMax,
    required this.spots,
    required this.xLabels,
    this.fractionDigits = 1,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _MetricStats.fromSpots(spots, currentValue);
    final statusLabel = _statusLabel;
    final statusColor = _statusColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedGlobe(
          val: currentValue.toStringAsFixed(fractionDigits),
          unit: heroUnit,
          subtitle: metricName,
          baseColor: baseColor,
          shadowColor: shadowColor,
          textColor: textColor,
          accentColor: accentColor,
          icon: icon,
        ),
        SizedBox(height: 18.h),
        _MetricOverviewCard(
          metricName: metricName,
          currentValue: currentValue,
          unit: chartUnit,
          fractionDigits: fractionDigits,
          icon: icon,
          accentColor: accentColor,
          textColor: textColor,
          statusLabel: statusLabel,
          statusColor: statusColor,
          idealRange:
              '${_formatCompact(idealMin)}-${_formatCompact(idealMax)}$chartUnit',
          stats: stats,
        ),
        SizedBox(height: 16.h),
        EnvironmentalChartCard(
          title: chartTitle,
          chartColor: accentColor,
          spots: spots,
          xLabels: xLabels,
          unit: chartUnit,
        ),
      ],
    );
  }

  String get _statusLabel {
    if (currentValue == 0 && spots.length <= 1) {
      return 'Đang chờ';
    }
    if (currentValue < idealMin) {
      return 'Thấp';
    }
    if (currentValue > idealMax) {
      return 'Cao';
    }
    return 'Lý tưởng';
  }

  Color get _statusColor {
    if (_statusLabel == 'Lý tưởng') {
      return AppColors.primary;
    }
    if (_statusLabel == 'Đang chờ') {
      return AppColors.textSecondary;
    }
    return const Color(0xFFFF7043);
  }
}

class _MetricOverviewCard extends StatelessWidget {
  final String metricName;
  final double currentValue;
  final String unit;
  final int fractionDigits;
  final IconData icon;
  final Color accentColor;
  final Color textColor;
  final String statusLabel;
  final Color statusColor;
  final String idealRange;
  final _MetricStats stats;

  const _MetricOverviewCard({
    required this.metricName,
    required this.currentValue,
    required this.unit,
    required this.fractionDigits,
    required this.icon,
    required this.accentColor,
    required this.textColor,
    required this.statusLabel,
    required this.statusColor,
    required this.idealRange,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.86), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
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
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(icon, color: accentColor, size: 25.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    metricName.h2Custom(
                      size: 16.sp,
                      color: AppColors.textMain,
                      fontweight: FontWeight.w700,
                    ),
                    SizedBox(height: 4.h),
                    'Dải lý tưởng $idealRange'.labelCustom(
                      size: 12.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: statusLabel.labelCustom(
                  size: 12.sp,
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _formatValue(currentValue, unit, fractionDigits),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 34.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
              'Hiện tại'.labelCustom(
                size: 12.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: AppColors.divider.withOpacity(0.85), height: 1),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Thấp nhất',
                  value: _formatValue(stats.min, unit, fractionDigits),
                ),
              ),
              _VerticalDivider(color: accentColor),
              Expanded(
                child: _StatTile(
                  label: 'Trung bình',
                  value: _formatValue(stats.average, unit, fractionDigits),
                ),
              ),
              _VerticalDivider(color: accentColor),
              Expanded(
                child: _StatTile(
                  label: 'Cao nhất',
                  value: _formatValue(stats.max, unit, fractionDigits),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        label.labelCustom(
          size: 10.sp,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: 5.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final Color color;

  const _VerticalDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36.h,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      color: color.withOpacity(0.12),
    );
  }
}

class _MetricStats {
  final double min;
  final double max;
  final double average;

  const _MetricStats({
    required this.min,
    required this.max,
    required this.average,
  });

  factory _MetricStats.fromSpots(List<FlSpot> spots, double fallback) {
    final values = spots.isEmpty
        ? <double>[fallback]
        : spots.map((spot) => spot.y).toList(growable: false);
    final sum = values.fold<double>(0, (total, value) => total + value);

    return _MetricStats(
      min: values.reduce(math.min),
      max: values.reduce(math.max),
      average: sum / values.length,
    );
  }
}

String _formatValue(double value, String unit, int fractionDigits) {
  final digits = unit == '%' ? 0 : fractionDigits;
  return '${value.toStringAsFixed(digits)}$unit';
}

String _formatCompact(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}
