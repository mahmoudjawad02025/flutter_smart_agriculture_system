import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:smart_cucumber_agriculture_system/features/auth/models/auth_user.dart';
import 'package:smart_cucumber_agriculture_system/features/firebase_data/models/farm_payload.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseDatabase _database;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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

      final bool isFirstUser = await _isFirstUser();
      final bool isAdmin = isFirstUser;

      await _database.ref('${FarmPayload.usersPath}/${user.uid}').set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'role': isAdmin ? 'admin' : 'user',
        'status': isAdmin ? 'approved' : 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!isAdmin) {
        final String notifId =
            'signup_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
        await _database
            .ref('${FarmPayload.notificationItemsPath}/notif_$notifId')
            .set({
              'id': notifId,
              'title': 'مستخدم جديد بانتظار تأكيد المسؤول',
              'disease_name': 'User_Signup',
              'message':
                  'تم تسجيل مستخدم جديد ويحتاج إلى موافقة المسؤول لتفعيل الحساب.',
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'next_upload': '',
              'is_read': false,
            });
        // Ensure admins see the signup: increment the unread counter.
        try {
          final DataSnapshot countSnapshot = await _database
              .ref(FarmPayload.unreadCountPath)
              .get();
          final int currentCount = (countSnapshot.value as int?) ?? 0;
          await _database
              .ref(FarmPayload.unreadCountPath)
              .set(currentCount + 1);
        } catch (e) {
          // Do not block signup flow if increment fails; log for debugging.
          print('[AUTH_SERVICE] Failed to increment unread_count: $e');
        }
      }

      final authUser = await _userFromFirebaseUser(user);

      if (authUser.status == 'pending') {
        await _firebaseAuth.signOut();
        throw Exception(
          'تم إنشاء الحساب بنجاح! يرجى الانتظار حتى يوافق المسؤول على طلبك.',
        );
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
        throw Exception(
          'حسابك معلق في انتظار موافقة المسؤول. يرجى المحاولة لاحقًا.',
        );
      }
      if (authUser.status == 'rejected' || authUser.status == 'blocked') {
        await logout();
        throw Exception('تم تقييد وصول حسابك من قبل مسؤول.');
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
      throw Exception('فشل تسجيل الخروج: ${e.toString()}');
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
    if (user == null || user.email == null)
      throw Exception('لا يوجد مستخدم مسجل الدخول.');

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

      await _database.ref('${FarmPayload.usersPath}/${user.uid}').update({
        'displayName': displayName,
        'photoUrl': photoUrl,
      });
    } catch (e) {
      throw Exception('فشل تحديث الملف الشخصي: ${e.toString()}');
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
      await _database
          .ref('${FarmPayload.usersPath}/${user.uid}/email')
          .set(newEmail);
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
    final snapshot = await _database
        .ref('${FarmPayload.usersPath}/${user.uid}')
        .get();

    if (!snapshot.exists) {
      final bool isAdmin = await _isFirstUser();
      await _ensureUserRecord(user: user, isAdmin: isAdmin);
      return AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        role: isAdmin ? 'admin' : 'user',
        status: isAdmin ? 'approved' : 'pending',
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
    await _database.ref('${FarmPayload.usersPath}/$uid/status').set(newStatus);
  }

  /// Delete a user account from both Firebase Auth and Realtime Database
/// Delete current user account (requires reauthentication)
  Future<void> deleteCurrentUser(String password) async {
    try {
      final User? user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('لا يوجد مستخدم مسجل الدخول.');
      }

      // Reauthenticate first
      await reauthenticate(password);

      // Delete from Realtime Database
      await _database.ref('${FarmPayload.usersPath}/${user.uid}').remove();

      // Delete from Firebase Authentication
      await user.delete();

      print('[AUTH_SERVICE] Current user ${user.uid} deleted from Auth and Database');
    } catch (e) {
      print('[AUTH_SERVICE] Error deleting current user: $e');
      rethrow;
    }
  }

  /// Admin delete: Delete user from both Realtime Database and Firebase Authentication
  /// Calls a Cloud Function with Admin SDK privileges
  Future<void> deleteUserAsAdmin(String uid) async {
    try {
      // Call Cloud Function to delete user from Firebase Authentication
      final HttpsCallable deleteUserFunction =
          _functions.httpsCallable('deleteUser');

      await deleteUserFunction.call(<String, dynamic>{
        'uid': uid,
      });

      // Delete from Realtime Database
      await _database.ref('${FarmPayload.usersPath}/$uid').remove();

      print('[AUTH_SERVICE] User $uid deleted from Auth and Database by admin');
    } on FirebaseFunctionsException catch (e) {
      print('[AUTH_SERVICE] Cloud Function error: ${e.message}');
      print('[AUTH_SERVICE] Code: ${e.code}');
      throw Exception('خطأ في حذف المستخدم: ${e.message}');
    } catch (e) {
      print('[AUTH_SERVICE] Error deleting user $uid: $e');
      rethrow;
    }
  }

  Future<void> _ensureUserRecord({
    required User user,
    required bool isAdmin,
  }) async {
    await _database.ref('${FarmPayload.usersPath}/${user.uid}').set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': isAdmin ? 'admin' : 'user',
      'status': isAdmin ? 'approved' : 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> _isFirstUser() async {
    final snapshot = await _database.ref(FarmPayload.usersPath).get();
    if (!snapshot.exists) return true;
    final value = snapshot.value;
    if (value is Map) return value.isEmpty;
    return false;
  }

  Future<List<AuthUser>> getAllUsers() async {
    final snapshot = await _database.ref(FarmPayload.usersPath).get();
    if (!snapshot.exists) return [];

    final Map<dynamic, dynamic> usersMap = snapshot.value as Map;
    final List<AuthUser> users = [];

    usersMap.forEach((key, value) {
      final data = value as Map;
      users.add(
        AuthUser(
          uid: data['uid'] ?? '',
          email: data['email'] ?? '',
          displayName: data['displayName'],
          role: data['role'] ?? 'user',
          status: data['status'] ?? 'pending',
        ),
      );
    });

    return users;
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'كلمة المرور المقدمة ضعيفة جدًا.';
      case 'email-already-in-use':
        return 'يوجد حساب بالفعل لهذا البريد الإلكتروني.';
      case 'invalid-email':
        return 'عنوان البريد الإلكتروني غير صالح.';
      case 'user-disabled':
        return 'تم تعطيل حساب المستخدم.';
      case 'user-not-found':
        return 'لم يتم العثور على مستخدم بهذا البريد الإلكتروني.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'كلمة المرور الحالية التي أدخلتها غير صحيحة.';
      case 'internal-error':
        return 'فشل المصادقة. يرجى التحقق من كلمة المرور الحالية.';
      default:
        return e.message ?? 'حدث خطأ';
    }
  }
}
