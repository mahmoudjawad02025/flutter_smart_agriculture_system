import 'package:smart_cucumber_agriculture_system/features/auth/data/models/auth_user_model.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/domain/repositories/auth_repo.dart';

class Login {
  Login(this._repo);
  final AuthRepository _repo;

  Future<AuthUser> call({required String email, required String password}) {
    return _repo.login(email: email, password: password);
  }
}

