abstract class DashboardRepository {
  Future<void> writeSampleData();
  Future<int?> readNitrogenOnce();
  Future<void> pushTestNotification();
  Future<Map<String, dynamic>?> getFarmDataOnce();
  Stream<Map<String, dynamic>?> watchFarmData();
  Stream<Map<String, dynamic>?> watchLogs();
  Stream<Map<String, dynamic>?> watchPumps();
  Future<void> setPumpAutoMode(bool value);
  Future<void> setManualPumpState({
    required String pumpKey,
    required String pumpName,
    required bool value,
  });
  Future<void> updateCropTargets({
    required int moistMin,
    required int moistMax,
    required int nMin,
    required int nMax,
    required int pMin,
    required int pMax,
    required int kMin,
    required int kMax,
    required String leafGoal,
  });
}
