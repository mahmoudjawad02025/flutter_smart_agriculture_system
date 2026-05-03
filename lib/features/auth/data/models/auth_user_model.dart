import 'package:flutter_smart_agriculture_system/features/auth/domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.uid,
    required super.email,
    super.displayName,
    super.photoUrl,
    super.role = 'user',
    super.status = 'approved',
    this.isAnonymous = false,
    this.createdAt,
  });

  final bool isAnonymous;
  final DateTime? createdAt;

  AuthUserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    DateTime? createdAt,
    String? role,
    String? status,
  }) {
    return AuthUserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  factory AuthUserModel.fromMap(
    Map<String, dynamic> map,
    String uid,
    String email,
  ) {
    return AuthUserModel(
      uid: uid,
      email: email,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] as String? ?? 'user',
      status: map['status'] as String? ?? 'approved',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }
}
