import 'package:equatable/equatable.dart';
import 'package:flutter_smart_agriculture_system/features/auth/domain/entities/auth_user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => <Object?>[];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => <Object?>[user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final AuthUser?
  authenticatedUser; // Optional: if the error occurred while user was logged in

  const AuthError(this.message, {this.authenticatedUser});

  @override
  List<Object?> get props => <Object?>[message, authenticatedUser];
}
