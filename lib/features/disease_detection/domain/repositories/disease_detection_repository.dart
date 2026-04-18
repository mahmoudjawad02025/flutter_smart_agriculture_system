import '../entities/detection_result.dart';

abstract class DiseaseDetectionRepository {
  Future<String?> pickAndSaveLeafImage();

  Future<DetectionResult> analyzeSavedImage(String imagePath);
}
