import 'package:smart_cucumber_agriculture_system/features/dashboard/logic/repositories/dashboard_repo.dart';

class UpdateCropTargets {
  UpdateCropTargets(this._repo);
  final DashboardRepository _repo;

  Future<void> call({
    required int moistMin,
    required int moistMax,
    required int nMin,
    required int nMax,
    required int pMin,
    required int pMax,
    required int kMin,
    required int kMax,
    required String leafGoal,
  }) {
    return _repo.updateCropTargets(
      moistMin: moistMin,
      moistMax: moistMax,
      nMin: nMin,
      nMax: nMax,
      pMin: pMin,
      pMax: pMax,
      kMin: kMin,
      kMax: kMax,
      leafGoal: leafGoal,
    );
  }
}

