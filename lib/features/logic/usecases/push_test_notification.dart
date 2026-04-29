import 'package:smart_cucumber_agriculture_system/logic/repositories/firebase_data_repo.dart';

class PushTestNotification {
  PushTestNotification(this._repo);
  final FirebaseDataRepository _repo;

  Future<void> call() => _repo.pushTestNotification();
}
