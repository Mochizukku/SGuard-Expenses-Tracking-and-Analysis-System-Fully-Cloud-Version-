# FastAPI Backend Setup & Troubleshooting

## Quick Start

### 1. Find Your Computer's Local IP

**Windows (PowerShell or CMD):**
```powershell
ipconfig
```

Look for **IPv4 Address** under your active network:
```
Ethernet adapter Ethernet:
   IPv4 Address. . . . . . . . . . : 192.168.1.100
   Subnet Mask . . . . . . . . . . : 255.255.255.0
```

**Common IP ranges:**
- `192.168.x.x` - Most home/office networks
- `10.0.x.x` - Corporate networks
- `172.16.x.x - 172.31.x.x` - Docker/VM networks

### 2. Configure Flutter App

Edit: `lib/config/api_config.dart`

```dart
static const String devComputerIp = '192.168.1.100'; // Replace with YOUR IP
```

### 3. Ensure Backend is Running

```powershell
cd backend
python main.py
```

**Expected output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete
```

### 4. Test Connection from Phone

From phone's browser, visit:
```
http://192.168.1.100:8000/docs
```

If you see FastAPI Swagger docs, connection is working! ✅

---

## Troubleshooting

### Problem: "Unable to reach FastAPI gateway..."

**Checklist:**

1. **Backend Running?**
   ```powershell
   # In backend folder
   python main.py
   
   # Should see: "Uvicorn running on http://0.0.0.0:8000"
   ```

2. **Correct IP in Config?**
   - Run `ipconfig` on your computer
   - Update `lib/config/api_config.dart` with the IPv4 address
   - Make sure you're copying the right IP (not 127.0.0.1)

3. **Same Network?**
   - Phone must be on same WiFi as computer
   - Check: Settings → WiFi on both devices
   - They should show the same network name

4. **Firewall Blocking?**
   - Windows Firewall might block port 8000
   - **Add exception:**
     1. Windows Defender Firewall → Allow an app through firewall
     2. Click "Allow another app"
     3. Browse to python.exe (in your Python installation)
     4. Add for both Private and Public networks

5. **UDP vs TCP?**
   - FastAPI uses TCP port 8000 (not UDP)
   - Ensure your firewall allows TCP traffic

### Problem: "500 Internal Server Error"

**Check backend logs for errors:**

```powershell
cd backend
python main.py
# Watch for error messages in the terminal
```

**Common causes:**

1. **Missing `serviceAccountKey.json`**
   ```powershell
   # Verify file exists
   ls backend/serviceAccountKey.json
   ```
   - If missing, download from Firebase Console → Project Settings → Service Accounts

2. **Firebase Credentials Invalid**
   ```python
   # In backend/main.py, check:
   cred = credentials.Certificate("serviceAccountKey.json")
   firebase_admin.initialize_app(cred)
   ```

3. **Firestore Security Rules Rejecting Request**
   - See [FIRESTORE_INTEGRATION_GUIDE.md](FIRESTORE_INTEGRATION_GUIDE.md)
   - Verify rules allow your authenticated user's operations

### Problem: Localhost Works on Computer but Not Phone

**This is expected!** Localhost (127.0.0.1) only works on the same machine.

**Solution:** Use computer's local network IP instead.

```dart
// WRONG - Only works on the computer running the backend
static const String devComputerIp = '127.0.0.1';

// CORRECT - Works from phone on same network
static const String devComputerIp = '192.168.1.100';
```

### Problem: Data Not Syncing to Cloud

1. **Check Firestore Rules:**
   - Go to Firebase Console → Firestore → Rules
   - Verify rules allow your user to read/write (see FIRESTORE_INTEGRATION_GUIDE.md)

2. **Check Cloud Sync Status:**
   - In app: Settings → Account → Look for sync messages
   - Watch for "Cloud sync is unavailable..." banner

3. **Verify Backend Connects to Firestore:**
   ```python
   # Test in backend/main.py
   from firebase_admin import firestore
   db = firestore.client()
   print(db)  # Should print firestore client instance
   ```

---

## Environment-Based Configuration

For production deployments, modify `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Development: Point to computer
  static const bool isDevelopment = true;  // Set to false for production
  
  // Your computer's IP (only used if isDevelopment = true)
  static const String devComputerIp = '192.168.1.100';
  
  // Production URL (used if isDevelopment = false)
  static const String productionUrl = 'https://your-live-api.com/api';
}
```

**Run with different modes:**
```powershell
# Development (local computer)
flutter run

# Production (would require changing isDevelopment = false)
flutter run --release
```

---

## Testing Endpoints

Once connected, test individual endpoints:

**1. Health Check (No Auth Required)**
```bash
curl "http://192.168.1.100:8000/api/health" \
  -H "Content-Type: application/json"
```

**2. Get User (Requires Valid UID)**
```bash
curl "http://192.168.1.100:8000/api/users/YOUR_UID" \
  -H "Content-Type: application/json"
```

**3. API Documentation**
Visit in browser: `http://192.168.1.100:8000/docs`
- Interactive API explorer
- Try endpoints directly
- See request/response examples

---

## Network Debugging

**Check if phone can reach computer:**

From phone's browser:
```
http://192.168.1.100:8000/docs
```

**From computer, verify port is open:**
```powershell
# Windows
netstat -ano | findstr :8000

# Should show something like:
# TCP    0.0.0.0:8000    0.0.0.0:0    LISTENING    12345
```

**Restart network if issues persist:**
```powershell
# Windows
ipconfig /release
ipconfig /renew
```

---

## Production Deployment

When ready to deploy:

1. **Deploy Backend** to cloud (AWS, Heroku, GCP, etc.)
2. **Update Production URL** in `api_config.dart`
3. **Change `isDevelopment` to false**
4. **Update Firestore Rules** for production domain
5. **Test on real device** before releasing to Play Store

---

## Support

If issues persist:

1. Check Flutter doctor: `flutter doctor`
2. Check network with: `ping 192.168.1.100`
3. View app logs: `flutter logs`
4. Check backend logs in terminal where `python main.py` is running
