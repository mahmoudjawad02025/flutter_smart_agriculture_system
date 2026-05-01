import 'package:smart_cucumber_agriculture_system/features/ai_detection/domain/entities/ai_detection_result.dart';
import 'package:smart_cucumber_agriculture_system/features/ai_detection/domain/repositories/ai_detection_repo.dart';

class PickAndSaveLeafImage {
  PickAndSaveLeafImage(this.repository);
  final AiDetectionRepository repository;

  Future<String?> call() => repository.pickAndSaveLeafImage();
}

class AnalyzeLeafImage {
  AnalyzeLeafImage(this.repository);
  final AiDetectionRepository repository;

  Future<AiDetectionResult> call(String imagePath) =>
      repository.analyzeSavedImage(imagePath);
}

class UpdateLeafStatus {
  UpdateLeafStatus(this.repository);
  final AiDetectionRepository repository;

  Future<void> call(AiDetectionResult result) =>
      repository.updateLeafStatusInFirebase(result);
}
