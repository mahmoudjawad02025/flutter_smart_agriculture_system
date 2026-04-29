# Code Reference Guide - Authentication Features

Quick reference for all authentication-related code locations and key methods.

## 🔑 Key Files by Feature

### Login Feature
**File**: `lib/features/auth/ui/login_page.dart`

Key locations:
- Line 27-28: Default admin credentials (email & password)
- Line 51: Show/hide password toggle
- Line 86-105: Login button and error handling
- Line 309-312: Info box showing default credentials

Key methods:
- `_handleLogin()` - Validates and submits login
- `_showSnackBar()` - Shows error messages

### Sign-Up Feature
**File**: `lib/features/auth/ui/sign_up_page.dart`

Key locations:
- Line 61-75: Form validation logic
- Line 83-100: Sign-up button and error handling
- Line 34-44: Password matching validation
- Line 45-49: Password length validation

Key methods:
- `_handleSignUp()` - Validates and submits sign-up
- `_showSnackBar()` - Shows error messages

### Profile Management (Settings)
**File**: `lib/features/settings/ui/settings_page.dart`

Key locations:
- Line 28-99: Profile edit dialog
- Line 101-171: Password change dialog
- Line 173-195: Logout confirmation dialog
- Line 239-291: Profile card display

Key methods:
- `_showProfileDialog()` - Edit name/email
- `_showPasswordDialog()` - Change password
- `_handleLogout()` - Logout confirmation

### Authentication Cubit (State Management)
**File**: `lib/features/auth/cubit/auth_cubit.dart`

Key locations:
- Line 14-22: Constructor with AuthService injection
- Line 24-32: Stream subscription to Firebase auth changes
- Line 34-78: Public methods (signUp, login, logout, updateProfile, changeEmail, changePassword)
- Line 80-85: Cleanup on close

Key methods:
- `signUp()` - Creates new user
- `login()` - Authenticates user
- `logout()` - Signs out user
- `updateProfile()` - Changes display name
- `changeEmail()` - Changes email address
- `changePassword()` - Updates password

### Auth Service (Firebase Operations)
**File**: `lib/features/auth/services/auth_service.dart`

Key locations:
- Line 12-25: Constructor and auth state stream
- Line 27-65: signUp() - Creates user and saves to database
- Line 67-84: login() - Authenticates with Firebase
- Line 86-90: logout() - Signs user out
- Line 92-108: updateProfile() - Updates display name/photo
- Line 110-118: changeEmail() - Updates email
- Line 120-126: changePassword() - Updates password
- Line 138-200: Error handling methods

Key properties:
- `authStateChanges` - Stream of auth state changes

### Auth User Model
**File**: `lib/features/auth/models/auth_user.dart`

Key locations:
- Line 3-18: AuthUser class definition
- Line 20-42: copyWith() method for immutable updates
- Line 44-51: props list for Equatable

### Auth State
**File**: `lib/features/auth/cubit/auth_state.dart`

Key locations:
- Line 6-8: AuthInitial - App starting
- Line 10-12: AuthLoading - Loading authentication
- Line 14-18: AuthAuthenticated - User logged in
- Line 20-22: AuthUnauthenticated - No user
- Line 24-28: AuthError - Authentication failed

### Auth Wrapper (Route Dispatcher)
**File**: `lib/features/auth/ui/auth_wrapper.dart`

Key locations:
- Line 11-59: BlocBuilder with state handling
- Line 13-24: Loading state (shows spinner)
- Line 25-26: Authenticated state (shows AppShellPage)
- Line 27-28: Unauthenticated state (shows LoginPage)
- Line 29-50: Error state (shows error screen)

### Main App Setup
**File**: `lib/main.dart`

Key locations:
- Line 10: firebase_auth import
- Line 13-15: Auth feature imports
- Line 80-88: AuthCubit provider setup
- Line 114: AuthWrapper as root widget

---

## 🔄 Data Flow Diagrams

### Login Flow
```
LoginPage
    ↓ (user enters credentials)
AuthCubit.login(email, password)
    ↓
AuthService.login()
    ↓
FirebaseAuth.signInWithEmailAndPassword()
    ↓
Returns User object
    ↓
AuthCubit emits AuthAuthenticated state
    ↓
AuthWrapper routes to AppShellPage
```

### Sign-Up Flow
```
SignUpPage
    ↓ (user enters name, email, password)
AuthCubit.signUp(email, password, displayName)
    ↓
AuthService.signUp()
    ↓
FirebaseAuth.createUserWithEmailAndPassword()
    ↓
Updates displayName
    ↓
Saves user data to Realtime Database at users/{uid}
    ↓
AuthCubit emits AuthAuthenticated state
    ↓
AuthWrapper routes to AppShellPage
```

### Profile Update Flow
```
SettingsPage (Edit Profile button clicked)
    ↓
_showProfileDialog() opens
    ↓ (user clicks Save)
AuthCubit.updateProfile(displayName)
    ↓
AuthService.updateProfile()
    ↓
User.updateDisplayName()
    ↓
Updates users/{uid} in Realtime Database
    ↓
Firebase stream emits new user data
    ↓
AuthCubit rebuilds with updated profile
    ↓
SettingsPage rebuilds with new avatar/name
```

