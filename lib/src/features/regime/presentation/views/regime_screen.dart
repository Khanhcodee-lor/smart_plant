import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/home/presentation/controllers/weather_controller.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/header_regime.dart';
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
    return SizedBox.expand(
      child: AppRefreshScrollView(
        onRefresh: () async {
          return await ref.refresh(weatherProvider.future);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeaderRegime(),
            SizedBox(height: 18.h),
            SensorStatus(),
          ],
        ),
      ),
    );
  }
}
