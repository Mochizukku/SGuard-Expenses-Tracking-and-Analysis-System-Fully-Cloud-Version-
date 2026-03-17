# FastAPI Gateway Setup Guide

## Architecture Overview

Your app now uses **FastAPI as a gateway** to Firestore:

```
┌─────────────────┐
│   Flutter App   │ (No ClientException errors)
└────────┬────────┘
         │ HTTP calls
         ▼
┌─────────────────┐
│  FastAPI Server │ (Handles Firestore errors)
└────────┬────────┘
         │ SDK calls
         ▼
┌─────────────────┐
│   Firestore DB  │ (Secure, credentials on backend)
└─────────────────┘
```

## Benefits

✅ **No ClientException errors** - FastAPI handles all errors  
✅ **Secure credentials** - Firebase credentials stay on backend  
✅ **Centralized logic** - Business logic on one server  
✅ **Easy error handling** - HTTP errors instead of SDK errors  
✅ **Better control** - Can add auth, rate limiting, logging  

---

## Quick Start

### Option A: Use FastAPI Gateway (RECOMMENDED)

**1. Set up FastAPI backend** (separate project)

```bash
# Create a new directory for FastAPI
mkdir fastapi-backend
cd fastapi-backend

# Copy code from: FASTAPI_BACKEND_REFERENCE.md
# main.py contains the complete FastAPI server code
```

**2. Install dependencies**

```bash
pip install fastapi uvicorn firebase-admin python-multipart
```

**3. Get Firebase service account key**

- Go to Firebase Console → Project Settings → Service Accounts
- Click "Generate New Private Key"
- Save as `serviceAccountKey.json` in your FastAPI project

**4. Run FastAPI server**

```bash
python main.py
# Server runs at http://localhost:8000
```

**5. Flutter app automatically uses it**

Just run your Flutter app - it will call `http://127.0.0.1:8000/api` endpoints

✅ Done! No ClientException errors!

---

### Option B: Use Direct Firestore (Not Recommended)

If you don't want to set up FastAPI, use direct Firestore instead:

**In `lib/data/repositories/repository_provider.dart`:**

Change:
```dart
const bool USE_HTTP_GATEWAY = true;
```

To:
```dart
const bool USE_HTTP_GATEWAY = false;
```

⚠️ Note: You might still get ClientException errors with direct Firestore

---

## FastAPI Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/users` | Save user |
| GET | `/api/users/{userId}` | Get user |
| PUT | `/api/users/{userId}/balance` | Update balance |
| POST | `/api/users/{userId}/expenses` | Add expense |
| GET | `/api/users/{userId}/expenses` | Get all expenses |
| GET | `/api/users/{userId}/expenses/{id}` | Get expense |
| PUT | `/api/users/{userId}/expenses/{id}` | Update expense |
| DELETE | `/api/users/{userId}/expenses/{id}` | Delete expense |
| GET | `/api/users/{userId}/expenses/by-category/{cat}` | By category |
| GET | `/api/users/{userId}/expenses/by-date-range?start=...&end=...` | By date |
| GET | `/api/profile-summary/{userId}` | Profile stats |
| GET | `/api/health` | Health check |

---

## Deployment Options

### Development (Local)
```
FastAPI: http://localhost:8000
```

### Production (Choose one)

**Google Cloud Run** (Recommended)
```bash
gcloud run deploy fastapi-server --source .
```

**AWS Lambda** with Zappa
```bash
pip install zappa
zappa init
zappa deploy production
```

**Heroku**
```bash
git push heroku main
```

**DigitalOcean App Platform**
- Deploy as web service
- Copy `main.py` to repository

### Update Flutter for Production

In `lib/data/services/fastapi_gateway.dart`:

```dart
static const baseUrl = 'https://your-fastapi-server.com/api';
```

---

## Testing

### Check if FastAPI is running

```dart
// In your Flutter app
final gateway = FastApiGateway();
final isHealthy = await gateway.healthCheck();
print('FastAPI is ${isHealthy ? 'online' : 'offline'}');
```

### Test endpoints manually

```bash
# Health check
curl http://localhost:8000/api/health

# Get user (replace with real userId)
curl http://localhost:8000/api/users/user123

# Add expense
curl -X POST http://localhost:8000/api/users/user123/expenses \
  -H "Content-Type: application/json" \
  -d '{"userId":"user123","category":"Food","amount":25.50,"description":"Lunch","date":"2026-03-17T10:00:00Z"}'
```

---

## Troubleshooting

**Error: "Connection refused"**
```
→ FastAPI server not running
→ Run: python main.py
→ Check port 8000 is available
```

**Error: "Service account key not found"**
```
→ serviceAccountKey.json missing
→ Download from Firebase Console
→ Put in FastAPI project root
```

**Error: "Permission denied" in Firestore**
```
→ Update Firestore security rules
→ See FIRESTORE_INTEGRATION_GUIDE.md
```

**Error: "404 Not Found"**
```
→ Wrong endpoint URL
→ Check FastApiGateway.baseUrl
→ Verify FastAPI routes
```

**No real-time updates**
```
→ HTTP uses polling (5 second intervals)
→ Not true real-time like Firestore
→ For real-time, use direct Firestore instead
```

---

## Comparison: Direct Firestore vs FastAPI Gateway

| Feature | Direct Firestore | FastAPI Gateway |
|---------|-----------------|-----------------|
| Setup complexity | Simple | Medium |
| ClientException errors | Yes | No |
| Real-time updates | Yes (WebSocket) | No (polling 5s) |
| Error handling | SDK errors | HTTP errors |
| Firestore rules | Must be strict | More flexible |
| Backend logic | None | Can add |
| Credentials exposure | On device | Backend only |
| Cost | SDK bandwidth | API requests |

---

## Files Created

```
lib/
├── data/
│   ├── dataresources/
│   │   ├── firestore_datasource.dart    (Direct Firestore)
│   │   └── http_datasource.dart ← NEW (FastAPI calls)
│   ├── repositories/
│   │   ├── expense_repository_impl.dart
│   │   ├── expense_http_repository_impl.dart ← NEW
│   │   ├── user_repository_impl.dart
│   │   ├── user_http_repository_impl.dart ← NEW
│   │   └── repository_provider.dart ← UPDATED (uses HTTP by default)
│   └── services/
│       └── fastapi_gateway.dart ← UPDATED (all endpoints)
```

---

## Next Steps

1. ✅ Set up FastAPI backend (use FASTAPI_BACKEND_REFERENCE.md)
2. ✅ Start FastAPI server (`python main.py`)
3. ✅ Run Flutter app (`flutter run`)
4. ✅ Flutter automatically calls FastAPI
5. ✅ No more ClientException errors!

---

## Support

If you need help:
- Check endpoint in `FastApiGateway` class
- Check server logs: `python main.py` output
- Check Firestore rules in Firebase Console
- Check network tab in browser DevTools
