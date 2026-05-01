import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final DateTime? createdAt;
  final String role; // 'admin', 'user'
  final String status; // 'pending', 'approved', 'rejected', 'blocked'

  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.createdAt,
    this.role = 'user',
    this.status = 'approved', // default for backward compatibility
  });

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    DateTime? createdAt,
    String? role,
    String? status,
  }) {
    return AuthUser(
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

  @override
  List<Object?> get props => <Object?>[
        uid,
        email,
        displayName,
        photoUrl,
        isAnonymous,
        createdAt,
        role,
        status,
      ];
}
