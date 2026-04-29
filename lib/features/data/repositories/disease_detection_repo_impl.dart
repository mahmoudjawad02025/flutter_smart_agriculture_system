import 'package:smart_cucumber_agriculture_system/data/datasources/disease_detection_ds.dart';
import 'package:smart_cucumber_agriculture_system/data/models/detection_result_model.dart';
import 'package:smart_cucumber_agriculture_system/logic/repositories/disease_detection_repo.dart';

class DiseaseDetectionRepositoryImpl implements DiseaseDetectionRepository {
  DiseaseDetectionRepositoryImpl(this._dataSource);

  final DiseaseDetectionService _dataSource;

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
