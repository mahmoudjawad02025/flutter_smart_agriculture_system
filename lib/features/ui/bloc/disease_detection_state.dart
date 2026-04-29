import 'package:equatable/equatable.dart';
import 'package:smart_cucumber_agriculture_system/data/models/detection_result_model.dart';

enum DiseaseDetectionStatus { idle, imageReady, analyzing, success, error }

class DiseaseDetectionState extends Equatable {
  const DiseaseDetectionState({
    this.status = DiseaseDetectionStatus.idle,
    this.imagePath,
    this.previewRevision = 0,
    this.result,
    this.errorMessage,
  });

  final DiseaseDetectionStatus status;
  final String? imagePath;
  final int previewRevision;
  final DetectionResult? result;
  final String? errorMessage;

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get isAnalyzing => status == DiseaseDetectionStatus.analyzing;

  DiseaseDetectionState copyWith({
    DiseaseDetectionStatus? status,
    String? imagePath,
    int? previewRevision,
    bool clearImagePath = false,
    DetectionResult? result,
    bool clearResult = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DiseaseDetectionState(
      status: status ?? this.status,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      previewRevision: previewRevision ?? this.previewRevision,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    imagePath,
    previewRevision,
    result,
    errorMessage,
  ];
}
