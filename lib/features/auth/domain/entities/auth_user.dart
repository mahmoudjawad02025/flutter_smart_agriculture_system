import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = 'user',
    this.status = 'approved',
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String role;
  final String status;

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, role, status];
}
