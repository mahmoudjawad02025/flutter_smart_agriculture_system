import '../../domain/entities/detection_result.dart';
import '../../domain/repositories/disease_detection_repository.dart';
import '../datasources/local_image_data_source.dart';
import '../datasources/roboflow_remote_data_source.dart';

class DiseaseDetectionRepositoryImpl implements DiseaseDetectionRepository {
  DiseaseDetectionRepositoryImpl({
    required LocalImageDataSource localImageDataSource,
    required RoboflowRemoteDataSource remoteDataSource,
  }) : _localImageDataSource = localImageDataSource,
       _remoteDataSource = remoteDataSource;

  final LocalImageDataSource _localImageDataSource;
  final RoboflowRemoteDataSource _remoteDataSource;

  @override
  Future<String?> pickAndSaveLeafImage() {
    return _localImageDataSource.pickAndSaveImageAsMainUpload();
  }

  @override
  Future<DetectionResult> analyzeSavedImage(String imagePath) {
    return _remoteDataSource.analyzeImage(imagePath);
  }
}
