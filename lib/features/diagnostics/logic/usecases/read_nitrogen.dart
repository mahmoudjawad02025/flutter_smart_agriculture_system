import 'package:smart_cucumber_agriculture_system/features/dashboard/logic/repositories/dashboard_repo.dart';

class ReadNitrogen {
  ReadNitrogen(this._repo);
  final DashboardRepository _repo;

  Future<int?> call() => _repo.readNitrogenOnce();
}

