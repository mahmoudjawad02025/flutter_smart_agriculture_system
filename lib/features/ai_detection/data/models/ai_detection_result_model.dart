import 'package:smart_cucumber_agriculture_system/features/ai_detection/domain/entities/ai_detection_result.dart';

class AiDetectionResultModel extends AiDetectionResult {
  const AiDetectionResultModel({
    required super.detectedLabels,
    required super.createdAt,
    super.rawJson,
  });

  factory AiDetectionResultModel.fromApiResponse(Map<String, dynamic> json) {
    final Set<String> labels = <String>{};
    _collectLabels(json, labels);

    return AiDetectionResultModel(
      rawJson: json,
      detectedLabels: labels.toList()..sort(),
      createdAt: DateTime.now(),
    );
  }

  static void _collectLabels(dynamic node, Set<String> labels) {
    if (node is Map) {
      final dynamic classValue = node['class'] ?? node['label'] ?? node['name'];
      if (classValue is String && classValue.trim().isNotEmpty) {
        labels.add(classValue.trim());
      }

      for (final dynamic value in node.values) {
        _collectLabels(value, labels);
      }
      return;
    }

    if (node is List) {
      for (final dynamic item in node) {
        _collectLabels(item, labels);
      }
    }
  }
}
