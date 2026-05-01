import 'package:smart_cucumber_agriculture_system/features/logic/repositories/firebase_data_repo.dart';

class WriteSampleData {
  WriteSampleData(this._repo);
  final FirebaseDataRepository _repo;

  Future<void> call() => _repo.writeSampleData();
}
