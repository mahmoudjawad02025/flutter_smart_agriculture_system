import 'package:flutter_smart_agriculture_system/features/dashboard/domain/repositories/dashboard_repo.dart';

class WatchLogs {
  WatchLogs(this._repo);
  final DashboardRepository _repo;

  Stream<Map<String, dynamic>?> call() => _repo.watchLogs();
}
