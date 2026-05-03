import 'package:flutter_smart_agriculture_system/features/auth/domain/repositories/auth_repo.dart';

class Logout {
  Logout(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.logout();
}
