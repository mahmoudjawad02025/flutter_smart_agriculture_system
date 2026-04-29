## Firebase Authentication Setup Guide

To complete the sign-up and authentication system setup, you need to create a default admin user in Firebase. Here's what you need to do:

### Step 1: Enable Firebase Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **smart_cucumber_agriculture_system**
3. Navigate to **Build → Authentication**
4. Click **Get started** if not already enabled
5. Under **Sign-in method**, enable **Email/Password** provider

### Step 2: Create Default Admin User

After enabling Email/Password auth, you have two options:

#### **Option A: Create Admin User via Firebase Console (Recommended)**

1. In Firebase Console, go to **Authentication → Users**
2. Click **Add user** button
3. Fill in the form:
   - **Email**: `admin@agriculture.local`
   - **Password**: `admin`
   - Check "**Autogenerate password**" if you want a stronger password (then update login page)
4. Click **Add user**
5. Copy the **User ID (UID)** 

#### **Option B: Create Admin User via App (First Use)**

1. Run the app
2. Go to Sign-up page (click "Don't have an account?" on login)
3. Create account with:
   - **Name**: Admin
   - **Email**: `admin@agriculture.local`
   - **Password**: `admin`
4. This will automatically create the user in Firebase

### Step 3: Set User Role (Optional but Recommended)

To identify the admin user, set the role in Firebase Realtime Database:

1. Go to **Realtime Database**
2. Navigate to path: `users/{USER_UID}/role`
3. Change value from `user` to `admin`

**Example path**: `users/abc123xyz/role` → set value to `admin`

### Step 4: Test the Flow

1. **First Login**: Use the default credentials shown on login page:
   - Email: `admin@agriculture.local`
   - Password: `admin`

2. **Sign Up**: Create additional users by clicking "Don't have an account?"

3. **Change Profile**: Go to Settings → Edit Profile to update name and email

4. **Change Password**: Go to Settings → Change Password

### Firebase Security Rules

The app uses standard Firebase Auth. Update your Realtime Database security rules to protect user data:

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

Replace `$uid` with the authenticated user's UID.

### Troubleshooting

- **Email already exists**: If you get "email already in use" error, either use a different email or delete the existing user from Firebase Console
- **Password too weak**: Passwords must be at least 6 characters
- **Email verification**: The app currently doesn't require email verification, but you can add it later
- **Reauthentication**: When changing password, the user must be logged in (they are after sign-up)

### Key Files

- **Auth UI**: `lib/features/auth/ui/` (login, sign-up pages)
- **Auth Service**: `lib/features/auth/services/auth_service.dart`  
- **Auth Cubit**: `lib/features/auth/cubit/auth_cubit.dart`
- **Settings with Profile**: `lib/features/settings/ui/settings_page.dart`
- **Auth State Wrapper**: `lib/features/auth/ui/auth_wrapper.dart`

### Next Steps (Optional)

1. **Customize credentials**: Change `admin@agriculture.local` to `admin@yourdomain.com` in [login_page.dart](../../features/auth/ui/login_page.dart)
2. **Add role-based access control**: Modify the Cubit to check user role
3. **Add email verification**: Use `verifyBeforeUpdateEmail()` in AuthService
4. **Add password reset**: Implement forgot password flow
5. **Persist settings**: Save toggle preferences from Settings page to Firebase or SharedPreferences
