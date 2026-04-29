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

  factory DetectionResult.fromApiResponse(Map<String, dynamic> json) {
    final Set<String> labels = <String>{};
    _collectLabels(json, labels);

    return DetectionResult(
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

  @override
  List<Object?> get props => <Object?>[rawJson, detectedLabels, createdAt];
}
