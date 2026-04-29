import 'package:smart_cucumber_agriculture_system/data/datasources/auth_ds.dart';
import 'package:smart_cucumber_agriculture_system/data/models/auth_user_model.dart';
import 'package:smart_cucumber_agriculture_system/logic/repositories/auth_repo.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final AuthService _dataSource;

  @override
  @override
  Stream<AuthUser?> authStateChanges() => _dataSource.authStateChanges;

  @override
  Future<AuthUser> login({required String email, required String password}) {
    return _dataSource.login(email: email, password: password);
  }

  @override
  Future<void> logout() => _dataSource.logout();

  @override
  Future<AuthUser?> getCurrentUser() => _dataSource.getCurrentUser();

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _dataSource.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  @override
  Future<void> updateProfile({required String displayName, String? photoUrl}) {
    return _dataSource.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) {
    return _dataSource.changeEmail(
      currentPassword: currentPassword,
      newEmail: newEmail,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _dataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<List<AuthUser>> getAllUsers() {
    return _dataSource.getAllUsers();
  }

  @override
  Future<void> updateUserStatus(String uid, String status) {
    return _dataSource.updateUserStatus(uid, status);
  }
}
