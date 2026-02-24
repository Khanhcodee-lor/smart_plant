import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AppRefreshScrollView extends StatelessWidget {
  /// Widget con (nội dung) bên trong
  final Widget child;

  /// Hàm được gọi khi người dùng vuốt xuống để refresh
  final Future<void> Function() onRefresh;

  /// (Tuỳ chọn) Căn lề cho nội dung cuộn
  final EdgeInsetsGeometry? padding;

  const AppRefreshScrollView({
    super.key,
    required this.child,
    required this.onRefresh,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      // Bạn có thể đổi màu mặc định cho toàn bộ app ở đây
      color: AppColors.background,
      backgroundColor: AppColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        // Đảm bảo luôn cuộn được kể cả khi nội dung ngắn
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: child,
      ),
    );
  }
}
