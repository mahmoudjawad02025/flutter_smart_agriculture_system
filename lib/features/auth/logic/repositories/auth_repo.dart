import 'package:smart_cucumber_agriculture_system/features/auth/data/models/auth_user_model.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<AuthUser> login({required String email, required String password});
  Future<void> logout();
  Future<AuthUser?> getCurrentUser();

  // Additional account management
  Future<void> updateProfile({required String displayName, String? photoUrl});
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  // Admin methods
  Future<List<AuthUser>> getAllUsers();
  Future<void> updateUserStatus(String uid, String status);
}

