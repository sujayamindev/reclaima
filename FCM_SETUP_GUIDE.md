# Firebase Cloud Messaging (FCM) Setup & Deployment Guide
## Smart Receipt & Warranty Manager - Production Ready

---

## SECTION 1: FIREBASE PROJECT SETUP

### Step 1.1: Create/Access Firebase Project
1. Go to https://console.firebase.google.com
2. Create new project or select existing: "smart-receipt-manager"
3. Enable Google Analytics (optional but recommended)

### Step 1.2: Enable Required Services
In Firebase Console, enable:
- ✓ Cloud Messaging (Project Settings → Cloud Messaging tab)
- ✓ Authentication (already enabled for Firebase Auth)
- ✓ Cloud Storage (for receipts - already configured)

### Step 1.3: Get Service Account Key
1. Firebase Console → Project Settings → Service Accounts tab
2. Click "Generate New Private Key"
3. Save as: `backend/firebase-service-account.json`
4. Keep this file SECURE - it's in .gitignore

---

## SECTION 2: BACKEND CONFIGURATION

### Step 2.1: Environment Variables (.env)
Add to `backend/.env`:

```env
# Firebase Admin SDK
FIREBASE_CREDENTIALS_PATH=firebase-service-account.json
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key

# FCM Configuration
FCM_SERVER_KEY=automatic  # Loaded from service account
ENABLE_FCM=true

# Scheduler Settings
ENABLE_SCHEDULER=true
REMINDER_CHECK_HOUR=9    # 9 AM UTC daily
CLEANUP_HOUR=2           # 2 AM UTC daily
```

### Step 2.2: Backend Code (Already Implemented ✓)
File: `backend/app/services/notification_service.py`

✓ NotificationService class with FCM integration
✓ send_notification() method for push delivery
✓ send_warranty_reminders() job (daily at 9 AM)
✓ send_return_reminders() job (daily at 9:05 AM)
✓ Quiet hours filtering
✓ Error handling & logging

### Step 2.3: Initialize Firebase Admin SDK
In `backend/app/services/notification_service.py` (lines 1-40):

```python
import firebase_admin
from firebase_admin import credentials, messaging
from app.core.config import settings

# Initialize Firebase (runs once on import)
if not firebase_admin.get_app(None):
    cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(cred, {
        'projectId': settings.FIREBASE_PROJECT_ID,
    })
```

Status: ✓ Already implemented in the code

---

## SECTION 3: MOBILE (FLUTTER) CONFIGURATION

### Step 3.1: Google Services Configuration

**Android:**
1. Firebase Console → Project Settings → General tab
2. Download "google-services.json"
3. Place at: `mobile/android/app/google-services.json`
4. Already referenced in: `mobile/android/app/build.gradle.kts`

**iOS:**
1. Firebase Console → Project Settings → General tab
2. Download "GoogleService-Info.plist"
3. Place at: `mobile/ios/Runner/GoogleService-Info.plist`
4. Add to Xcode Build Phases

### Step 3.2: pubspec.yaml Dependencies (Already Added ✓)
File: `mobile/pubspec.yaml`

```yaml
dependencies:
  firebase_messaging: ^14.0.0
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.1.0
```

### Step 3.3: Dart Code (Already Implemented ✓)
Files implemented:
- `mobile/lib/services/notification_service.dart`
- `mobile/lib/providers/notification_provider.dart`
- `mobile/lib/screens/settings/settings_screen.dart`

### Step 3.4: Request Notification Permissions

**Android 13+:**
File: `mobile/android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

**iOS 10+:**
File: `mobile/ios/Runner/Info.plist`
Already properly configured with NSUserNotificationUsageDescription

### Step 3.5: Setup Build Configuration
- Android: `mobile/android/build.gradle.kts` (Firebase plugin configured)
- iOS: `mobile/ios/Podfile` (Firebase dependencies included)

---

## SECTION 4: DEPLOYMENT & TESTING

### Step 4.1: Deploy Backend with FCM

On cloud VM:

```bash
# 1. Place firebase-service-account.json
scp firebase-service-account.json arm-vm:/mnt/data/smart-receipt-and-warranty-manager/backend/

# 2. SSH to VM and update .env
ssh arm-vm
cd /mnt/data/smart-receipt-and-warranty-manager
# Edit backend/.env with:
#   FIREBASE_CREDENTIALS_PATH=/app/firebase-service-account.json
#   FIREBASE_PROJECT_ID=your-project-id
#   ENABLE_FCM=true

# 3. Rebuild Docker
docker compose down
docker compose up -d

# 4. Verify initialization
docker compose logs backend | grep -i firebase
```

Expected output:
```
INFO: Firebase Admin SDK initialized successfully
INFO: APScheduler started — reminder jobs at 09:00 UTC
```

### Step 4.2: Test Backend FCM Setup

```bash
curl -X GET http://localhost:8000/api/v1/health

# Response should show:
# {
#   "status": "healthy",
#   "firebase": "initialized",
#   "database": "healthy"
# }
```

### Step 4.3: Deploy Mobile App

**Android Build:**
```bash
cd mobile
flutter build apk --release

# Or for testing:
flutter run
```

**iOS Build:**
```bash
cd mobile
flutter build ios --release

