import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/features/regime/presentation/widgets/garden_overlay_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HeaderRegime extends StatelessWidget {
  const HeaderRegime({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = GardenOverlayMenu();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            "Khu vườn:".h1Custom(size: 18.sp, color: AppColors.textMain),
            SizedBox(width: 4.w),
            "Cà chua".h1Custom(size: 18.sp, color: AppColors.textMain),
            GestureDetector(
              onTapDown: (d) {
                menu.show(
                  context: context,
                  position: d.globalPosition,
                  currentGarden: "Cà chua",
                  onAdd: () {
                    debugPrint("Thêm vườn");
                  },
                );
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
