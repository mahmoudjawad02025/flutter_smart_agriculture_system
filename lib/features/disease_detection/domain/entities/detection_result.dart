import 'package:equatable/equatable.dart';

class DetectionResult extends Equatable {
  const DetectionResult({
    required this.rawJson,
    required this.detectedLabels,
    required this.createdAt,
  });

  final Map<String, dynamic> rawJson;
  final List<String> detectedLabels;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[rawJson, detectedLabels, createdAt];
}
