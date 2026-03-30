# Mobile Testing Setup Guide - SGuard Android Phone

## Overview
This guide helps you test the SGuard app on an Android phone. Four issues have been fixed, and one requires manual configuration.

---

## ✅ Issues Fixed (Auto-Deployed)

### 1. **Login Form Keyboard Overflow**
- **Issue**: "Bottom overflowed by 33 pixels" when typing in login form
- **Fix**: Added `resizeToAvoidBottomInset: true` to Scaffold
- **Status**: ✅ DONE

### 2. **Bottom Navigation Blocking System Nav Bar**
- **Issue**: 3-4 bottom icons blocking Android system navigation/back buttons
- **Fix**: Added `MediaQuery.of(context).padding.bottom` to bottom nav padding
- **Status**: ✅ DONE

### 3. **Navigation UX (Swipe & Exit Flow)**
- **Issue**: Hard to navigate back from profile page using swipe gestures
- **Fixes**: 
  - Added drawer menu with quick navigation to all pages
  - Added "Sign Out" option in drawer
  - Can now swipe from left edge or tap menu icon to access drawer
- **Status**: ✅ DONE

### 4. **PDF Export (Save to Device)**
- **Issue**: PDF only allowed sharing, not saving to device downloads
- **Fixes**:
  - Added `path_provider` package
  - Created `saveToDownloads()` method in `RecordExportService`
  - Updated UI with two buttons: "Save to Downloads" (green) and "Share PDF" (blue)
- **Permissions Added**: 
  - `WRITE_EXTERNAL_STORAGE`
  - `READ_EXTERNAL_STORAGE`
  - `MANAGE_EXTERNAL_STORAGE` (Android 11+)
- **Status**: ✅ DONE

---

## ⚠️ FastAPI Backend Issue (Manual Configuration Required)

### 5. **FastAPI 500 Error + Localhost Unreachable**

#### **Problem**
- Phone can't reach `127.0.0.1:8000` (localhost only works on computer)
- Backend returns 500 Internal Server Error

#### **Solution: Update FastAPI Gateway URL**

Your phone needs your **computer's local network IP**, not localhost.

**Step 1: Find Your Computer's Local IP**

On Windows (PowerShell or CMD):
```powershell
ipconfig
```

Look for **IPv4 Address** under your active network adapter (e.g., Ethernet or WiFi):
```
Ethernet adapter Ethernet:
   IPv4 Address. . . . . . . . . . : 192.168.1.100
```

**Step 2: Update Flutter App**

Edit: `lib/data/services/fastapi_gateway.dart`

Find (around line 14):
```dart
static const baseUrl = 'http://127.0.0.1:8000/api';
```

Replace with your computer's IP (example uses `192.168.1.100`):
```dart
static const baseUrl = 'http://192.168.1.100:8000/api';
```

**Step 3: Verify Backend is Accessible**

Ensure:
1. FastAPI backend is running: `python main.py` in `backend/` folder
2. Backend listens on all interfaces (check `main.py` for `0.0.0.0:8000`)
3. Computer and phone are on **same network** (same WiFi)
4. Firewall allows port 8000

**Step 4: Test Connection**

From phone's browser, visit:
```
http://192.168.1.100:8000/api/docs
```

If you see FastAPI docs, connection works! ✅

#### **Debug Backend 500 Error**

If backend still returns 500 errors, check:

1. **Backend logs**: Look for error messages in terminal
2. **Firebase credentials**: Verify `serviceAccountKey.json` path is correct
3. **Firestore rules**: Ensure security rules allow the operations
4. **Python dependencies**: Run `pip install -r requirements.txt`

---

## 📱 Testing Workflow

### 1. Start Backend
```powershell
cd backend
python main.py
```

### 2. Update FastAPI URL
- Edit `lib/data/services/fastapi_gateway.dart`
- Change localhost to your computer's IP

### 3. Run Flutter App on Phone
```powershell
flutter run
```

### 4. Test Each Feature

| Feature | Test Case |
|---------|-----------|
| **Login** | Type in email field → keyboard should not overflow |
| **Navigation** | Swipe from left edge → drawer appears with all pages |
| **Bottom Nav** | Open app → system back button should be visible |
| **PDF Export** | Profile → Record Export → Save to Downloads button should work |
| **Cloud Sync** | Record spending → should sync to Firestore (if rules fixed) |

---

## 🔧 Configuration Checklist

- [ ] Computer's IPv4 address noted
- [ ] `fastapi_gateway.dart` updated with computer IP
- [ ] Backend (`main.py`) running successfully
- [ ] Phone on same network as computer
- [ ] Firewall allows port 8000
- [ ] Firestore security rules updated (see FIRESTORE_INTEGRATION_GUIDE.md)
- [ ] `flutter pub get` run to fetch new `path_provider` package

---

## 📝 For Future: Environment Configuration

After testing, add environment-based configuration:

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String isDev = bool.fromEnvironment('DEV', defaultValue: true);
  
  static String get baseUrl {
    if (isDev) {
      return 'http://192.168.1.100:8000/api'; // Your computer IP
    }
    return 'https://your-production-url.com/api';
  }
}
```

Run with: `flutter run -d android --dart-define=DEV=true`

---

## ✅ Deployment Ready

Once all is working, the app is ready for:
- Testing on multiple Android devices
- Publishing to Google Play Store
- Deploying backend to cloud (AWS, Heroku, etc.)
