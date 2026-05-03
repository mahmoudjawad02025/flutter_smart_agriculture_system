import 'package:flutter_smart_agriculture_system/features/dashboard/domain/repositories/dashboard_repo.dart';

class PushTestNotification {
  PushTestNotification(this._repo);
  final DashboardRepository _repo;

  Future<void> call() => _repo.pushTestNotification();
}
