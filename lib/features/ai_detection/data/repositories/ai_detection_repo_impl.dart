import 'package:smart_cucumber_agriculture_system/features/ai_detection/data/datasources/ai_detection_ds.dart';
import 'package:smart_cucumber_agriculture_system/features/ai_detection/data/models/detection_result_model.dart';
import 'package:smart_cucumber_agriculture_system/features/ai_detection/logic/repositories/ai_detection_repo.dart';

class AiDetectionRepositoryImpl implements AiDetectionRepository {
  AiDetectionRepositoryImpl(this._dataSource);

  final AiDetectionService _dataSource;

  @override
  Future<DetectionResult> analyzeSavedImage(String imagePath) {
    return _dataSource.analyzeSavedImage(imagePath);
  }

  @override
  Future<String?> pickAndSaveLeafImage() => _dataSource.pickAndSaveLeafImage();

  @override
  Future<void> updateLeafStatusInFirebase(DetectionResult result) {
    return _dataSource.updateLeafStatusInFirebase(result);
  }
}

