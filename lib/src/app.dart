import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'core/routers/router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'IoT Plant Doctor',
          debugShowCheckedModeBanner: false,
          routerConfig: goRouter,
          theme: _buildAppTheme(),
        );
      },
    );
  }

  /// ===============================
  /// BUILD APP THEME (SAFE VERSION)
  /// ===============================
  ThemeData _buildAppTheme() {
    // Base Material 3 theme
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        background: AppColors.background,
      ),
    );

    // ⚠️ RẤT QUAN TRỌNG:
    // KHÔNG dùng textTheme.apply(fontSizeFactor: ...)
    // vì ScreenUtil đã scale bằng .sp rồi
    final textTheme = GoogleFonts.beVietnamProTextTheme(base.textTheme)
        .copyWith(
          headlineLarge: GoogleFonts.beVietnamPro(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
          headlineMedium: GoogleFonts.beVietnamPro(
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
          bodyLarge: GoogleFonts.beVietnamPro(
            fontSize: 16.sp,
            color: AppColors.textMain,
          ),
          bodyMedium: GoogleFonts.beVietnamPro(
            fontSize: 14.sp,
            color: AppColors.textMain,
          ),
          labelLarge: GoogleFonts.beVietnamPro(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textMain,
          ),
        );

    return base.copyWith(
      textTheme: textTheme,

      // ===============================
      // APP BAR
      // ===============================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.beVietnamPro(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // ===============================
      // INPUT (TEXT FIELD)
      // ===============================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        hintStyle: GoogleFonts.beVietnamPro(
          fontSize: 14.sp,
          color: AppColors.textHint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      // ===============================
      // BUTTON
      // ===============================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
