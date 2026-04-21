import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/cubit/auth_state.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/models/auth_user.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/services/auth_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  late final StreamSubscription<AuthUser?> _authStateSubscription;

  AuthCubit({required AuthService authService})
    : _authService = authService,
      super(const AuthInitial()) {
    _bindAuthStateChanges();
  }

  void _bindAuthStateChanges() {
    _authStateSubscription = _authService.authStateChanges.listen(
      (AuthUser? user) {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
      onError: (Object error) {
        emit(AuthError(error.toString()));
      },
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      emit(const AuthLoading());
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      emit(const AuthLoading());
      await _authService.login(email: email, password: password);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    try {
      emit(const AuthLoading());
      await _authService.logout();
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> updateProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      await _authService.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      // Refresh auth state
      final AuthUser? user = await _authService.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> changeEmail({required String newEmail}) async {
    try {
      await _authService.changeEmail(newEmail: newEmail);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> changePassword({required String newPassword}) async {
    try {
      await _authService.changePassword(newPassword: newPassword);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _authStateSubscription.cancel();
    await super.close();
  }
}
