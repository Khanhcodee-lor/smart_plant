import 'package:app_iot/src/core/constants/app_assets.dart';
import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/constants/app_text_styles.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:app_iot/src/shared/animations/app_fade_in.dart';
import 'package:app_iot/src/shared/animations/app_scale_in.dart';
import 'package:app_iot/src/shared/animations/app_slide_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends BaseView {
  const LoginScreen({super.key});

  @override
  SystemUiOverlayStyle systemUiOverlayStyle(BuildContext context) {
    return SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent, // Nền trong suốt
      statusBarIconBrightness: Brightness.dark, // Icon pin/sóng màu đen
    );
  }

  @override
  // Tắt padding mặc định của BaseView để ảnh tràn viền 100%
  EdgeInsetsGeometry padding(BuildContext context) => EdgeInsets.zero;

  @override
  // Tắt SafeArea để ảnh nền tràn full màn hình
  bool useSafeArea() => false;

  @override
  // Màn hình này không có input nên không cần resize khi phím hiện
  bool resizeToAvoidBottomInset() => false;

  // --- NỘI DUNG CHÍNH ---
  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    ref.listen(authControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) {
            print("Đăng nhập thành công: ${user.name}");
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Chào mừng ${user.name}!')));
            context.go('/');
          }
        },
        error: (error, stackTrace) {
          // CÓ LỖI XẢY RA: Báo lỗi cho người dùng
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng nhập thất bại: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    });
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        // 1. PHẦN ẢNH LOTTIE Ở TRÊN
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          // Kéo dài ảnh lottie xuống 48% màn hình để phần khung trắng đè lên là vừa đẹp
          height: screenHeight * 0.48,
          child: AppFadeIn(
            duration: const Duration(milliseconds: 800),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors
                    .background, // Cân nhắc đổi thành màu nền thật của ảnh nếu có
              ),
              clipBehavior: Clip.antiAlias,
              child: Lottie.asset(AppAssets.lottieLogin, fit: BoxFit.cover),
            ),
          ),
        ),

        // 2. PHẦN KHUNG TRẮNG ĐĂNG NHẬP Ở DƯỚI
        Positioned(
          top: screenHeight * 0.44,
          // Bắt đầu vẽ khung trắng từ mốc 44% (đè lên ảnh 4%)
          left: 0,
          right: 0,
          bottom: 0, // KÉO SÁT CHẠM ĐÁY MÀN HÌNH -> Fix triệt để khoảng trắng!
          child: AppSlideIn(
            duration: const Duration(milliseconds: 1000),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.background,
                    AppColors.accent.withOpacity(0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.3, 1.0],
                ),

                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.r),
                  topRight: Radius.circular(40.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: 35.h),

                  // --- LOGO VÀ TEXT ---
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppScaleIn(
                        delay: const Duration(milliseconds: 200),
                        startScale: 0.5,
                        child: Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              AppAssets.logoApp,
                              width: 60.r,
                              height: 60.r,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Plant",
                              style: AppTextStyles.h1Bold.copyWith(
                                fontSize: 20.sp,
                              ),
                            ),
                            TextSpan(
                              text: "Smart",
                              style: AppTextStyles.h1Light.copyWith(
                                fontSize: 20.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      "Theo dõi và chăm sóc cây trồng thông minh".bodyCustom(
                        size: 13.sp,
                        color: AppColors.textMain.withOpacity(0.6),
                      ),
                    ],
                  ),

                  SizedBox(height: 38.h),

                  // --- NÚT BẤM ---
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.w),
                    child: Column(
                      children: [
                        AppSlideIn(
                          delay: const Duration(milliseconds: 550),
                          offset: const Offset(0, 30),
                          child: _buildTranslucentButton(
                            onTap: () {},
                            backgroundColor: AppColors.accent,
                            textColor: AppColors.background,
                            text: "Login",
                          ),
                        ),
                        SizedBox(height: 18.h),
                        AppSlideIn(
                          delay: const Duration(milliseconds: 650),
                          offset: const Offset(0, 30),
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                ) // Hiện vòng quay nếu đang load
                              : _buildGoogleButton(
                                  onTap: () {
                                    ref
                                        .read(authControllerProvider.notifier)
                                        .loginWithGoogle();
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(), // Đẩy nội dung lên, khoảng trống rơi xuống đáy an toàn
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Widget xây dựng nút bấm dạng trong suốt (Login/Signup)
  Widget _buildTranslucentButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 52.h, // Chiều cao cố định theo thiết kế
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30.r), // Bo tròn kiểu pill-shape
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30.r),
          child: Center(child: text.bodyCustom(color: textColor)),
        ),
      ),
    );
  }

  /// Widget xây dựng nút đăng nhập Google
  Widget _buildGoogleButton({required VoidCallback onTap}) {
    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Google
                Image.asset(
                  AppAssets.icGoogle, // Đảm bảo có ảnh này
                  height: 22.h,
                  width: 22.h,
                ),
                16.horizontalSpace,
                // Text
                "Tiếp tục với Google".bodyCustom(size: 12.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
