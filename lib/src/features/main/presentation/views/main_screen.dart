import 'package:app_iot/src/core/views/base_view.dart';
import 'package:app_iot/src/features/home/presentation/views/home_screen.dart';
import 'package:app_iot/src/features/main/presentation/widgets/custom_bottom_nav.dart';
import 'package:app_iot/src/features/profile/presentation/views/profile_screen.dart';
import 'package:app_iot/src/features/regime/presentation/views/regime_screen.dart';
import 'package:app_iot/src/features/support/presentation/views/support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bottomNavProvider = StateProvider<int>((ref) => 0);

class MainScreen extends BaseView {
  const MainScreen({super.key});

  @override
  // Tắt SafeArea để có thể thiết kế linh hoạt hơn
  bool useSafeArea() => false;

  @override
  EdgeInsetsGeometry padding(BuildContext context) => EdgeInsets.zero;

  @override
  Widget buildBody(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavProvider);

    // Danh sách các màn hình tương ứng với từng Tab
    final screens = [
      const HomeScreen(),
      const RegimeScreen(),
      const SupportScreen(),
      const ProfileScreen(),
    ];
    return Stack(
      children: [
        IndexedStack(index: currentIndex, children: screens),

        CustomBottomNav(),
      ],
    );
  }
}
