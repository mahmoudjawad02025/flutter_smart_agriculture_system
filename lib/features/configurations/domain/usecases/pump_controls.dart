import 'package:flutter_smart_agriculture_system/features/dashboard/domain/repositories/dashboard_repo.dart';

class WatchPumps {
  WatchPumps(this._repo);
  final DashboardRepository _repo;

  Stream<Map<String, dynamic>?> call() => _repo.watchPumps();
}

class SetPumpAutoMode {
  SetPumpAutoMode(this._repo);
  final DashboardRepository _repo;

  Future<void> call(bool value) => _repo.setPumpAutoMode(value);
}

class SetManualPumpState {
  SetManualPumpState(this._repo);
  final DashboardRepository _repo;

  Future<void> call({
    required String pumpKey,
    required String pumpName,
    required bool value,
  }) {
    return _repo.setManualPumpState(
      pumpKey: pumpKey,
      pumpName: pumpName,
      value: value,
    );
  }
}
