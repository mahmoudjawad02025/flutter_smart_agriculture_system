import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/models/auth_user.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseDatabase _database;

  AuthService({
    required FirebaseAuth firebaseAuth,
    required FirebaseDatabase database,
  }) : _firebaseAuth = firebaseAuth,
       _database = database;

  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      return _userFromFirebaseUser(user);
    });
  }

  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User user = userCredential.user!;

      // Update display name
      await user.updateDisplayName(displayName);

      // Save user data to Realtime Database
      await _database.ref('users/${user.uid}').set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'photoUrl': user.photoURL,
        'role': 'user',
        'createdAt': DateTime.now().toIso8601String(),
      });

      return _userFromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      return _userFromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  Future<void> updateProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      final User user = _firebaseAuth.currentUser!;
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);

      // Update in database
      final Map<String, dynamic> updates = <String, dynamic>{
        'displayName': displayName,
        'photoUrl': photoUrl,
      };
      updates.removeWhere((String _, dynamic value) => value == null);
      await _database.ref('users/${user.uid}').update(updates);
    } catch (e) {
      throw Exception('Update profile failed: ${e.toString()}');
    }
  }

  Future<void> changeEmail({required String newEmail}) async {
    try {
      final User user = _firebaseAuth.currentUser!;
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update in database
      await _database.ref('users/${user.uid}/email').set(newEmail);
    } catch (e) {
      throw Exception('Change email failed: ${e.toString()}');
    }
  }

  Future<void> changePassword({required String newPassword}) async {
    try {
      final User user = _firebaseAuth.currentUser!;
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Change password failed: ${e.toString()}');
    }
  }

  Future<AuthUser?> getCurrentUser() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _userFromFirebaseUser(user);
  }

  AuthUser _userFromFirebaseUser(User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime,
    );
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'The user account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'too-many-requests':
        return 'Too many login attempts. Try again later.';
      default:
        return e.message ?? 'An error occurred';
    }
  }
}
