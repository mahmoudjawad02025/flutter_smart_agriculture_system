import 'package:equatable/equatable.dart';
import 'package:smart_cucumber_agriculture_system/features/ai_detection/data/models/detection_result_model.dart';

enum AiDetectionStatus { idle, imageReady, analyzing, success, error }

class AiDetectionState extends Equatable {
  const AiDetectionState({
    this.status = AiDetectionStatus.idle,
    this.imagePath,
    this.previewRevision = 0,
    this.result,
    this.errorMessage,
  });

  final AiDetectionStatus status;
  final String? imagePath;
  final int previewRevision;
  final DetectionResult? result;
  final String? errorMessage;

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get isAnalyzing => status == AiDetectionStatus.analyzing;

  AiDetectionState copyWith({
    AiDetectionStatus? status,
    String? imagePath,
    int? previewRevision,
    bool clearImagePath = false,
    DetectionResult? result,
    bool clearResult = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AiDetectionState(
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

