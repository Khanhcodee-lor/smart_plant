import 'package:app_iot/src/core/constants/app_assets.dart';
import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyPlant extends StatelessWidget {
  const MyPlant({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HEADER: Tiêu đề và nút Menu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            "Khu vườn của tôi".h1Custom(
              size: 18.sp,
              color: AppColors.textMain, // Tuỳ chỉnh màu theo theme của bạn
            ),
            // Nút menu tròn
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu, size: 18.sp, color: AppColors.textMain),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        _buildPlantCard(),

        SizedBox(height: 10.h),
        Center(child: _buildAddPlantButton()),
      ],
    );
  }

  // --- Widget Loại Cây ---
  Widget _buildPlantCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // Bóng mờ rất nhẹ
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Phần trên: Ảnh + Tên + Trạng thái
          Row(
            children: [
              // Ảnh tủ lạnh (Bạn thay bằng Image.asset nếu có ảnh thật nhé)
              Container(
                width: 80.w,
                height: 80.h,

                child: Image.asset(AppAssets.tomatoPlantImage),
              ),
              SizedBox(width: 16.w),

              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        "Cà chua".bodyCustom(
                          size: 12.sp,
                          color: AppColors.textMain,
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12.sp,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    "Hãy đến thăm khu vườn của bạn".bodyCustom(
                      size: 12.sp,
                      color: AppColors.disabledText, // Màu xám cho trạng thái
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget Nút Thêm Thiết Bị ---
  Widget _buildAddPlantButton() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(30.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: "Thêm loại cây".bodyCustom(
          size: 12.sp,
          color: AppColors.disabledText,
        ),
      ),
    );
  }
}
