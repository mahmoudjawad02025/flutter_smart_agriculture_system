# Manual Firebase Configuration Checklist

## ✅ Complete This Before Running the App

### 1. Firebase Authentication Setup

- [ ] Go to [Firebase Console](https://console.firebase.google.com/)
- [ ] Select project: **smart_cucumber_agriculture_system**
- [ ] Navigate to: **Build → Authentication**
- [ ] Click: **Get started** (if not already enabled)
- [ ] Enable: **Email/Password** sign-in method
- [ ] Status should show: ✅ Enabled

### 2. Create Default Admin User

**Method A: Via Firebase Console (Recommended)**
- [ ] In Firebase Console → **Authentication → Users**
- [ ] Click: **Add user** button
- [ ] Enter:
  - [ ] Email: `admin@agriculture.local`
  - [ ] Password: `admin` (or your preferred password)
- [ ] Click: **Add user**
- [ ] Copy and save the **User UID** shown in the list

**Method B: Via App (First Time)**
- [ ] Run the app
- [ ] Click: **"Don't have an account?"** on login page
- [ ] Create account with credentials above
- [ ] Account automatically added to Firebase

### 3. Verify User Data in Database

After creating the admin user:
- [ ] Go to: **Realtime Database** in Firebase Console
- [ ] Navigate to: `users/{USER_UID}` (replace with actual UID)
- [ ] You should see:
  ```json
  {
    "uid": "abc123xyz",
    "email": "admin@agriculture.local",
    "displayName": "Admin",
    "photoUrl": null,
    "role": "user",
    "createdAt": "2025-04-21T10:30:00.000Z"
  }
  ```

### 4. Optional: Set Admin Role

For future role-based features:
- [ ] Go to: **Realtime Database** → `users/{USER_UID}/role`
- [ ] Change value from: `"user"` to: `"admin"`

### 5. Firebase Security Rules

Set proper security rules to protect user data:

**Location**: Firebase Console → **Realtime Database → Rules**

**Paste this**:
```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth.uid === $uid",
        ".write": "auth.uid === $uid"
      }
    },
    "smart_cucumber_agriculture": {
      "$uid": {
        ".read": "auth.uid === $uid",
        ".write": "auth.uid === $uid"
      }
    }
  }
}
```

- [ ] Click: **Publish**
- [ ] Confirm changes

### 6. Test the Setup

- [ ] Run app: `flutter run`
- [ ] Login page should appear with pre-filled credentials
- [ ] Click: **Login** with `admin@agriculture.local` / `admin`
- [ ] Should navigate to Dashboard
- [ ] Go to: **Settings** tab
- [ ] Should see profile card with admin name
- [ ] Test: **Edit Profile** → Change name
- [ ] Test: **Change Password** → Update password
- [ ] Test: **Logout** → Return to login page

---

## Optional Configuration

### Customize Admin Credentials (if not using defaults)

If you want different default credentials:

**File**: `lib/features/auth/ui/login_page.dart`

**Find** (around line 27):
```dart
_emailController.text = 'admin@agriculture.local';
_passwordController.text = 'admin';
```

**Replace with** your credentials:
```dart
_emailController.text = 'your-email@domain.com';
_passwordController.text = 'your-password';
```

### Also Update the Info Box

**Find** (around line 309):
```dart
Text(
  'Email: admin@agriculture.local\nPassword: admin',
```

**Replace** with your credentials.

---

## Firebase Paths Reference

All user data is stored in these Firebase Realtime Database paths:

| Feature | Path | Example |
|---------|------|---------|
| User Profile | `users/{uid}` | `users/abc123/` |
| User Email | `users/{uid}/email` | `users/abc123/email` |
| User Name | `users/{uid}/displayName` | `users/abc123/displayName` |
| User Role | `users/{uid}/role` | `users/abc123/role` |
| Notifications | `smart_cucumber_agriculture/{uid}/notifications/` | `smart_cucumber_agriculture/abc123/notifications/` |
| Unread Count | `smart_cucumber_agriculture/{uid}/notifications/unread_count` | `smart_cucumber_agriculture/abc123/notifications/unread_count` |

---

## Troubleshooting

### Issue: "Email already in use"
- [ ] Either use a different email address
- [ ] Or delete the existing user from Firebase Console
- [ ] Then create a new one

### Issue: "This operation is not allowed"
- [ ] Make sure Email/Password provider is enabled in Firebase Console
- [ ] Check that Authentication is enabled for your project

### Issue: "An unknown error occurred"
- [ ] Check internet connection
- [ ] Verify Firebase project is correctly initialized in app
- [ ] Check Firebase Console for project status

### Issue: "Password too weak"
- [ ] Use at least 6 characters
- [ ] Mix of letters, numbers, symbols recommended

### Issue: Password doesn't change in settings
- [ ] User must be logged in (they are after sign-up)
- [ ] Check that Firebase Auth provider is enabled
- [ ] Check internet connection

---

## Values Configured in Code

These are the hard-coded values already set up in the app:

| Value | Location | Current Setting |
|-------|----------|-----------------|
| Default Email | `login_page.dart:27` | `admin@agriculture.local` |
| Default Password | `login_page.dart:28` | `admin` |
| Default User Role | `auth_user.dart:default` | `'user'` |
| Users DB Path | `auth_service.dart` | `users/{uid}` |
| Min Password Length | `sign_up_page.dart` | 6 characters |

---

## Done! ✅

Once you complete the checklist above:
1. App will display login page
2. Use admin credentials to log in
3. Access all features including Settings with profile management
4. New users can sign up via "Don't have an account?" link
5. All data syncs with Firebase in real-time

Need help? See: `FIREBASE_AUTH_SETUP.md` for detailed step-by-step instructions.
