import 'package:smart_cucumber_agriculture_system/features/dashboard/logic/repositories/dashboard_repo.dart';

class PushTestNotification {
  PushTestNotification(this._repo);
  final DashboardRepository _repo;

  Future<void> call() => _repo.pushTestNotification();
}

