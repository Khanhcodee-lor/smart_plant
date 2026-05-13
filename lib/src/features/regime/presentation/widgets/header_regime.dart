import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/garden_overlay_menu.dart';
import 'package:app_iot/src/features/home/presentation/controllers/plant_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HeaderRegime extends ConsumerWidget {
  const HeaderRegime({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = GardenOverlayMenu();
    final plantAsyncValue = ref.watch(plantControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            "Khu vườn:".h1Custom(size: 18.sp, color: AppColors.textMain),
            SizedBox(width: 4.w),
            plantAsyncValue.when(
              data: (plants) {
                if (plants.isEmpty) return const SizedBox.shrink();
                return plants.first.name.h1Custom(
                  size: 18.sp,
                  color: AppColors.textMain,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            GestureDetector(
              onTapDown: (d) {
                plantAsyncValue.whenData((plants) {
                  if (plants.isEmpty) return;
                  menu.show(
                    context: context,
                    position: d.globalPosition,
                    currentGarden: plants.first.name,
                    onAdd: () {
                      debugPrint("Thêm vườn");
                    },
                  );
                });
              },
              child: Icon(Icons.arrow_drop_down),
            ),
            Spacer(),
            IconButton(
              icon: Icon(
                Icons.pending_actions,
                size: 26.sp,
                color: AppColors.accent,
              ),
              onPressed: () {},
            ),
          ],
        ),
        SizedBox(height: 10.h),
      ],
    );
  }
}
