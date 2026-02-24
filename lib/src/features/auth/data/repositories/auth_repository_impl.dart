import 'package:app_iot/src/core/services/firebase/firebase_auth_service.dart';
import 'package:app_iot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:app_iot/src/features/auth/domain/entities/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository_impl.g.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _authService;
  AuthRepositoryImpl(this._authService);

  // Hàm helper để phiên dịch dữ liệu
  AppUser? _mapFirebaseUserToAppUser(User? firebaseUser) {
    if (firebaseUser == null) return null;
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? 'Người dùng',
      photoUrl: firebaseUser.photoURL,
    );
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      // 1. Gọi Data Source (Service) để xử lý logic API
      final userCredential = await _authService.signInWithGoogle();
      // 2. Chuyển đổi UserCredential sang AppUser và trả về
      return _mapFirebaseUserToAppUser(userCredential.user);
    } catch (e) {
      // Bạn có thể custom lại Exception ở đây nếu muốn
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  AppUser? getCurrentUser() {
    final firebaseUser = _authService.currentUser; // Lấy từ Firebase
    return _mapFirebaseUserToAppUser(firebaseUser); // Dịch sang AppUser
  }
}

// Khai báo Provider dùng Riverpod Generator
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  // Đọc provider của FirebaseAuthService (từ file service của bạn)
  final authService = ref.watch(firebaseAuthServiceProvider);

  // Truyền service đó vào Repository
  return AuthRepositoryImpl(authService);
}
