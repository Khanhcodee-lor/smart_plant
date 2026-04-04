import 'package:app_iot/src/core/constants/app_assets.dart';
import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class MyPlant extends ConsumerWidget {
  const MyPlant({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsyncValue = ref.watch(plantControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HEADER: Tiêu đề
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            "Khu vườn của tôi".h1Custom(
              size: 18.sp,
              color: AppColors.textMain, // Tuỳ chỉnh màu theo theme của bạn
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // 2. DANH SÁCH CÂY TỪ FIREBASE
        plantAsyncValue.when(
          data: (plants) {
            if (plants.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: "Chưa có cây nào trong vườn.".bodyCustom(
                    size: 14.sp,
                    color: AppColors.disabledText,
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plants.length,
              separatorBuilder: (context, index) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final plant = plants[index];
                return _buildPlantCard(context, plant);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Lỗi tải dữ liệu: $error')),
        ),

        SizedBox(height: 10.h),
        Center(child: _buildAddPlantButton(context)),
      ],
    );
  }

  // --- Widget Loại Cây ---
  Widget _buildPlantCard(BuildContext context, Plant plant) {
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
              Container(
                width: 80.w,
                height: 80.h,
                // Dựa theo dữ liệu 'image': 'tomato' trong realtime db
                child: plant.imageUrl.toLowerCase().contains('tomato')
                    ? Image.asset(AppAssets.tomatoPlantImage)
                    : Image.asset(
                        AppAssets.tomatoPlantImage,
                      ), // Fallback default
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
                        plant.name.bodyCustom(
                          size: 12.sp,
                          color: AppColors.textMain,
                        ),
                        // Nút chuyển màn hình theo ID
                        InkWell(
                          onTap: () {
                            // Sửa đường dẫn match với router: path: 'detail/:id' bên trong '/'
                            context.push('/detail/${plant.id}');
                          },
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 12.sp,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    plant.status.bodyCustom(
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
  Widget _buildAddPlantButton(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/bluetooth-scan'),
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
        child: "Cài đặt Wifi thiết bị".bodyCustom(
          size: 12.sp,
          color: AppColors.disabledText,
        ),
      ),
    );
  }
}
