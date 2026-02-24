import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:app_iot/src/core/constants/app_assets.dart';
import 'package:app_iot/src/features/home/presentation/controllers/weather_controller.dart';

// Đổi tên thành CardWeather để bạn không phải sửa code bên HomeScreen
class CardWeather extends ConsumerWidget {
  const CardWeather({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    // Căn giữa hoặc căn trái phải tùy bạn đặt align bên ngoài
    return Align(
      alignment:
          Alignment.centerLeft, // Đổi thành center nếu muốn căn giữa màn hình
      child: weatherAsync.when(
        data: (weather) => _buildWeatherPill(weather),
        loading: () => _buildLoadingPill(),
        error: (error, stackTrace) => _buildErrorPill(ref),
      ),
    );
  }

  // --- UI LÚC CÓ DỮ LIỆU ---
  Widget _buildWeatherPill(weather) {
    return Container(
      // Padding ngang dọc tạo hình viên thuốc
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        // Màu nền xám nhạt/trắng mờ như trong ảnh của bạn
        color: AppColors.background,
        borderRadius: BorderRadius.circular(50.r), // Bo cong hoàn toàn
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon thời tiết
          SvgPicture.asset(
            _getWeatherAsset(weather.icon),
            width: 16.w,
            height: 16.w,
          ),
          SizedBox(width: 8.w),

          // Chữ: 22°C Hà Nội
          '${weather.temperature.round()}°C ${weather.city}'.bodyCustom(
            size: 8,
            color: AppColors.textMain,
          ),
        ],
      ),
    );
  }

  // --- UI LÚC ĐANG TẢI ---
  Widget _buildLoadingPill() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB).withOpacity(0.9),
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8.w),
          Text(
            'Đang tải...',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- UI LÚC LỖI ---
  Widget _buildErrorPill(WidgetRef ref) {
    return GestureDetector(
      onTap: () =>
          ref.invalidate(weatherProvider), // Bấm vào viên thuốc để thử lại
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(50.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 18.sp, color: Colors.red),
            SizedBox(width: 4.w),
            Text(
              'Thử lại',
              style: TextStyle(fontSize: 14.sp, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

// Hàm map mã icon của OpenWeatherMap (Giữ nguyên của bạn)
String _getWeatherAsset(String iconCode) {
  switch (iconCode) {
    case '01d':
      return AppAssets.sunnyIcon;
    case '01n':
      return AppAssets.partlyCloudyIcon;
    case '02d':
    case '03d':
    case '04d':
      return AppAssets.partlyCloudyIcon;
    case '02n':
    case '03n':
    case '04n':
      return AppAssets.partlyCloudyIcon;
    case '09d':
    case '09n':
    case '10d':
    case '10n':
      return AppAssets.rainIcon;
    case '11d':
    case '11n':
      return AppAssets.thunderstomIcon;
    case '13d':
    case '13n':
      return AppAssets.sunnyIcon;
    case '50d':
    case '50n':
      return AppAssets.sunnyIcon;
    default:
      return AppAssets.sunnyIcon;
  }
}
