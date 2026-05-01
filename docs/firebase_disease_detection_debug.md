# Firebase Disease Detection - Debugging Guide

## 🔍 Console Logging

Now the app prints detailed logs to the console. When you analyze an image, look for these in the **Debug Console** (in VS Code's Terminal or Logcat in Android Studio):

```
[ANALYZE_IMAGE] Starting image analysis...
[ANALYZE_IMAGE] Calling Roboflow API...
[ANALYZE_IMAGE] API returned successfully: [Downy_Mildew]
[ANALYZE_IMAGE] Updating Firebase leaf status...
[DISEASE_DETECTION] Detected labels: [Downy_Mildew]
[DISEASE_DETECTION] Is healthy: false
[DISEASE_DETECTION] Updating Firebase with:
[DISEASE_DETECTION]   status: Downy_Mildew
[DISEASE_DETECTION]   needs_fix: true
[DISEASE_DETECTION]   reupload_at: 2025-04-23T14:30:00.000Z
[DISEASE_DETECTION] Firebase update successful!
[ANALYZE_IMAGE] Firebase update completed!
[ANALYZE_IMAGE] Analysis completed successfully!
```

### If Firebase update FAILS, you'll see:
```
[ANALYZE_IMAGE] Firebase update FAILED: [Error details]
```

---

## 🔐 Common Firebase Issues

### Issue 1: Permission Denied
**Symptom**: Console shows `Permission denied` error

**Cause**: Firestore/RTDB security rules blocking writes

**Solution**: Check your Firebase database rules in Firebase Console
```
Database Rules should allow write to `smart_cucumber_agriculture/data/leaf`:

{
  "rules": {
    "smart_cucumber_agriculture": {
      "data": {
        "leaf": {
          ".write": true  // Allow writes (develop mode)
        }
      }
    }
  }
}
```

### Issue 2: Path Not Found
**Symptom**: Console shows path error

**Cause**: Firebase structure doesn't exist yet

**Solution**: Ensure your Firebase has the structure:
```
smart_cucumber_agriculture/
  └── data/
      └── leaf/
          ├── status
          ├── needs_fix
          ├── reupload_at
          └── last_updated
```

**How to Create**: Use the "Firebase" tab in the app → click "Write Sample Data" button

### Issue 3: Network Timeout
**Symptom**: Firebase call hangs or times out

**Cause**: No internet connection or Firebase not initialized

**Solution**:
- Verify Firebase initialization completed
- Check device has internet
- Check Firebase project credentials in `firebase_options.dart`

---

## 🧪 Testing Steps

### Step 1: Verify Firebase is Connected
Go to **Firebase** tab → Click "Get Data" → Should show live data

### Step 2: Analyze a Cucumber Image
1. Go to **AI Detection** tab
2. Click upload image
3. Click analyze
4. **Watch the console** for logs

### Step 3: Check Dashboard
After analysis, go to **Dashboard** → Should see:
- `Leaf status: Downy_Mildew` (or disease name)
- Chip showing "Needs Fix" (in red) instead of "Good" (in green)

### Step 4: Verify in Firebase Console
Go to Firebase Console → Realtime Database → Check `smart_cucumber_agriculture/data/leaf`:
```json
{
  "leaf": {
    "needs_fix": true,
    "reupload_at": "2025-04-23T14:30:00.000Z",
    "status": "Downy_Mildew",
    "last_updated": "2025-04-21T10:15:30.000Z"
  }
}
```

---

## ⚙️ Control Behavior with Config

Edit `lib/core/config/app_runtime_config.dart`:

```dart
class AppRuntimeConfig {
  // Days until next upload when disease detected (default: 2 days)
  static const int diseaseReuploadDelayDays = 2;  // Change to 3, 7, etc
  
  // What labels count as "healthy" (all detected labels must match these keywords)
  static const List<String> healthyKeywords = <String>[
    'healthy',  // Add more: 'green', 'normal', 'good'
  ];
  
  // Optional: whitelist of confirmed diseases (if empty, any non-healthy = disease)
  static const List<String> confirmedDiseaseLabels = <String>[];
  
  // Enable debug logging
  static const bool enableDebugLogging = true;
}
```

### Examples:

**Example 1**: Make reupload interval 7 days
```dart
static const int diseaseReuploadDelayDays = 7;
```

**Example 2**: Only accept "healthy" and "green" as healthy
```dart
static const List<String> healthyKeywords = <String>[
  'healthy',
  'green',
];
```

**Example 3**: Whitelist specific diseases to track
```dart
static const List<String> confirmedDiseaseLabels = <String>[
  'downy_mildew',
  'powdery_mildew',
  'leaf_spot',
];
```

---

## 📊 Firebase Data Flow

```
Image Upload
    ↓
Roboflow API (detect disease)
    ↓
[ANALYZE_IMAGE] API returned: [labels]
    ↓
Check if healthy (using healthyKeywords config)
    ↓
Build Firebase update:
  - status: disease name or "Healthy"
  - needs_fix: boolean (true if diseased)
  - reupload_at: ISO8601 timestamp
    ↓
Write to Firebase: smart_cucumber_agriculture/data/leaf
    ↓
[DISEASE_DETECTION] Firebase update successful!
    ↓
Dashboard StreamBuilder listens to Firebase
    ↓
Dashboard updates to show: "Leaf status: Downy_Mildew" + "Needs Fix" chip
```

---

## 🛠️ Troubleshooting Checklist

- [ ] Firebase is initialized in `main.dart`
- [ ] Firebase Console has `smart_cucumber_agriculture` database
- [ ] Security rules allow write to `smart_cucumber_agriculture/data/leaf`
- [ ] Sample data structure exists (use "Write Sample Data" button)
- [ ] Check Debug Console for `[DISEASE_DETECTION]` logs
- [ ] Verify internet connection on device/emulator
- [ ] Try uploading a known cucumber disease image (not generic photo)
- [ ] Check reupload delay isn't too long (default 2 days)

---

## 📱 How to View Logs

### **Android Studio**
- Run app → Open Logcat (bottom panel)
- Filter by `[DISEASE_DETECTION]` or `[ANALYZE_IMAGE]`

### **VS Code Terminal**
- Run `flutter run` in terminal
- Logs print automatically when analyzing

### **Visual Studio (Mac)**
- Run app → View Console Output
- Filter by `DISEASE_DETECTION`

---

## 🔄 Real-Time Updates

The dashboard **automatically updates** when Firebase changes:
- Analysis completes → Firebase updated → Dashboard refreshes (1-2 seconds)
- No manual refresh needed
- If Firebase update fails, dashboard stays on old data until next successful update

---

**Status**: ✅ Debug logging enabled  
**Config File**: `lib/core/config/app_runtime_config.dart`  
**Logs Prefix**: `[DISEASE_DETECTION]` and `[ANALYZE_IMAGE]`  
