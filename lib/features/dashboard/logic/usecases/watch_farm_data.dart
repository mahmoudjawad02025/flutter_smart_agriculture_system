import 'package:smart_cucumber_agriculture_system/features/dashboard/logic/repositories/dashboard_repo.dart';

class WatchFarmData {
  WatchFarmData(this._repo);
  final DashboardRepository _repo;

  Stream<Map<String, dynamic>?> call() => _repo.watchFarmData();
}

