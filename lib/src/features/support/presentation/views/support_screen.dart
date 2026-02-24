import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/support/presentation/widgets/device_selector_section.dart';
import 'package:app_iot/src/features/support/presentation/widgets/explore_section.dart';
import 'package:app_iot/src/features/support/presentation/widgets/service_grid.dart';
import 'package:app_iot/src/features/support/presentation/widgets/support_search_bar.dart';
import 'package:app_iot/src/shared/widgets/app_refresh_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SupportScreen extends BaseView {
  const SupportScreen({super.key});

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
          AppColors.accentSecond.withOpacity(0.06),
          AppColors.backgroundGreen.withOpacity(0.5),
        ],
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    return SizedBox.expand(
      child: AppRefreshScrollView(
        onRefresh: () async {
          // Implement refresh logic if needed
          return await Future.delayed(const Duration(seconds: 1));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            "Hỗ trợ".h1Custom(size: 24.sp),
            SizedBox(height: 20.h),
            const SupportSearchBar(),
            SizedBox(height: 24.h),
            const DeviceSelectorSection(),
            SizedBox(height: 24.h),
            const ServiceGrid(),
            SizedBox(height: 24.h),
            const ExploreSection(),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}
