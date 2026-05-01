import 'package:smart_cucumber_agriculture_system/features/ai_detection/domain/entities/ai_detection_result.dart';

abstract class AiDetectionRepository {
  Future<String?> pickAndSaveLeafImage();
  Future<AiDetectionResult> analyzeSavedImage(String imagePath);
  Future<void> updateLeafStatusInFirebase(AiDetectionResult result);
}
