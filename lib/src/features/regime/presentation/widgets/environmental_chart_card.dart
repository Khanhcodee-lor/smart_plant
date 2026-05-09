import 'dart:math' as math;

import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EnvironmentalChartCard extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final List<String> xLabels;
  final Color chartColor;
  final String unit;

  const EnvironmentalChartCard({
    super.key,
    required this.title,
    required this.spots,
    required this.xLabels,
    required this.chartColor,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final chartSpots = spots
        .where((spot) => spot.x.isFinite && spot.y.isFinite)
        .toList(growable: false);
    final hasChart = chartSpots.length >= 2;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.86), width: 1),
        boxShadow: [
          BoxShadow(
            color: chartColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: title.h2Custom(
                  size: 18.sp,
                  color: AppColors.textMain,
                  fontweight: FontWeight.w700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: chartColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: (hasChart ? '${chartSpots.length} điểm' : 'Đang chờ')
                    .labelCustom(
                      size: 11.sp,
                      color: chartColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          if (hasChart)
            SizedBox(
              height: 226.h,
              child: LineChart(_buildChartData(chartSpots)),
            )
          else
            _buildEmptyState(chartSpots),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<FlSpot> chartSpots) {
    final bounds = _resolveYBounds(chartSpots);
    final bottomStep = math
        .max(1, ((chartSpots.length - 1) / 4).ceil())
        .toDouble();

    return LineChartData(
      minX: chartSpots.first.x,
      maxX: math.max(chartSpots.first.x + 1, chartSpots.last.x),
      minY: bounds.min,
      maxY: bounds.max,
      clipData: const FlClipData.all(),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => const Color(0xFF1B233A),
          tooltipRoundedRadius: 14.r,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              return LineTooltipItem(
                _formatValue(touchedSpot.y),
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.sp,
                ),
              );
            }).toList();
          },
        ),
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: chartColor.withOpacity(0.34),
                    strokeWidth: 1.5,
                    dashArray: [5, 5],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: chartColor,
                        ),
                  ),
                );
              }).toList();
            },
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: bounds.interval,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: AppColors.divider.withOpacity(0.72), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36.w,
            interval: bounds.interval,
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Text(
                  _formatAxisValue(value),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: const Color(0xFF8B93A6),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34.h,
            interval: bottomStep,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if ((value - index).abs() > 0.01 ||
                  index < 0 ||
                  index >= xLabels.length ||
                  xLabels[index].isEmpty) {
                return const SizedBox.shrink();
              }

              final isLatest = index == chartSpots.length - 1;
              return Padding(
                padding: EdgeInsets.only(top: 9.h),
                child: Text(
                  xLabels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isLatest
                        ? AppColors.primary
                        : const Color(0xFF8B93A6),
                    fontSize: 10.sp,
                    fontWeight: isLatest ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: chartSpots.last.y,
            color: chartColor.withOpacity(0.22),
            strokeWidth: 1.2,
            dashArray: [6, 6],
          ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: chartSpots,
          isCurved: true,
          curveSmoothness: 0.28,
          gradient: LinearGradient(
            colors: [chartColor.withOpacity(0.88), chartColor],
          ),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: chartSpots.length <= 8,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: index == chartSpots.length - 1 ? 5 : 3.6,
                  color: Colors.white,
                  strokeWidth: 2.4,
                  strokeColor: chartColor,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                chartColor.withOpacity(0.22),
                chartColor.withOpacity(0.03),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(List<FlSpot> chartSpots) {
    final latestValue = chartSpots.isEmpty ? null : chartSpots.last.y;

    return Container(
      height: 210.h,
      width: double.infinity,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      decoration: BoxDecoration(
        color: chartColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: chartColor.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.show_chart_rounded,
              color: chartColor,
              size: 28.sp,
            ),
          ),
          SizedBox(height: 12.h),
          'Chưa đủ dữ liệu lịch sử'.h2Custom(
            size: 15.sp,
            color: AppColors.textMain,
            fontweight: FontWeight.w700,
          ),
          if (latestValue != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: 'Hiện tại ${_formatValue(latestValue)}'.labelCustom(
                size: 12.sp,
                color: chartColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  ({double min, double max, double interval}) _resolveYBounds(
    List<FlSpot> chartSpots,
  ) {
    final values = chartSpots.map((spot) => spot.y).toList(growable: false);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);

    if (unit == '%') {
      return (min: 0.0, max: math.max(100.0, maxValue), interval: 25.0);
    }

    final range = maxValue - minValue;
    final padding = math.max(range * 0.22, 4.0);
    final minY = math.max(0.0, minValue - padding);
    final maxY = math.max(minY + 8.0, maxValue + padding);

    return (min: minY, max: maxY, interval: _niceInterval(maxY - minY));
  }

  double _niceInterval(double range) {
    if (range <= 8) {
      return 2;
    }
    if (range <= 16) {
      return 4;
    }
    if (range <= 32) {
      return 8;
    }
    return 12;
  }

  String _formatValue(double value) {
    final text = unit == '%'
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text$unit';
  }

  String _formatAxisValue(double value) {
    if (unit == '%') {
      return value.round().toString();
    }
    return value >= 10 ? value.round().toString() : value.toStringAsFixed(1);
  }
}
