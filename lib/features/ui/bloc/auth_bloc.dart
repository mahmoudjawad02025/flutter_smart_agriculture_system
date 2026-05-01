import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/features/ui/bloc/auth_state.dart';
import 'package:smart_cucumber_agriculture_system/features/data/models/auth_user_model.dart';
import 'package:smart_cucumber_agriculture_system/features/logic/repositories/auth_repo.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authService;
  late final StreamSubscription<AuthUser?> _authStateSubscription;
  AuthCubit({required AuthRepository authService})
    : _authService = authService,
      super(const AuthInitial()) {
    _bindAuthStateChanges();
  }

  void _bindAuthStateChanges() {
    _authStateSubscription = _authService.authStateChanges().listen(
      (AuthUser? user) {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
      onError: (Object error) {
        emit(AuthError(_cleanError(error)));
      },
    );
  }

  AuthUser? get _currentUser {
    final s = state;
    if (s is AuthAuthenticated) return s.user;
    if (s is AuthError) return s.authenticatedUser;
    return null;
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
      emit(AuthError(_cleanError(e)));
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      emit(const AuthLoading());
      await _authService.login(email: email, password: password);
    } catch (e) {
      emit(AuthError(_cleanError(e)));
    }
  }

  Future<void> logout() async {
    try {
      emit(const AuthLoading());
      await _authService.logout();
    } catch (e) {
      emit(AuthError(_cleanError(e)));
    }
  }

  Future<void> updateProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    final user = _currentUser;
    try {
      await _authService.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      final AuthUser? refreshedUser = await _authService.getCurrentUser();
      if (refreshedUser != null) {
        emit(AuthAuthenticated(refreshedUser));
      }
    } catch (e) {
      emit(AuthError(_cleanError(e), authenticatedUser: user));
    }
  }

  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _currentUser;
    try {
      // Don't emit loading here to avoid screen flickering,
      // or at least capture the user
      await _authService.changeEmail(
        currentPassword: currentPassword,
        newEmail: newEmail,
      );
      emit(
        AuthError(
          'Verification email sent to $newEmail. Please confirm to finish change.',
          authenticatedUser: user,
        ),
      );
    } catch (e) {
      emit(AuthError(_cleanError(e), authenticatedUser: user));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(
        AuthError('Password updated successfully.', authenticatedUser: user),
      );
    } catch (e) {
      emit(AuthError(_cleanError(e), authenticatedUser: user));
    }
  }

  String _cleanError(dynamic e) {
    String msg = e.toString();
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    if (msg.startsWith('Exception ')) return msg.substring(10);
    return msg;
  }

  // Admin Methods
  Future<List<AuthUser>> fetchAllUsers() async {
    return _authService.getAllUsers();
  }

  Future<void> updateUserStatus(String uid, String status) async {
    final user = _currentUser;
    try {
      await _authService.updateUserStatus(uid, status);
    } catch (e) {
      emit(AuthError(_cleanError(e), authenticatedUser: user));
    }
  }

  @override
  Future<void> close() async {
    await _authStateSubscription.cancel();
    await super.close();
  }
}