### Password Change Flow
```
SettingsPage (Change Password button clicked)
    ↓
_showPasswordDialog() opens
    ↓ (user enters new password twice)
Validation: passwords match? min 6 chars?
    ↓
AuthCubit.changePassword(newPassword)
    ↓
AuthService.changePassword()
    ↓
User.updatePassword()
    ↓
Firebase backend updates authentication credentials
    ↓
SnackBar: "Password changed"
    ↓
Dialog closes
```

---

## 📦 Firebase Integration Points

### Firebase Auth Methods Used

```dart
// Creating user
FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: String,
  password: String
)

// Logging in
FirebaseAuth.instance.signInWithEmailAndPassword(
  email: String,
  password: String
)

// Getting current user
FirebaseAuth.instance.currentUser

// Listening to auth changes
FirebaseAuth.instance.authStateChanges()

// Updating profile
User.updateDisplayName(String)
User.updatePhotoURL(String)
User.updatePassword(String)
User.verifyBeforeUpdateEmail(String)

// Signing out
FirebaseAuth.instance.signOut()
```

### Firebase Database Paths

```
users/{uid}/
  ├── uid: String
  ├── email: String
  ├── displayName: String
  ├── photoUrl: String?
  ├── role: String
  └── createdAt: DateTime
```

---

## 🎯 Common Customizations

### Change Default Admin Credentials
**File**: `lib/features/auth/ui/login_page.dart`
```dart
// Line 27-28
_emailController.text = 'admin@agriculture.local';  // CHANGE THIS
_passwordController.text = 'admin';                  // AND THIS
```

### Add Email Validation
**File**: `lib/features/auth/ui/sign_up_page.dart`
```dart
// In _handleSignUp() method, add:
if (!_emailController.text.contains('@')) {
  _showSnackBar('Invalid email address');
  return;
}
```

### Customize Error Messages
**File**: `lib/features/auth/services/auth_service.dart`
```dart
// Lines 138-200 contain all error handling
// Modify switch cases to show different messages
```

### Add Role-Based Features
**File**: `lib/features/auth/models/auth_user.dart`
```dart
// Line 3-18 defines AuthUser
// role property already included:
final String? role; // 'admin', 'user', etc.
```

### Set User Role After Creation
**File**: `lib/features/auth/services/auth_service.dart`
```dart
// In signUp() method after saving user data:
await _database.ref('users/${user.uid}/role').set('admin');
```

---

## 🧪 Testing Scenarios

### Test Scenario 1: Happy Path Sign-Up
1. Open app → See LoginPage
2. Click "Don't have an account?"
3. Fill form: name="John", email="john@test.com", password="Test123"
4. Click "Create Account"
5. Should see: Dashboard
6. Check Firebase: users collection has new document

### Test Scenario 2: Login with Admin
1. See LoginPage with pre-filled credentials
2. Click "Login"
3. Should navigate to Dashboard
4. Close and reopen app
5. Should auto-login (no login page shown)

### Test Scenario 3: Profile Update
1. Login → Dashboard → Settings tab
2. Click "Edit Profile"
3. Change name to "Administrator"
4. Click "Save"
5. Avatar should update
6. Refresh database - name should be updated

### Test Scenario 4: Password Change
1. Login → Settings tab
2. Click "Change Password"
3. Enter new password twice
4. Click "Change"
5. Should see: "Password changed" message
6. Logout
7. Try login with old password - should fail
8. Login with new password - should succeed

### Test Scenario 5: Logout
1. Login → Settings tab
2. Click "Logout" button
3. Click "Logout" in confirmation dialog
4. Should return to LoginPage
5. Previous session should be cleared

---

## 🐛 Debugging Tips

### Enable Debug Logging
**File**: `lib/features/auth/services/auth_service.dart`

Add after any Firebase operation:
```dart
print('Auth operation: $result');  // Logs to console
```

### View Firebase Auth Errors
**File**: `lib/features/auth/services/auth_service.dart`

The `_handleAuthException()` method (line 138-200) converts Firebase errors to readable messages.

### Inspect Firebase Data
1. Go to Firebase Console
2. Select **Realtime Database**
3. Look at `users` node
4. Each user UID has their profile data

### Check Auth State
Add this in any widget:
```dart
@override
Widget build(BuildContext context) {
  return BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) {
      print('Current auth state: $state');  // Logs state changes
      return YourWidget();
    },
  );
}
```

---

## 📚 Related Documentation

- `FIREBASE_AUTH_SETUP.md` - Setup instructions
- `SETUP_CHECKLIST.md` - Quick checklist
- `AUTH_IMPLEMENTATION_SUMMARY.md` - Feature summary
- `README_AUTH.md` - Complete guide

---

**Last Updated**: April 21, 2025  
**Version**: 1.0.0
