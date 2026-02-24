import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/home/presentation/controllers/weather_controller.dart';
import 'package:app_iot/src/features/home/presentation/widgets/card_weather.dart';
import 'package:app_iot/src/features/home/presentation/widgets/my_plant.dart';
import 'package:app_iot/src/features/home/presentation/widgets/home_header.dart';
import 'package:app_iot/src/shared/widgets/app_refresh_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends BaseView {
  const HomeScreen({super.key});

  @override
  Color? backgroundColor(BuildContext context) => Colors.transparent;

  @override
  Decoration? bodyDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        transform: GradientRotation(0.3),
        tileMode: TileMode.clamp,
        stops: [0.0, 0.7],
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
          // Chỉ việc gọi logic refresh của màn hình này
          return await ref.refresh(weatherProvider.future);
        },
        child: Column(
          children: [
            HomeHeader(),
            SizedBox(height: 16.h),
            CardWeather(),
            SizedBox(height: 16.h),
            MyPlant(),
          ],
        ),
      ),
    );
  }
}
