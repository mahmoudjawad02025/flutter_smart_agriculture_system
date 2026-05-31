const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * HTTP Callable function to delete a user from Firebase Authentication
 * Only callable by authenticated admin users
 * 
 * Parameters:
 *   - uid (string): The UID of the user to delete
 */
exports.deleteUser = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to call this function'
    );
  }

  const uid = data.uid;

  // Validate UID parameter
  if (!uid || typeof uid !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'UID parameter is required and must be a string'
    );
  }

  try {
    // Check if the caller is an admin
    const callerToken = await admin.auth().verifyIdToken(context.auth.token);
    
    // Get the user to be deleted
    const userToDelete = await admin.auth().getUser(uid);
    
    // Check if caller is admin (you may want to add custom claims for this)
    // For now, we'll rely on your Realtime Database role check
    const callerSnapshot = await admin.database()
      .ref(`/users/${context.auth.uid}`)
      .once('value');
    
    const callerRole = callerSnapshot.val()?.role;

    if (callerRole !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can delete user accounts'
      );
    }

    // Prevent admin from deleting themselves
    if (context.auth.uid === uid) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Cannot delete your own account using this method'
      );
    }

    // Delete the user from Firebase Authentication
    await admin.auth().deleteUser(uid);

    console.log(`User ${uid} (${userToDelete.email}) deleted from Firebase Authentication`);

    return {
      success: true,
      message: `User ${userToDelete.email} has been deleted`,
      uid: uid
    };
  } catch (error) {
    console.error(`Error deleting user ${uid}:`, error);

    if (error.code === 'permission-denied' || error.code === 'invalid-argument') {
      throw error;
    }

    if (error.code === 'auth/user-not-found') {
      throw new functions.https.HttpsError(
        'not-found',
        'User not found'
      );
    }

    throw new functions.https.HttpsError(
      'internal',
      'Error deleting user: ' + error.message
    );
  }
});
