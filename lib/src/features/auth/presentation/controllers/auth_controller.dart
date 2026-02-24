import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/app_user.dart';
import '../../data/repositories/auth_repository_impl.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<AppUser?> build() {
    final repository = ref.read(authRepositoryProvider);
    // Trạng thái ban đầu
    return repository.getCurrentUser();
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();

    // Đọc repository thông qua provider
    final repository = ref.read(authRepositoryProvider);

    state = await AsyncValue.guard(() async {
      return await repository.signInWithGoogle();
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final repository = ref.read(authRepositoryProvider);
    await repository.signOut();
    state = const AsyncValue.data(null);
  }
}
