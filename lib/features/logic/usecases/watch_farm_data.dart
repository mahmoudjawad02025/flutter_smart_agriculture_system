import 'package:smart_cucumber_agriculture_system/logic/repositories/firebase_data_repo.dart';

class WatchFarmData {
  WatchFarmData(this._repo);
  final FirebaseDataRepository _repo;

  Stream<Map<String, dynamic>?> call() => _repo.watchFarmData();
}
