import 'package:smart_cucumber_agriculture_system/features/auth/domain/entities/auth_user.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/domain/repositories/auth_repo.dart';

class GetUser {
  GetUser(this._repo);
  final AuthRepository _repo;

  Future<AuthUser?> call() => _repo.getCurrentUser();
}

