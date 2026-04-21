# Notifications Quick Start

## 🎯 What's New?

Your app now has **real-time notifications** that automatically trigger when a disease is detected:

✅ Shows unread count badge on AppBar  
✅ Displays disease name + next upload date  
✅ Mark notifications as read  
✅ Auto-decreases unread count  
✅ Real-time updates everywhere  

---

## 🚀 Try It Now

### **Step 1: Upload a Diseased Cucumber Image**
1. Open the app
2. Go to **AI Detection** tab
3. Upload an image with a disease (e.g., Downy Mildew)

### **Step 2: Analyze the Image**
1. Click **Analyze**
2. Wait for results
3. Look at the **AppBar notification icon** → Should show red badge with count

### **Step 3: View the Notification Badge**
- Red circle with white number shows in the top-right AppBar
- Badge appears automatically when disease is detected
- Count increases with each new disease

### **Step 4: Mark as Read (Optional)**
1. Click the notification badge in the AppBar
2. Or go to the Notifications page (if added to navigation)
3. Click **Mark Read** on a notification
4. Unread count decreases automatically

---

## 🔍 What Happens Behind the Scenes

```
You upload image with disease
           ↓
Roboflow API detects: "Downy_Mildew"
           ↓
App checks if healthy: NO
           ↓
Creates notification with:
  - Disease name: "Downy_Mildew"
  - Next upload: 2 days from now (configurable)
  - Status: Unread
           ↓
Badge appears showing "1"
           ↓
You can mark as read → Count decreases
```

---

## ⚙️ Configuration

### **Change Disease Reupload Delay**

Edit: `lib/core/config/app_runtime_config.dart`

```dart
// Default: 2 days
static const int diseaseReuploadDelayDays = 2;

// Change to 3, 7, 14, etc.
static const int diseaseReuploadDelayDays = 7;  // 7 days instead
```

---

## 📌 Important Notes

### **Notifications are In-Memory**
- Notifications stay in RAM while app is open
- If you restart the app, in-memory notifications disappear
- (You can add Firebase persistence later if needed)

### **Badge Color Meanings**
- **Red circle with number**: Unread notifications
- **No badge**: 0 unread (or all read)

### **Notification Details**
Each notification shows:
- ⚠️ Disease name (red)
- 📝 Message: "Detected on your cucumber leaf"
- 🕐 Next upload date (e.g., "in 2 days")
- ✅ "Mark Read" action
- 🗑️ "Delete" action

---

## 🎨 UI Locations

### **Notification Badge** (AppBar)
- **Location**: Top-right of AppBar
- **Shows**: Red badge with unread count
- **Action**: Tap to see SnackBar message

### **Notifications Page** (Optional)
- List all notifications
- See full details (disease, date, etc.)
- Mark as read or delete

---

## 🐛 Troubleshooting

### **Badge doesn't appear**
- [ ] Make sure you analyzed a disease (not healthy)
- [ ] Console should show: `[ANALYZE_IMAGE] Notification added for disease: ...`
- [ ] Check the unread count > 0

### **Count doesn't change**
- [ ] Try clicking "Mark Read" to decrease
- [ ] Or "Delete" to remove the notification
- [ ] App should update immediately

### **Notifications disappear after restart**
- This is normal (in-memory storage)
- To make persistent, add Firebase sync
- See `notifications_feature.md` for Firebase setup

---

## 📱 Files You Edited/Added

**New Features:**
- `lib/features/notifications/models/farm_notification.dart` - Data model
- `lib/features/notifications/cubit/notifications_cubit.dart` - State management
- `lib/features/notifications/cubit/notifications_state.dart` - State class
- `lib/features/notifications/services/notifications_service.dart` - Firebase sync
- `lib/features/notifications/ui/notifications_page.dart` - UI + Badge widget

**Modified:**
- `lib/main.dart` - Added NotificationsCubit provider
- `lib/features/app_shell/ui/app_shell_page.dart` - Added NotificationBadge
- `lib/features/disease_detection/cubit/disease_detection_cubit.dart` - Calls addNotification()
- `lib/features/firebase_data/models/farm_payload.dart` - Added notifications structure
- `pubspec.yaml` - Added uuid package

---

## 🔗 Related Docs

- [Notifications Feature Complete Guide](notifications_feature.md)
- [Disease Detection Debug Guide](firebase_disease_detection_debug.md)
- [Null Safety Handling](null_safety_handling.md)

---

**Ready to test?** Upload a disease image and watch the badge appear! 🎉
