import 'package:smart_cucumber_agriculture_system/features/dashboard/domain/repositories/dashboard_repo.dart';

class GetFarmDataOnce {
  GetFarmDataOnce(this._repo);
  final DashboardRepository _repo;

  Future<Map<String, dynamic>?> call() => _repo.getFarmDataOnce();
}

