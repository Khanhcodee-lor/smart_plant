import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:app_iot/src/features/regime/presentation/controllers/regime_realtime_controller.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/environmental_metric_detail.dart';
import 'package:app_iot/src/shared/widgets/app_refresh_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final realtimeAsyncValue = ref.watch(regimeRealtimeDataProvider(plantId));

    return SizedBox.expand(
      child: AppRefreshScrollView(
        padding: EdgeInsets.fromLTRB(0, 68.h, 0, 24.h),
        onRefresh: () async {
          ref.invalidate(plantControllerProvider);
          ref.invalidate(regimeRealtimeDataProvider(plantId));

          await Future.wait([
            ref.read(plantControllerProvider.future),
            ref
                .read(regimeRealtimeDataProvider(plantId).future)
                .then<void>((_) {})
                .catchError((_) {}),
          ]);
        },
        child: plantAsyncValue.when(
          data: (plants) {
            final plantIndex = plants.indexWhere((p) => p.id == plantId);
            if (plantIndex == -1) {
              return SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.62,
                child: Center(
                  child: Text('Không tìm thấy dữ liệu cây ($plantId)'),
                ),
              );
            }
            final plant = plants[plantIndex];

            final currentMoisture =
                realtimeAsyncValue.asData?.value.soilMoisture ??
                plant.soilMoisture;
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

            return EnvironmentalMetricDetail(
              metricName: 'Độ ẩm đất',
              chartTitle: 'Biểu đồ độ ẩm đất',
              currentValue: currentMoisture,
              heroUnit: '%',
              chartUnit: '%',
              fractionDigits: 0,
              icon: Icons.eco_rounded,
              accentColor: const Color(0xFF2E7D32),
              baseColor: const Color(0xFFE9F7EC),
              shadowColor: const Color(0xFFC9EFD0),
              textColor: const Color(0xFF12662D),
              idealMin: 35,
              idealMax: 70,
              spots: chartSpots,
              xLabels: xLabels,
            );
          },
          loading: () => SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.62,
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.62,
            child: Center(child: Text('Lỗi tải dữ liệu: $error')),
          ),
        ),
      ),
    );
  }
}
