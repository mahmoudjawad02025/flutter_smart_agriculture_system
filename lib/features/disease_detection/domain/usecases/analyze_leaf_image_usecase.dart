import '../entities/detection_result.dart';
import '../repositories/disease_detection_repository.dart';

class AnalyzeLeafImageUseCase {
  const AnalyzeLeafImageUseCase(this._repository);

  final DiseaseDetectionRepository _repository;

  Future<DetectionResult> call(String imagePath) {
    return _repository.analyzeSavedImage(imagePath);
  }
}
