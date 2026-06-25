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
    _restorePersistedSession();
  }

  Future<void> _restorePersistedSession() async {
    try {
      final AuthUser? user = await _authService.getCurrentUser();
      if (user != null && !isClosed) {
        emit(AuthAuthenticated(user));
      } else if (!isClosed && state is AuthInitial) {
        emit(const AuthUnauthenticated());
      }
    } catch (error) {
      if (!isClosed && state is AuthInitial) {
        emit(const AuthUnauthenticated());
      }
    }
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
          'تم إرسال رسالة تحقق إلى $newEmail. يرجى التأكيد لإتمام التغيير.',
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
      emit(AuthError('تم تحديث كلمة المرور بنجاح.', authenticatedUser: user));
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
