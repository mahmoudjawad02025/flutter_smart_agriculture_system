import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_cucumber_agriculture_system/data/models/auth_user_model.dart';

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
      try {
        final authUser = await _userFromFirebaseUser(user);
        if (authUser.status != 'approved') return null; 
        return authUser;
      } catch (e) {
        return null;
      }
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
      await user.updateDisplayName(displayName);

      final bool isAdmin = email.toLowerCase() == 'admin@agriculture.local';

      await _database.ref('users/${user.uid}').set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'role': isAdmin ? 'admin' : 'user',
        'status': isAdmin ? 'approved' : 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!isAdmin) {
        final String notifId = 'signup_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
        await _database.ref('smart_cucumber_agriculture/data/notifications/$notifId').set({
          'id': notifId,
          'title': 'New User Request',
          'disease_name': 'User_Signup', 
          'message': 'A new user ($displayName) has registered and is waiting for your approval in User Management.',
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'next_upload': '',
          'is_read': false,
        });
      }

      final authUser = await _userFromFirebaseUser(user);

      if (authUser.status == 'pending') {
        await _firebaseAuth.signOut();
        throw Exception('Account created successfully! Please wait for an administrator to approve your request.');
      }

      return authUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final authUser = await _userFromFirebaseUser(userCredential.user!);

      if (authUser.status == 'pending') {
        await logout();
        throw Exception('Your account is pending approval by an admin. Please check back later.');
      }
      if (authUser.status == 'rejected' || authUser.status == 'blocked') {
        await logout();
        throw Exception('Your account access has been restricted by an admin.');
      }

      return authUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  Future<AuthUser?> getCurrentUser() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) return null;
    final authUser = await _userFromFirebaseUser(user);
    return authUser.status == 'approved' ? authUser : null;
  }

  // Security Verification Methods
  Future<void> reauthenticate(String password) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) throw Exception('No user logged in.');
    
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    
    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updateProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    try {
      final User user = _firebaseAuth.currentUser!;
      await user.updateDisplayName(displayName);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);

      await _database.ref('users/${user.uid}').update({
        'displayName': displayName,
        'photoUrl': photoUrl,
      });
    } catch (e) {
      throw Exception('Update profile failed: ${e.toString()}');
    }
  }

  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    try {
      await reauthenticate(currentPassword);
      final User user = _firebaseAuth.currentUser!;
      // Firebase verifyBeforeUpdateEmail sends a link to the NEW email
      await user.verifyBeforeUpdateEmail(newEmail);
      await _database.ref('users/${user.uid}/email').set(newEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await reauthenticate(currentPassword);
      final User user = _firebaseAuth.currentUser!;
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<AuthUser> _userFromFirebaseUser(User user) async {
    final snapshot = await _database.ref('users/${user.uid}').get();
    
    if (!snapshot.exists) {
      return AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        role: (user.email?.toLowerCase() == 'admin@agriculture.local') ? 'admin' : 'user',
        status: (user.email?.toLowerCase() == 'admin@agriculture.local') ? 'approved' : 'pending',
        createdAt: user.metadata.creationTime,
      );
    }

    final data = snapshot.value as Map? ?? {};
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: data['displayName'] ?? user.displayName,
      role: data['role'] ?? 'user',
      status: data['status'] ?? 'approved',
      createdAt: user.metadata.creationTime,
    );
  }

  Future<void> updateUserStatus(String uid, String newStatus) async {
    await _database.ref('users/$uid/status').set(newStatus);
  }

  Future<List<AuthUser>> getAllUsers() async {
    final snapshot = await _database.ref('users').get();
    if (!snapshot.exists) return [];
    
    final Map<dynamic, dynamic> usersMap = snapshot.value as Map;
    final List<AuthUser> users = [];
    
    usersMap.forEach((key, value) {
      final data = value as Map;
      users.add(AuthUser(
        uid: data['uid'] ?? '',
        email: data['email'] ?? '',
        displayName: data['displayName'],
        role: data['role'] ?? 'user',
        status: data['status'] ?? 'pending',
      ));
    });
    
    return users;
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password': return 'The password provided is too weak.';
      case 'email-already-in-use': return 'The account already exists for that email.';
      case 'invalid-email': return 'The email address is not valid.';
      case 'user-disabled': return 'The user account has been disabled.';
      case 'user-not-found': return 'No user found for that email.';
      case 'wrong-password': 
      case 'invalid-credential':
        return 'The current password you entered is incorrect.';
      case 'internal-error':
        return 'Authentication failed. Please check your current password.';
      default: return e.message ?? 'An error occurred';
    }
  }
}
