import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/profile/presentation/widgets/profile_header.dart';
import 'package:app_iot/src/features/profile/presentation/widgets/profile_menu_list.dart';
import 'package:app_iot/src/features/profile/presentation/widgets/third_party_services.dart';
import 'package:app_iot/src/shared/widgets/app_refresh_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileScreen extends BaseView {
  const ProfileScreen({super.key});

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
          return await Future.delayed(const Duration(seconds: 1));
        },
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 28.sp,
                      color: AppColors.textMain,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "6",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const ProfileHeader(),
            SizedBox(height: 24.h),
            const ThirdPartyServices(),
            SizedBox(height: 24.h),
            const ProfileMenuList(),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}
