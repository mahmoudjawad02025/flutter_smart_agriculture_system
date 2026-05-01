import 'package:smart_cucumber_agriculture_system/features/ai_detection/data/models/detection_result_model.dart';

abstract class AiDetectionRepository {
  Future<String?> pickAndSaveLeafImage();
  Future<DetectionResult> analyzeSavedImage(String imagePath);
  Future<void> updateLeafStatusInFirebase(DetectionResult result);
}

