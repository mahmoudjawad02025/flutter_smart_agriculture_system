import 'package:equatable/equatable.dart';

class FarmNotification extends Equatable {
  const FarmNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.diseaseName,
    required this.nextUpload,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String diseaseName;
  final String nextUpload;
  final bool isRead;
  final DateTime createdAt;

  factory FarmNotification.fromMap(String id, Map<String, dynamic> map) {
    return FarmNotification(
      id: id,
      title: map['title'] as String? ?? 'Disease Detected',
      message: map['message'] as String? ?? '',
      diseaseName: map['disease_name'] as String? ?? '',
      nextUpload: map['next_upload'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'message': message,
      'disease_name': diseaseName,
      'next_upload': nextUpload,
      'is_read': isRead,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.parse(value);
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
  }) {
    return FarmNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      diseaseName: diseaseName ?? this.diseaseName,
      nextUpload: nextUpload ?? this.nextUpload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
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
  ];
}
