import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/environmental_chart_card.dart';
import 'package:app_iot/src/shared/animations/animated_globe.dart';

import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:app_iot/src/shared/widgets/app_refresh_scroll_view.dart';

class SoilMoistureDetailScreen extends BaseView {
  final String plantId;
  const SoilMoistureDetailScreen({super.key, required this.plantId});

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
      title: "Độ ẩm đất".h1Custom(size: 18.sp, color: AppColors.textMain),
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

            final currentMoisture = plant.soilMoisture;
            final sensorHistory = plant.sensorHistory;
            final List<FlSpot> chartSpots = [];
            final List<String> xLabels = [];

            for (int i = 0; i < sensorHistory.length; i++) {
              chartSpots.add(
                FlSpot(i.toDouble(), sensorHistory[i].soilMoisture),
              );
              final timeStr = sensorHistory[i].time;
              xLabels.add(
                timeStr.length >= 16 ? timeStr.substring(11, 16) : timeStr,
              );
            }

            // Append current realtime point
            chartSpots.add(
              FlSpot(sensorHistory.length.toDouble(), currentMoisture),
            );
            xLabels.add('NOW');

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                children: [
                  // Animated Circular Soil Moisture Layout
                  AnimatedGlobe(
                    val: currentMoisture.toStringAsFixed(1),
                    unit: "%",
                    subtitle: "Độ ẩm đất",
                    baseColor: const Color(0xFFE8F5E9),
                    shadowColor: const Color(0xFFC8E6C9),
                    textColor: const Color(0xFF2E7D32),
                  ),
                  SizedBox(height: 40.h),
                  EnvironmentalChartCard(
                    title: "Biểu đồ độ ẩm đất",
                    chartColor: const Color(0xFF2E7D32),
                    spots: chartSpots,
                    xLabels: xLabels,
                    unit: "%",
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
