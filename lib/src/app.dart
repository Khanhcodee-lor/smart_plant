import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_colors.dart';
import 'core/routers/router.dart';
import 'core/services/firebase/firebase_messaging_service.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  OverlayEntry? _foregroundNotificationEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = ref.read(routerProvider);
      unawaited(
        ref
            .read(firebaseMessagingServiceProvider)
            .init(
              onNotificationOpened: (message) =>
                  _openNotification(router, message),
              onForegroundMessage: (message) =>
                  _showForegroundNotification(router, message),
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(firebaseMessagingServiceProvider);
    final goRouter = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'MyPlant',
          debugShowCheckedModeBanner: false,
          routerConfig: goRouter,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          theme: _buildAppTheme(),
        );
      },
    );
  }

  void _openNotification(GoRouter router, RemoteMessage message) {
    final plantId = (message.data['plant_id'] ?? message.data['plantId'])
        ?.toString()
        .trim();
    if (plantId != null && plantId.isNotEmpty) {
      router.goNamed('plant_detail', pathParameters: {'id': plantId});
    } else {
      router.go('/notifications');
    }
  }

  void _showForegroundNotification(GoRouter router, RemoteMessage message) {
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'Thông báo cây trồng';
    final body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        'Có kết quả nhận diện mới.';

    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('$title\n$body')),
      );
      return;
    }

    _removeForegroundNotification();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ForegroundNotificationBanner(
        title: title,
        body: body,
        onTap: () => _openNotification(router, message),
        onDismiss: () {
          if (!identical(_foregroundNotificationEntry, entry)) return;
          _foregroundNotificationEntry = null;
          entry.remove();
          entry.dispose();
        },
      ),
    );
    _foregroundNotificationEntry = entry;
    overlay.insert(entry);
  }

  void _removeForegroundNotification() {
    final entry = _foregroundNotificationEntry;
    _foregroundNotificationEntry = null;
    if (entry != null) {
      entry.remove();
      entry.dispose();
    }
  }

  @override
  void dispose() {
    _removeForegroundNotification();
    super.dispose();
  }

  /// ===============================
  /// BUILD APP THEME (SAFE VERSION)
  /// ===============================
  ThemeData _buildAppTheme() {
    // Base Material 3 theme
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        background: AppColors.background,
      ),
    );

    // ⚠️ RẤT QUAN TRỌNG:
    // KHÔNG dùng textTheme.apply(fontSizeFactor: ...)
    // vì ScreenUtil đã scale bằng .sp rồi
    final textTheme = GoogleFonts.beVietnamProTextTheme(base.textTheme)
        .copyWith(
          headlineLarge: GoogleFonts.beVietnamPro(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
          headlineMedium: GoogleFonts.beVietnamPro(
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
          bodyLarge: GoogleFonts.beVietnamPro(
            fontSize: 16.sp,
            color: AppColors.textMain,
          ),
          bodyMedium: GoogleFonts.beVietnamPro(
            fontSize: 14.sp,
            color: AppColors.textMain,
          ),
          labelLarge: GoogleFonts.beVietnamPro(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textMain,
          ),
        );

    return base.copyWith(
      textTheme: textTheme,

      // ===============================
      // APP BAR
      // ===============================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.beVietnamPro(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // ===============================
      // INPUT (TEXT FIELD)
      // ===============================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        hintStyle: GoogleFonts.beVietnamPro(
          fontSize: 14.sp,
          color: AppColors.textHint,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),

      // ===============================
      // BUTTON
      // ===============================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

class _ForegroundNotificationBanner extends StatefulWidget {
  const _ForegroundNotificationBanner({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  State<_ForegroundNotificationBanner> createState() =>
      _ForegroundNotificationBannerState();
}

class _ForegroundNotificationBannerState
    extends State<_ForegroundNotificationBanner> {
  bool _visible = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
      _dismissTimer = Timer(const Duration(seconds: 6), _dismiss);
    });
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    if (!mounted) return;
    setState(() => _visible = false);
    _dismissTimer = Timer(const Duration(milliseconds: 240), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20.r);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
          child: AnimatedSlide(
            offset: _visible ? Offset.zero : const Offset(0, -0.18),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: Material(
                color: Colors.white,
                elevation: 12,
                shadowColor: AppColors.primary.withOpacity(0.2),
                borderRadius: borderRadius,
                child: InkWell(
                  onTap: () {
                    widget.onTap();
                    _dismiss();
                  },
                  borderRadius: borderRadius,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.14),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 3.h,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.accentSecond,
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 13.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42.w,
                                  height: 42.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Icon(
                                    Icons.notifications_active_rounded,
                                    color: AppColors.primary,
                                    size: 23.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'THÔNG BÁO MỚI',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.7,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 28.w,
                                            height: 28.w,
                                            child: IconButton(
                                              onPressed: _dismiss,
                                              padding: EdgeInsets.zero,
                                              tooltip: 'Đóng thông báo',
                                              icon: Icon(
                                                Icons.close_rounded,
                                                color: AppColors.disabledText,
                                                size: 18.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        widget.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.textMain,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 3.h),
                                      Text(
                                        widget.body,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.sp,
                                          height: 1.35,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Xem chi tiết',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 3.w),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: AppColors.primary,
                                            size: 15.sp,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
