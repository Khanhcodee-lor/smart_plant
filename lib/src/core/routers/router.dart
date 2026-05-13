import 'dart:async';

import 'package:app_iot/src/features/auth/presentation/controllers/views/login_screen.dart';
import 'package:app_iot/src/features/bluetooth/presentation/views/provisioning_screen.dart';
import 'package:app_iot/src/features/disease_detection/presentation/view/disease_detection_screen.dart';
import 'package:app_iot/src/features/main/presentation/views/main_screen.dart';
import 'package:app_iot/src/features/regime/presentation/views/humidity_detail_screen.dart';
import 'package:app_iot/src/features/regime/presentation/views/soil_moisture_detail_screen.dart';
import 'package:app_iot/src/features/regime/presentation/views/temperature_detail_screen.dart';
import 'package:app_iot/src/core/services/firebase/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

// Navigator key gốc
final _rootNavigatorKey = GlobalKey<NavigatorState>();

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Stream<User?> authStateChanges) {
    _subscription = authStateChanges.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

@riverpod
GoRouter router(Ref ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  final authStateListenable = _AuthStateListenable(
    authService.authStateChanges,
  );
  ref.onDispose(authStateListenable.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: authStateListenable,

    /// ===============================
    /// AUTH REDIRECT LOGIC (CHUẨN)
    /// ===============================
    redirect: (context, state) {
      final user = authService.currentUser;
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
              return DiseaseDetectionScreen(plantId: id);
            },
          ),

          /// TEMPERATURE DETAIL
          GoRoute(
            path: 'temperature/:id',
            name: 'temperature_detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TemperatureDetailScreen(plantId: id);
            },
          ),

          /// HUMIDITY DETAIL
          GoRoute(
            path: 'humidity/:id',
            name: 'humidity_detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return HumidityDetailScreen(plantId: id);
            },
          ),

          /// SOIL MOISTURE DETAIL
          GoRoute(
            path: 'soil-moisture/:id',
            name: 'soil_moisture_detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return SoilMoistureDetailScreen(plantId: id);
            },
          ),
        ],
      ),

      GoRoute(
        path: '/bluetooth-scan',
        name: 'bluetooth_scan',
        builder: (context, state) => const ProvisioningScreen(),
      ),
    ],
  );
}
