import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BluetoothScanScreen extends BaseView {
  const BluetoothScanScreen({super.key});

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
  PreferredSizeWidget? appBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: "Quet Bluetooth".h1Custom(size: 18.sp),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bluetooth_searching_rounded,
              size: 56.sp,
              color: AppColors.accent,
            ),
            SizedBox(height: 16.h),
            "Quet thiet bi Bluetooth".h1Custom(size: 16.sp),
            SizedBox(height: 8.h),
            "Man hinh scan Bluetooth da san sang. Ban co the tiep tuc them logic quet thiet bi tai day."
                .bodyCustom(
                  size: 13.sp,
                  color: AppColors.textSecondary,
                  align: TextAlign.center,
                ),
          ],
        ),
      ),
    );
  }
}
