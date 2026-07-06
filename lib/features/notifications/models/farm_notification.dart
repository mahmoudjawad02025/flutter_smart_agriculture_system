import 'package:equatable/equatable.dart';
import '../../../core/localization/app_strings.dart';

class FarmNotification extends Equatable {
  const FarmNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.diseaseName,
    required this.nextUpload,
    required this.isRead,
    required this.createdAt,
    this.type = '',
  });

  static const String typeSensorAlert = 'sensor_alert';
  static const String typeTankAlert = 'tank_alert';
  static const String typeForceStop = 'force_stop';
  static const String typeDisease = 'disease';
  static const String typePumpChange = 'pump_change';
  static const String typeImageUpload = 'image_upload';
  static const String typeUserSignup = 'user_signup';
  static const String typeReuploadReminder = 'reupload_reminder';
  static const String typeManualTest = 'manual_test';
  static const String typeAutoAction = 'auto_action';
  static const String typeGeneral = 'general';

  final String id;
  final String title;
  final String message;
  final String diseaseName;
  final String nextUpload;
  final bool isRead;
  final DateTime createdAt;
  final String type;

  String get resolvedType {
    final String explicit = type.trim().toLowerCase();
    if (explicit.isNotEmpty) return explicit;

    final String legacy = diseaseName.trim().toLowerCase();
    if (legacy.startsWith('sensor_threshold') || legacy == 'sensor_alert') {
      return typeSensorAlert;
    }
    if (legacy.startsWith('pump_change') || legacy == 'system_log') {
      return typePumpChange;
    }
    if (legacy.startsWith('auto_')) return typeAutoAction;
    if (legacy == 'image_upload') return typeImageUpload;
    if (legacy == 'user_signup') return typeUserSignup;
    if (legacy == 'manualtest' || legacy == 'manual_test') {
      return typeManualTest;
    }
    if (legacy.isNotEmpty) return typeDisease;
    return typeGeneral;
  }

  /// Whether this notification should appear in the in-app list.
  bool get isDisplayable {
    switch (resolvedType) {
      case typeDisease:
      case typeUserSignup:
      case typeReuploadReminder:
      case typeSensorAlert:
      case typeTankAlert:
      case typeForceStop:
        return true;
      case typeImageUpload:
      case typePumpChange:
      case typeManualTest:
      case typeAutoAction:
        return false;
      default:
        return resolvedType == typeGeneral && diseaseName.isNotEmpty;
    }
  }

  factory FarmNotification.fromMap(String id, Map<String, dynamic> map) {
    return FarmNotification(
      id: id,
      title: map['title'] as String? ?? AppStrings.diseaseDetected,
      message: map['message'] as String? ?? '',
      diseaseName: map['disease_name'] as String? ?? '',
      nextUpload: map['next_upload'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: _parseDateTime(map['created_at']),
      type: map['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'title': title,
      'message': message,
      'next_upload': nextUpload,
      'is_read': isRead,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
    if (type.isNotEmpty) {
      map['type'] = type;
    }
    if (diseaseName.isNotEmpty) {
      map['disease_name'] = diseaseName;
    }
    return map;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(value.trim());
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }

  FarmNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? diseaseName,
    String? nextUpload,
    bool? isRead,
    DateTime? createdAt,
    String? type,
  }) {
    return FarmNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      diseaseName: diseaseName ?? this.diseaseName,
      nextUpload: nextUpload ?? this.nextUpload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    message,
    diseaseName,
    nextUpload,
    isRead,
    createdAt,
    type,
  ];
}
