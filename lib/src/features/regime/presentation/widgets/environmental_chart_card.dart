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
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      height: 250.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title.h2Custom(size: 16.sp),
          SizedBox(height: 20.h),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => const Color(0xFF1B233A),
                    tooltipRoundedRadius: 16.r,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        return LineTooltipItem(
                          '${touchedSpot.y.toStringAsFixed(1)}$unit',
                          TextStyle(
                            color: chartColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
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
                              color: Colors.white,
                              strokeWidth: 1.5,
                              dashArray: [4, 4],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                    radius: 6,
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
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        // Only draw a label if we have a string for this index
                        if (index < 0 ||
                            index >= xLabels.length ||
                            xLabels[index].isEmpty) {
                          return const SizedBox.shrink();
                        }

                        String text = xLabels[index];
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: text.labelCustom(
                            size: 11.sp,
                            color: index == spots.length - 1
                                ? AppColors.primary
                                : const Color(0xFF8B93A6),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: spots.isNotEmpty ? spots.last.x : 6,
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [chartColor, chartColor.withOpacity(0.8)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          chartColor.withOpacity(0.35),
                          chartColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