# Or for testing:
flutter run
```

### Step 4.4: Test FCM Token Registration

1. Run app on device
2. Authenticate with Firebase
3. Check logs:

**Android:**
```bash
adb logcat | grep -i "fcm\|messaging"
```

**iOS:**
Xcode Console → filter "firebase"

Expected:
```
FCM token received: eB8zE0J9Q_M:APA91bE5k9...
FCM token registered with backend
```

---

## SECTION 5: FIREBASE CONSOLE TESTING

### Step 5.1: Send Test Notification

1. Firebase Console → Messaging → New Campaign
2. Create Cloud Messaging campaign
3. Compose notification:
   - Title: "Test Warranty Reminder"
   - Body: "Your warranty expires in 30 days"

4. Target → Conditions:
   - Select by app package → smartreceiptmanager

5. Schedule: Send Now
6. Check device - notification should arrive

### Step 5.2: Monitor Delivery

1. Firebase Console → Messaging → All Campaigns
2. Click recent campaign
3. View metrics:
   - Sent count
   - Delivery rate
   - Engagement rate

---

## SECTION 6: TESTING WITH CURL + JWT

### Step 6.1: Get Firebase JWT Token

From Flutter app authentication or Firebase CLI:

```bash
firebase auth:signInWithEmailAndPassword(email, password)
```

### Step 6.2: Register FCM Token

```bash
curl -X PATCH http://localhost:8000/api/v1/notifications/fcm-token \
  -H "Authorization: Bearer $FIREBASE_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "eB8zE0J9Q_M:APA91bE5k9..._your_fcm_token"
  }'
```

Expected: **204 No Content**

### Step 6.3: Get User Preferences

```bash
curl -X GET http://localhost:8000/api/v1/notifications/preferences \
  -H "Authorization: Bearer $FIREBASE_JWT"
```

Expected: **200 OK** with preferences JSON

### Step 6.4: Update Preferences

```bash
curl -X PATCH http://localhost:8000/api/v1/notifications/preferences \
  -H "Authorization: Bearer $FIREBASE_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "warranty_reminders_enabled": true,
    "warranty_lead_days": 14,
    "quiet_hours_start": 22,
    "quiet_hours_end": 8
  }'
```

Expected: **200 OK** with updated preferences

---

## SECTION 7: PRODUCTION DEPLOYMENT CHECKLIST

### Setup:
- [ ] Create Firebase project (console.firebase.google.com)
- [ ] Download service account key
- [ ] Download google-services.json (Android)
- [ ] Download GoogleService-Info.plist (iOS)

### Backend Deployment:
- [ ] Place firebase-service-account.json in backend/
- [ ] Update backend/.env with Firebase credentials
- [ ] `docker compose down && docker compose up -d`
- [ ] Verify Firebase initialized: `curl http://localhost:8000/api/v1/health`

### Mobile Deployment:
- [ ] Place google-services.json in mobile/android/app/
- [ ] Place GoogleService-Info.plist in mobile/ios/Runner/
- [ ] `flutter pub get`
- [ ] `flutter run` (test on device)

### Testing:
- [ ] App authenticates with Firebase
- [ ] FCM token appears in console logs
- [ ] Register FCM token via API
- [ ] Update preferences via Settings screen
- [ ] Send test notification from Firebase Console
- [ ] Verify notification appears on device

---

## SECTION 8: TROUBLESHOOTING

### Issue: Firebase credentials not loading
**Solution:**
- Check FIREBASE_CREDENTIALS_PATH in .env
- Verify file permissions: `chmod 644 firebase-service-account.json`
- Check file path is correct and file exists

### Issue: Notifications not received on device
**Solution:**
- Verify app has notification permissions granted
- Check FCM token is registered (backend logs)
- Ensure user has reminders enabled in settings
- Check quiet hours not blocking notification

### Issue: APScheduler jobs not running
**Solution:**
- Check ENABLE_SCHEDULER=true in .env
- Verify backend container logs: `docker compose logs backend`
- Ensure database is healthy: `curl http://localhost:8000/api/v1/health`

### Issue: 403 Unauthorized on protected endpoints
**Solution:**
- Verify FIREBASE_JWT token is valid
- Check Authorization header format: `Bearer <token>`
- Token must not be expired
- Firebase must be properly initialized

---

## NEXT STEPS

1. **Get Firebase Credentials**
   - Visit Firebase Console and download required files

2. **Configure Backend**
   - Place firebase-service-account.json in backend/
   - Update .env with credentials

3. **Deploy to Cloud VM**
   - Copy credentials to VM
   - Rebuild Docker containers

4. **Configure Mobile**
   - Place google-services.json and GoogleService-Info.plist
   - Run `flutter pub get`

5. **Test End-to-End**
   - Run app on device
   - Verify FCM token registration
   - Send test notification from Firebase Console

---

## Documentation Links

- Firebase Cloud Messaging: https://firebase.google.com/docs/cloud-messaging
- Firebase Admin SDK (Python): https://firebase.google.com/docs/admin/setup
- Flutter Firebase Messaging: https://pub.dev/packages/firebase_messaging
- Firebase Authentication: https://firebase.google.com/docs/auth

