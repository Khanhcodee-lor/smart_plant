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
              return _buildEmptyGardenDiseaseEntry(context);
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
          loading: () => Column(
            children: [
              const Center(child: CircularProgressIndicator()),
              SizedBox(height: 12.h),
              _buildEmptyGardenDiseaseEntry(context),
            ],
          ),
          error: (error, stackTrace) => Column(
            children: [
              _buildEmptyGardenDiseaseEntry(context),
              SizedBox(height: 8.h),
              Text(
                'Không tải được danh sách cây: $error',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.disabledText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        SizedBox(height: 10.h),
        Center(child: _buildAddPlantButton(context)),
      ],
    );
  }

  Widget _buildEmptyGardenDiseaseEntry(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                padding: EdgeInsets.all(5.r),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGreen,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Image.asset(AppAssets.tomatoPlantImage),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    'Cà chua'.bodyCustom(
                      size: 15.sp,
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: 3.h),
                    'Xem kết quả sâu bệnh và lịch sử chụp'.bodyCustom(
                      size: 12.sp,
                      color: AppColors.disabledText,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/detail/tomato_001'),
              icon: const Icon(Icons.health_and_safety_outlined),
              label: const Text('Xem sâu bệnh'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 11.h),
              ),
            ),
          ),
        ],
      ),
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 80.w,
                height: 80.h,
                child: Image.asset(AppAssets.tomatoPlantImage),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    plant.name.bodyCustom(
                      size: 12.sp,
                      color: AppColors.textMain,
                    ),
                    SizedBox(height: 4.h),
                    plant.status.bodyCustom(
                      size: 12.sp,
                      color: AppColors.disabledText,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/detail/${plant.id}'),
              icon: const Icon(Icons.health_and_safety_outlined),
              label: const Text('Xem sâu bệnh'),
            ),
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
        child: 'Cài đặt Wifi thiết bị'.bodyCustom(
          size: 12.sp,
          color: AppColors.disabledText,
        ),
      ),
    );
  }
}
