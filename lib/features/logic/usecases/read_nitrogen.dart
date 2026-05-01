import 'package:smart_cucumber_agriculture_system/features/logic/repositories/firebase_data_repo.dart';

class ReadNitrogen {
  ReadNitrogen(this._repo);
  final FirebaseDataRepository _repo;

  Future<int?> call() => _repo.readNitrogenOnce();
}
