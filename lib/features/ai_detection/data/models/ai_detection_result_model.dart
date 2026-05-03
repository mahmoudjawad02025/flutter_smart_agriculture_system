import 'package:flutter_smart_agriculture_system/features/ai_detection/domain/entities/ai_detection_result.dart';

class AiDetectionResultModel extends AiDetectionResult {
  const AiDetectionResultModel({
    required super.detectedLabels,
    required super.createdAt,
    super.rawJson,
    super.confidence,
  });

  factory AiDetectionResultModel.fromApiResponse(Map<String, dynamic> json) {
    final Set<String> labels = <String>{};
    double? confidence;

    void collectLabels(dynamic node) {
      if (node is Map) {
        final dynamic classValue = node['class'] ?? node['label'] ?? node['name'];
        if (classValue is String && classValue.trim().isNotEmpty) {
          labels.add(classValue.trim());
        }
        final dynamic confidenceValue = node['confidence'];
        if (confidenceValue is num) {
          confidence = confidenceValue.toDouble();
        }

        for (final dynamic value in node.values) {
          collectLabels(value);
        }
        return;
      }

      if (node is List) {
        for (final dynamic item in node) {
          collectLabels(item);
        }
      }
    }

    collectLabels(json);

    return AiDetectionResultModel(
      rawJson: json,
      detectedLabels: labels.toList()..sort(),
      createdAt: DateTime.now(),
      confidence: confidence,
    );
  }
}
