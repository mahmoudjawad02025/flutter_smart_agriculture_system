import 'package:smart_cucumber_agriculture_system/features/data/models/detection_result_model.dart';

abstract class DiseaseDetectionRepository {
  Future<String?> pickAndSaveLeafImage();
  Future<DetectionResult> analyzeSavedImage(String imagePath);
  Future<void> updateLeafStatusInFirebase(DetectionResult result);
}
