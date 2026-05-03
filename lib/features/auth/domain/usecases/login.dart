import 'package:flutter_smart_agriculture_system/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_smart_agriculture_system/features/auth/domain/repositories/auth_repo.dart';

class Login {
  Login(this._repo);
  final AuthRepository _repo;

  Future<AuthUser> call({required String email, required String password}) {
    return _repo.login(email: email, password: password);
  }
}
