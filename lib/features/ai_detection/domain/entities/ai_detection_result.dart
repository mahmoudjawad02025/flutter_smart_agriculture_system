import 'package:equatable/equatable.dart';

class AiDetectionResult extends Equatable {
  const AiDetectionResult({
    required this.detectedLabels,
    required this.createdAt,
    this.rawJson,
  });

  final List<String> detectedLabels;
  final DateTime createdAt;
  final Map<String, dynamic>? rawJson;

  @override
  List<Object?> get props => [detectedLabels, createdAt, rawJson];
}
