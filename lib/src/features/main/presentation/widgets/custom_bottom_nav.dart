import 'package:app_iot/src/core/constants/app_assets.dart';
import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/main/presentation/views/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class CustomBottomNav extends ConsumerWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      left: 8.w,
      right: 8.w,
      bottom: 30.h,
      child: Row(
        children: [
          // 1. Cụm 4 nút điều hướng (Pill shape)
          Expanded(
            child: Container(
              height: 60.h, // Chiều cao an toàn không bị tràn viền
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(40.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.borderFocused.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Truyền 2 loại icon (Rỗng và Đặc) để làm hiệu ứng
                  _buildNavItem(
                    ref,
                    index: 0,
                    inactiveIcon: SvgPicture.asset(
                      AppAssets.homeIconLine,
                      width: 20.w,
                    ),
                    activeIcon: SvgPicture.asset(
                      AppAssets.homeIconFill,
                      width: 20.w,
                      colorFilter: const ColorFilter.mode(
                        AppColors.accent,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: "Trang chủ",
                  ),
                  _buildNavItem(
                    ref,
                    index: 1,
                    inactiveIcon: SvgPicture.asset(
                      AppAssets.remimeIconLine,
                      width: 20.w,
                    ),
                    activeIcon: SvgPicture.asset(
                      AppAssets.remimeIconFill,
                      width: 20.w,
                      colorFilter: const ColorFilter.mode(
                        AppColors.accent,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: "Chế độ",
                  ),
                  _buildNavItem(
                    ref,
                    index: 2,
                    inactiveIcon: SvgPicture.asset(
                      AppAssets.treeIconLine,
                      width: 20.w,
                    ),
                    activeIcon: SvgPicture.asset(
                      AppAssets.treeIconFill,
                      width: 20.w,
                      colorFilter: const ColorFilter.mode(
                        AppColors.accent,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: "Hỗ trợ",
                  ),
                  _buildNavItem(
                    ref,
                    index: 3,
                    inactiveIcon: SvgPicture.asset(
                      AppAssets.personIconLine,
                      width: 20.w,
                    ),
                    activeIcon: SvgPicture.asset(
                      AppAssets.personIconFill,
                      width: 20.w,
                      colorFilter: const ColorFilter.mode(
                        AppColors.accent,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: "Tôi",
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // 2. Nút AI hình tròn tách biệt
          Container(
            height: 64.h,
            width: 64.h,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.borderFocused.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                // TODO: Gọi hàm mở Chatbot AI ở đây
                print("Mở AI Chatbot");
              },
              borderRadius: BorderRadius.circular(35.r),
              splashColor: AppColors.accent.withOpacity(0.1),
              highlightColor: Colors.transparent,
              child: Center(
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.accent,
                  size: 28.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET CON: Nút bấm trong Nav Bar ---
  Widget _buildNavItem(
    WidgetRef ref, {
    required int index,
    required Widget inactiveIcon,
    required Widget activeIcon,
    required String label,
    bool hasNotification = false,
  }) {
    final currentIndex = ref.watch(bottomNavProvider);
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ref.read(bottomNavProvider.notifier).state = index;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(4),
          margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.borderFocused.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(100.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Giữ các thành phần ép sát nhau
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // --- HIỆU ỨNG POP VÀ ĐỔ MÀU ICON ---
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,

                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        key: ValueKey(isSelected),
                        child: isSelected ? activeIcon : inactiveIcon,
                      ),
                    ),
                  ),

                  // --- CHẤM ĐỎ THÔNG BÁO ---
                  if (hasNotification && !isSelected)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),

              // --- CHỈ HIỆN CHỮ KHI ĐƯỢC CHỌN ---
              if (isSelected) ...[
                SizedBox(height: 2.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  // Tuyệt chiêu replaceAll để chống rớt dòng chữ "Trang chủ"
                  child: label
                      .replaceAll(' ', '\u00A0')
                      .bodyCustom(
                        maxLines: 1,
                        size: 8.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
