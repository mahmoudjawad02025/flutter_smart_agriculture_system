import 'package:smart_cucumber_agriculture_system/logic/repositories/firebase_data_repo.dart';

class GetFarmDataOnce {
  GetFarmDataOnce(this._repo);
  final FirebaseDataRepository _repo;

  Future<Map<String, dynamic>?> call() => _repo.getFarmDataOnce();
}
