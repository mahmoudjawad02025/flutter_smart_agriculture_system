import 'package:smart_cucumber_agriculture_system/features/dashboard/logic/repositories/dashboard_repo.dart';

class WriteSampleData {
  WriteSampleData(this._repo);
  final DashboardRepository _repo;

  Future<void> call() => _repo.writeSampleData();
}

