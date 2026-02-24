import 'package:app_iot/src/features/auth/presentation/controllers/views/login_screen.dart';
import 'package:app_iot/src/features/main/presentation/views/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

// Navigator key gốc
final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,

    /// ===============================
    /// AUTH REDIRECT LOGIC (CHUẨN)
    /// ===============================
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoginRoute = state.matchedLocation == '/login';

      // CHƯA đăng nhập → luôn về login
      if (user == null && !isLoginRoute) {
        return '/login';
      }

      // ĐÃ đăng nhập → không cho quay lại login
      if (user != null && isLoginRoute) {
        return '/';
      }

      // Các trường hợp hợp lệ khác
      return null;
    },

    /// ===============================
    /// ROUTES
    /// ===============================
    routes: [
      /// LOGIN
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      /// HOME
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MainScreen(),
        routes: [
          /// DETAIL
          GoRoute(
            path: 'detail/:id',
            name: 'plant_detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return Scaffold(
                appBar: AppBar(title: const Text('Chi tiết cây')),
                body: Center(
                  child: Text(
                    'Chi tiết ID: $id',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}


/*
Logic Redirect trong router.dart của bạn đang hoạt động tốt cho lần khởi chạy đầu tiên.
 Tuy nhiên, nó đang kiểm tra tĩnh qua FirebaseAuth.instance.currentUser.

Nghĩa là: Nếu user đang ở trang chủ '/', xong họ bấm nút Đăng xuất, GoRouter 
sẽ không tự động đá họ về trang /login được (vì nó không tự lắng nghe sự thay đổi của 
Firebase).

Để nó tự động 100%, sau này khi làm chức năng Đăng xuất, bạn nên truyền thêm thuộc 
tính refreshListenable vào GoRouter nhé. Tạm thời bây giờ đăng nhập được vào trong là quá ổn rồi! */