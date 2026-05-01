# Null Safety & Error Handling Guide

## Problem Scenario
When AI analysis fails (bad image quality, no disease detected, or Firebase connection issues), the app needs to:
1. **Not crash** - Show meaningful error to user
2. **Degrade gracefully** - Show analysis results even if Firebase fails
3. **Handle edge cases** - Empty detections, null responses, API timeouts

## Current Implementation

### 1. **Service Layer** (`diagnosis_service.dart`)

#### `analyzeSavedImage()` - API Handling
- Checks if image file exists before sending to Roboflow
- Wraps Dio calls in try-catch for timeout/network errors
- Handles both `Map<String, dynamic>` and generic `Map` responses
- **Error output**: Includes status code and body for debugging

```dart
// Handles case: wrong image, network timeout, API error
response = await _dio.postUri(..., options: Options(
  sendTimeout: const Duration(seconds: 35),
  receiveTimeout: const Duration(seconds: 35),
));
```

#### `updateLeafStatusInFirebase()` - Firebase Handling
- Gracefully handles empty detection labels → "Unknown - Detection Failed"
- Wraps Firebase update in try-catch
- Adds `last_updated` timestamp for audit trail
- **Error output**: Rethrows with clear message

```dart
// Handles case: no disease detected
if (labels.isEmpty) {
  leafStatus = 'Unknown - Detection Failed';
}
```

### 2. **Cubit Layer** (`diagnosis_cubit.dart`)

#### `analyzeImage()` - Composite Error Handling
```dart
try {
  final result = await _aiDetectionService.analyzeSavedImage(imagePath);
  
  // TRY Firebase update separately
  String? firebaseError;
  try {
    await _aiDetectionService.updateLeafStatusInFirebase(result);
  } catch (firebaseErr) {
    // Store error but DON'T FAIL - analysis succeeded
    firebaseError = 'Firebase sync failed (non-critical): $firebaseErr';
  }
  
  // Always emit SUCCESS if analysis worked, even if Firebase failed
  emit(state.copyWith(
    status: AiDetectionStatus.success,
    result: result,
    errorMessage: firebaseError,  // Show warning, not error
  ));
} catch (error) {
  // CRITICAL error: API call failed
  emit(state.copyWith(
    status: AiDetectionStatus.error,
    errorMessage: 'API Analysis failed: $error\n\nTips:\n'
        '• Check image quality\n'
        '• Ensure good lighting\n'
        '• Verify Roboflow API key',
  ));
}
```

**Key Strategy**: Separate analysis failures (critical) from Firebase failures (non-critical)
- ✅ API call fails → Show error UI, don't allow Firebase update
- ✅ API succeeds but Firebase fails → Show result + warning banner
- ✅ Empty detection → Show "Unknown - Detection Failed" + next upload time

### 3. **UI Layer** (`ai_detection_page.dart`)

The UI receives state with:
- `status: AiDetectionStatus.success` - Show analysis result
- `errorMessage: String` - Show warning banner if present
- `result: DetectionResult` - Display detected classes

```dart
// UI shows success result even with warning banner
if (state.status == AiDetectionStatus.success) {
  return _ResultView(result: state.result);
}
```

## Test Scenarios

### ✅ Scenario 1: Good Image, Healthy Leaf
- **Flow**: Upload → Analyze → Success
- **Firebase**: Sets status='Healthy', needs_fix=false, reupload_at=''
- **UI**: Shows "Healthy" with green checkmark

### ✅ Scenario 2: Good Image, Diseased Leaf
- **Flow**: Upload → Analyze → Success
- **Firebase**: Sets status='Disease Name', needs_fix=true, reupload_at='2025-04-23T...'
- **UI**: Shows disease + next upload time in dashboard

### ✅ Scenario 3: Bad Image Quality
- **Flow**: Upload → Analyze → API Error
- **Firebase**: No update (analysis failed)
- **UI**: Shows error with tips "Check image quality, ensure good lighting"

### ✅ Scenario 4: API Success but Firebase Offline
- **Flow**: Upload → Analyze → Success (API) → Firebase fails
- **Firebase**: No update (connection failed)
- **UI**: Shows result + warning banner "Firebase sync failed (non-critical)"
- **User Experience**: Result is still visible, can be reuploaded when Firebase is online

### ✅ Scenario 5: No Disease Detected (Empty Response)
- **Flow**: Upload → Analyze → API returns []
- **Firebase**: Sets status='Unknown - Detection Failed', needs_fix=true
- **UI**: Shows "Unknown - Detection Failed" with next upload reminder

## Key Null Safety Patterns Used

| Pattern | Where | Why |
|---------|-------|-----|
| Fallback values | `leafStatus` logic | Handle empty labels gracefully |
| Separate try-catch | Firebase in Cubit | Allow Firebase failure without blocking analysis result |
| Error message chaining | All layers | Preserve context: API error → Cubit → UI |
| Type checking | `response.data` | Handle API response polymorphism |
| Nested null checks | `imagePath` validation | Prevent false analysis attempts |

## Configuration

Disease reupload delay when not healthy:
```dart
// lib/core/config/app_runtime_config.dart
static const int diseaseReuploadDelayDays = 2;  // Change to 3, 7, etc as needed
```

Health keywords (define what "healthy" means):
```dart
static const List<String> healthyKeywords = ['healthy', 'normal', 'green'];
```

---

**Status**: ✅ All null safety issues handled  
**Last Updated**: April 21, 2025  
**Analyzer**: 0 issues found
