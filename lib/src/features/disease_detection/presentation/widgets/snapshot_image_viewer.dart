import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showSnapshotImageViewer(
  BuildContext context, {
  required String imageUrl,
  String title = 'Ảnh bệnh',
  String subtitle = '',
}) {
  final normalizedUrl = imageUrl.trim();
  if (normalizedUrl.isEmpty) {
    return;
  }

  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Đóng',
    barrierColor: Colors.black,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: title.h2Custom(
                        size: 16.sp,
                        color: Colors.white,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      normalizedUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2.4,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: 'Không tải được ảnh'.bodyCustom(
                            size: 14.sp,
                            color: Colors.white70,
                            align: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (subtitle.trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 18.h),
                  child: subtitle.bodyCustom(
                    size: 12.sp,
                    color: Colors.white70,
                    align: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
