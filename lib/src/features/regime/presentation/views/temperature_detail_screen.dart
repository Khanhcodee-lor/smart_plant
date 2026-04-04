import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/environmental_chart_card.dart';
import 'package:app_iot/src/shared/animations/animated_globe.dart';
import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:app_iot/src/shared/widgets/app_refresh_scroll_view.dart';

class TemperatureDetailScreen extends BaseView {
  final String plantId;
  const TemperatureDetailScreen({super.key, required this.plantId});

  @override
  Color? backgroundColor(BuildContext context) => Colors.white;

  @override
  bool extendBodyBehindAppBar() => true;

  @override
  Decoration? bodyDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        transform: const GradientRotation(0.3),
        tileMode: TileMode.clamp,
        stops: const [0.0, 0.7],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.accentSecond.withOpacity(0.09),
          AppColors.backgroundGreen.withOpacity(0.8),
        ],
      ),
    );
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.textMain),
      elevation: 0,
      title: "Nhiệt độ".h1Custom(size: 18.sp, color: AppColors.textMain),
      centerTitle: true,
    );
  }

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    final plantAsyncValue = ref.watch(plantControllerProvider);

    return SizedBox.expand(
      child: AppRefreshScrollView(
        onRefresh: () async {
          return await ref.refresh(plantControllerProvider.future);
        },
        child: plantAsyncValue.when(
          data: (plants) {
            final plantIndex = plants.indexWhere((p) => p.id == plantId);
            if (plantIndex == -1) {
              return Center(
                child: Text('Không tìm thấy dữ liệu cây ($plantId)'),
              );
            }
            final plant = plants[plantIndex];

            final currentTemp = plant.temperature;
            final sensorHistory = plant.sensorHistory;
            final List<FlSpot> chartSpots = [];
            final List<String> xLabels = [];

            for (int i = 0; i < sensorHistory.length; i++) {
              chartSpots.add(
                FlSpot(i.toDouble(), sensorHistory[i].temperature),
              );
              // Extract HH:mm from time string if possible
              final timeStr = sensorHistory[i].time;
              xLabels.add(
                timeStr.length >= 16 ? timeStr.substring(11, 16) : timeStr,
              );
            }

            // Append current realtime point
            chartSpots.add(
              FlSpot(sensorHistory.length.toDouble(), currentTemp),
            );
            xLabels.add('NOW');

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                children: [
                  // Animated Circular Temperature Layout
                  AnimatedGlobe(
                    val: currentTemp.toStringAsFixed(1),
                    unit: "°",
                    subtitle: "Nhiệt độ",
                    baseColor: const Color(0xFFFDECD8),
                    shadowColor: const Color(0xFFFCE1C6),
                    textColor: const Color(0xFF1B233A),
                  ),
                  SizedBox(height: 40.h),
                  EnvironmentalChartCard(
                    title: "Biểu đồ nhiệt độ",
                    chartColor: const Color(0xFFFF7043),
                    spots: chartSpots,
                    xLabels: xLabels,
                    unit: "°C",
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Lỗi tải dữ liệu: $error')),
        ),
      ),
    );
  }
}
