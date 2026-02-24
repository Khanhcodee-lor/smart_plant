import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/home/presentation/controllers/weather_controller.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/automatic_regime_card.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/header_regime.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/regime_toggle_button.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/schedule_regime_list.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/sensor_status.dart';
import 'package:app_iot/src/shared/widgets/app_refresh_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final regimeModeProvider = StateProvider<bool>(
  (ref) => true,
); // true = Auto, false = Schedule

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
    final isAuto = ref.watch(regimeModeProvider);

    return SizedBox.expand(
      child: AppRefreshScrollView(
        onRefresh: () async {
          return await ref.refresh(weatherProvider.future);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeaderRegime(),
            SizedBox(height: 6.h),
            RegimeToggleButton(
              isAuto: isAuto,
              onToggle: (val) =>
                  ref.read(regimeModeProvider.notifier).state = val,
            ),
            SizedBox(height: 10.h),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isAuto
                  ? const AutomaticRegimeCard()
                  : const ScheduleRegimeList(),
            ),
            SizedBox(height: 18.h),
            SensorStatus(),
          ],
        ),
      ),
    );
  }
}
