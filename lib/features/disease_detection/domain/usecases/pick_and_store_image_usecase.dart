import '../repositories/disease_detection_repository.dart';

class PickAndStoreImageUseCase {
  const PickAndStoreImageUseCase(this._repository);

  final DiseaseDetectionRepository _repository;

  Future<String?> call() {
    return _repository.pickAndSaveLeafImage();
  }
}
