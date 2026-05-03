import 'package:equatable/equatable.dart';

class AiDetectionResult extends Equatable {
  const AiDetectionResult({
    required this.detectedLabels,
    required this.createdAt,
    this.rawJson,
    this.confidence,
  });

  final List<String> detectedLabels;
  final DateTime createdAt;
  final Map<String, dynamic>? rawJson;
  final double? confidence;

  @override
  List<Object?> get props => [detectedLabels, createdAt, rawJson, confidence];
}
