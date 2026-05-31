import 'package:equatable/equatable.dart';

class DetectionResult extends Equatable {
  const DetectionResult({
    required this.rawJson,
    required this.detectedLabels,
    required this.createdAt,
    this.confidence,
  });

  final Map<String, dynamic> rawJson;
  final List<String> detectedLabels;
  final DateTime createdAt;
  final double? confidence;

  factory DetectionResult.fromApiResponse(Map<String, dynamic> json) {
    final Set<String> labels = <String>{};
    double? conf;

    void collectLabels(dynamic node) {
      if (node is Map) {
        final dynamic classValue =
            node['class'] ?? node['label'] ?? node['name'];
        if (classValue is String && classValue.trim().isNotEmpty) {
          final String label = classValue.trim();
          // Filter out labels that start with "كشف :" (detection prefix in Arabic)
          if (!label.startsWith('كشف :')) {
            labels.add(label);
          }
        }
        if (node.containsKey('confidence')) {
          conf = (node['confidence'] as num).toDouble();
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

    return DetectionResult(
      rawJson: json,
      detectedLabels: labels.toList()..sort(),
      createdAt: DateTime.now(),
      confidence: conf,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    rawJson,
    detectedLabels,
    createdAt,
    confidence,
  ];
}
