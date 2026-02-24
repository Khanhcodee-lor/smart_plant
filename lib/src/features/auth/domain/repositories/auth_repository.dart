import 'package:app_iot/src/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> signInWithGoogle();
  Future<void> signOut();

  AppUser? getCurrentUser();
}
