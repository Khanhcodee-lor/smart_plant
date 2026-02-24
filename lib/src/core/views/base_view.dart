import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart'; //

abstract class BaseView extends ConsumerWidget {
  const BaseView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Tự động ẩn bàn phím khi chạm ra ngoài
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // 2. Tùy chỉnh màu Status Bar theo màn hình
        value: systemUiOverlayStyle(context),
        child: Scaffold(
          // Hỗ trợ mở rộng body ra sau AppBar hoặc không
          extendBodyBehindAppBar: extendBodyBehindAppBar(),
          //background
          backgroundColor: backgroundColor(context) ?? AppColors.background,
          appBar: buildAppBar(context, ref),
          drawer: buildDrawer(context, ref),
          floatingActionButton: buildFloatingActionButton(context, ref),
          bottomNavigationBar: buildBottomNavigationBar(context, ref),
          resizeToAvoidBottomInset: resizeToAvoidBottomInset(),
          // 3. Stack để đè Loading lên trên cùng
          body: Stack(
            children: [
              _buildBackground(context),
              _buildResponsiveBody(context, ref),
              if (isLoading(ref)) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIC RESPONSIVE & LAYOUT ---
  Widget _buildBackground(BuildContext context) {
    final decoration = bodyDecoration(context);
    if (decoration == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: decoration,
    );
  }

  Widget _buildResponsiveBody(BuildContext context, WidgetRef ref) {
    // Sử dụng SafeArea linh hoạt
    Widget content = buildBody(context, ref);

    if (useSafeArea()) {
      content = SafeArea(
        top: safeAreaTop(),
        bottom: safeAreaBottom(),
        child: content,
      );
    }

    // Căn giữa và giới hạn chiều rộng cho Tablet/Web
    return Center(
      child: Container(
        // Dùng .w của ScreenUtil hoặc giới hạn cứng nếu trên Web
        constraints: BoxConstraints(
          maxWidth: enableWebConstraints() ? 600.w : double.infinity,
        ),
        padding: padding(context),
        child: content,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: const CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  // --- ABSTRACT METHODS (Bắt buộc Override) ---

  Widget buildBody(BuildContext context, WidgetRef ref);

  Decoration? bodyDecoration(BuildContext context) => null;
  // --- OPTIONAL METHODS (Tùy chọn Override) ---

  PreferredSizeWidget? buildAppBar(BuildContext context, WidgetRef ref) => null;
  Widget? buildDrawer(BuildContext context, WidgetRef ref) => null;
  Widget? buildFloatingActionButton(BuildContext context, WidgetRef ref) =>
      null;
  Widget? buildBottomNavigationBar(BuildContext context, WidgetRef ref) => null;

  // --- CONFIGURATION (Cấu hình) ---

  /// Màu nền màn hình
  Color? backgroundColor(BuildContext context) => AppColors.background;

  /// Padding mặc định (Dùng .w, .h của ScreenUtil)
  EdgeInsetsGeometry padding(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h);

  /// Trạng thái Loading (Kết nối với Provider)
  bool isLoading(WidgetRef ref) => false;

  /// Cấu hình Status Bar (Màu chữ, màu nền pin/sóng)
  SystemUiOverlayStyle systemUiOverlayStyle(BuildContext context) {
    return SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent, // Trong suốt để thấy ảnh nền
      statusBarIconBrightness: Brightness.dark, // Icon màu tối
    );
  }

  bool resizeToAvoidBottomInset() => true;
  bool extendBodyBehindAppBar() => false;

  // SafeArea config
  bool useSafeArea() => true;
  bool safeAreaTop() => true;
  bool safeAreaBottom() => true;

  // Web/Tablet config
  bool enableWebConstraints() =>
      true; // Bật giới hạn chiều rộng trên màn hình lớn
}
