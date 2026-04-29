abstract class FirebaseDataRepository {
  Future<void> writeSampleData();
  Future<int?> readNitrogenOnce();
  Future<void> pushTestNotification();
  Future<Map<String, dynamic>?> getFarmDataOnce();
  Stream<Map<String, dynamic>?> watchFarmData();
  Stream<Map<String, dynamic>?> watchLogs();
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
