import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:app_iot/src/features/regime/presentation/controllers/regime_realtime_controller.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/header_regime.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/pump_control_card.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/sensor_status.dart';
import 'package:app_iot/src/shared/widgets/app_refresh_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RegimeScreen extends BaseView {
  const RegimeScreen({super.key});

  @override
  Color? backgroundColor(BuildContext context) => Colors.transparent;

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
  Widget buildBody(BuildContext context, WidgetRef ref) {
    final plantId = _resolveRegimePlantId(ref.watch(plantControllerProvider));

    return SizedBox.expand(
      child: AppRefreshScrollView(
        onRefresh: () async {
          ref.invalidate(plantControllerProvider);
          ref.invalidate(regimeRealtimeDataProvider(plantId));

          await Future.wait([
            ref.read(plantControllerProvider.future),
            ref.read(regimeRealtimeDataProvider(plantId).future),
          ]);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeaderRegime(),
            SizedBox(height: 18.h),
            SensorStatus(plantId: plantId),
            SizedBox(height: 12.h),
            PumpControlCard(plantId: plantId),
          ],
        ),
      ),
    );
  }
}

String _resolveRegimePlantId(AsyncValue<List<Plant>> plantAsyncValue) {
  final plants = plantAsyncValue.asData?.value ?? const <Plant>[];
  if (plants.isEmpty) {
    return 'tomato_001';
  }
  return plants.first.id;
}
