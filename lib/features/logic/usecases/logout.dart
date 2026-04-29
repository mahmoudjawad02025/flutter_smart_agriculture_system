import 'package:smart_cucumber_agriculture_system/logic/repositories/auth_repo.dart';

class Logout {
  Logout(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.logout();
}
