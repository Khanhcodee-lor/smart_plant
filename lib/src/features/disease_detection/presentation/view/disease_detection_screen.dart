import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/current_disease_card_widget.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/disease_history_list_widget.dart';
import 'package:app_iot/src/features/disease_detection/presentation/widgets/video_stream_widget.dart';
import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:app_iot/src/shared/widgets/app_refresh_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app_iot/src/features/chatbot/presentation/views/ai_chatbot_sheet.dart';

class DiseaseDetectionScreen extends BaseView {
  final String plantId;
  const DiseaseDetectionScreen({super.key, required this.plantId});

  @override
  bool extendBodyBehindAppBar() => true;

  @override
  Widget? buildFloatingActionButton(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      backgroundColor: AppColors.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
      elevation: 4,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const AiChatbotSheet(),
        );
      },
      child: Icon(Icons.auto_awesome, color: Colors.white, size: 24.sp),
    );
  }

  @override
  AppBar? buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textMain),
      titleTextStyle: const TextStyle(
        color: AppColors.textMain,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      centerTitle: true,
      title: ref
          .watch(plantControllerProvider)
          .when(
            data: (plants) {
              // Lấy đúng cây theo plantId
              final plantIndex = plants.indexWhere((p) => p.id == plantId);
              if (plantIndex == -1) {
                return const Text('Không tìm thấy dữ liệu cây');
              }
              final plant = plants[plantIndex];
              return Text(plant.name);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Lỗi tải dữ liệu: $error')),
          ),
    );
  }

  @override
  Decoration? bodyDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        transform: GradientRotation(0.3),
        tileMode: TileMode.clamp,
        stops: [0.0, 0.7],
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
  Widget buildBody(BuildContext context, WidgetRef ref) {
    final plantAsyncValue = ref.watch(plantControllerProvider);

    return SizedBox.expand(
      child: AppRefreshScrollView(
        onRefresh: () async {
          // Chỉ việc gọi logic refresh của màn hình này
          return await ref.refresh(plantControllerProvider.future);
        },
        child: plantAsyncValue.when(
          data: (plants) {
            // Lấy đúng cây theo plantId
            final plantIndex = plants.indexWhere((p) => p.id == plantId);
            if (plantIndex == -1) {
              return Center(
                child: Text('Không tìm thấy dữ liệu cây ($plantId)'),
              );
            }
            final plant = plants[plantIndex];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Video Stream Widget
                  VideoStreamWidget(videoUrl: plant.videoUrl),
                  SizedBox(height: 20.h),

                  // 3. Current Disease Card
                  CurrentDiseaseCardWidget(
                    latestDetection: plant.latestDetection,
                  ),
                  SizedBox(height: 20.h),

                  // 4. Lịch sử bệnh (History List)
                  "Lịch sử phát hiện".h1Custom(
                    size: 16.sp,
                    color: AppColors.textMain,
                  ),
                  SizedBox(height: 12.h),
                  DiseaseHistoryListWidget(history: plant.history),
                  SizedBox(height: 30.h),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Lỗi tải dữ liệu: $error')),
        ),
      ),
    );
  }
}
