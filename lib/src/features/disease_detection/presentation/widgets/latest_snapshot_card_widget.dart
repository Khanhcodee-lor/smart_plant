import 'package:app_iot/src/core/constants/app_build_text.dart';
import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:app_iot/src/core/services/firebase/firebase_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final latestSnapshotUrlProvider = FutureProvider.autoDispose
    .family<String, String>((ref, snapshotPath) async {
      return await ref
          .read(firebaseStorageServiceProvider)
          .resolveDownloadUrl(snapshotPath);
    });

class LatestSnapshotCardWidget extends ConsumerWidget {
  final String snapshotUrl;
  final String capturedAt;

  const LatestSnapshotCardWidget({
    super.key,
    required this.snapshotUrl,
    this.capturedAt = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedPath = snapshotUrl.trim();
    final snapshotAsync = normalizedPath.isEmpty
        ? const AsyncValue<String>.data('')
        : ref.watch(latestSnapshotUrlProvider(normalizedPath));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_camera_back_outlined,
              size: 18.sp,
              color: AppColors.accent,
            ),
            SizedBox(width: 8.w),
            "Ảnh chụp mới nhất".h1Custom(
              size: 16.sp,
              color: AppColors.textMain,
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          height: 220.h,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              snapshotAsync.when(
                data: (resolvedUrl) {
                  if (resolvedUrl.isEmpty) {
                    return _SnapshotPlaceholder(
                      icon: Icons.photo_outlined,
                      message: 'Chưa có ảnh chụp mới nhất',
                    );
                  }

                  return Image.network(
                    resolvedUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const _SnapshotPlaceholder(
                        icon: Icons.image_search_outlined,
                        message: 'Đang tải ảnh chụp...',
                        showLoader: true,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const _SnapshotPlaceholder(
                        icon: Icons.broken_image_outlined,
                        message: 'Không tải được ảnh chụp',
                      );
                    },
                  );
                },
                loading: () => const _SnapshotPlaceholder(
                  icon: Icons.image_search_outlined,
                  message: 'Đang tải ảnh chụp...',
                  showLoader: true,
                ),
                error: (_, _) => const _SnapshotPlaceholder(
                  icon: Icons.broken_image_outlined,
                  message: 'Không tải được ảnh chụp',
                ),
              ),
              if (capturedAt.trim().isNotEmpty)
                Positioned(
                  left: 12.w,
                  right: 12.w,
                  bottom: 12.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.48),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          color: Colors.white,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: capturedAt.bodyCustom(
                            size: 12.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SnapshotPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool showLoader;

  const _SnapshotPlaceholder({
    required this.icon,
    required this.message,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundGreen,
            AppColors.accentSecond.withOpacity(0.18),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLoader) ...[
                SizedBox(
                  width: 28.w,
                  height: 28.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(height: 12.h),
              ] else ...[
                Icon(icon, size: 34.sp, color: AppColors.disabledText),
                SizedBox(height: 10.h),
              ],
              message.bodyCustom(
                size: 14.sp,
                color: AppColors.disabledText,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
