import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/constants/app_build_text.dart';

class GardenOverlayMenu {
  OverlayEntry? _entry;

  void show({
    required BuildContext context,
    required Offset position,
    required String currentGarden,
    VoidCallback? onAdd,
  }) {
    final overlay = Overlay.of(context);

    // đảm bảo không bị chồng overlay
    hide();

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          /// Tap ngoài để đóng
          GestureDetector(
            onTap: hide,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),

          Positioned(
            left: position.dx - 100.w, // GIỮ NGUYÊN
            top: position.dy + 12, // GIỮ NGUYÊN
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 220.w, // GIỮ NGUYÊN
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black.withOpacity(0.15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.check, color: AppColors.primary),
                      title: currentGarden.h1Custom(size: 12.sp),
                      subtitle: "Hiện tại".bodyCustom(
                        size: 10.sp,
                        color: AppColors.disabledText,
                      ),
                    ),

                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(Icons.add_circle),
                      title: "Thêm vườn của bạn".bodyCustom(size: 10.sp),
                      onTap: () {
                        hide();
                        onAdd?.call();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}
