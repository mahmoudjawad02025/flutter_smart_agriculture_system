import 'package:smart_cucumber_agriculture_system/features/data/models/auth_user_model.dart';
import 'package:smart_cucumber_agriculture_system/features/logic/repositories/auth_repo.dart';

class LoginUseCase {
  LoginUseCase(this._repo);
  final AuthRepository _repo;

  Future<AuthUser> call({required String email, required String password}) {
    return _repo.login(email: email, password: password);
  }
}

class LogoutUseCase {
  LogoutUseCase(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.logout();
}

class GetCurrentUserUseCase {
  GetCurrentUserUseCase(this._repo);
  final AuthRepository _repo;

  Future<AuthUser?> call() => _repo.getCurrentUser();
}
