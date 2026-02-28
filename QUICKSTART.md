# 🚀 Quick Start Guide

## Prerequisites Installed?
- [ ] Python 3.11+
- [ ] Docker & Docker Compose
- [ ] PostgreSQL (optional if using Docker)

---

## 🏃 Quick Start (Development Mode)

### Option 1: Docker Compose (Recommended)

```bash
# Start all services (PostgreSQL + FastAPI)
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down
```

**API will be available at:** http://localhost:8000
**API Docs:** http://localhost:8000/docs

---

### Option 2: Local Development (Without Docker)

#### 1. Setup Python Environment
```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

#### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

#### 3. Configure Environment
```bash
# Copy .env.example to .env (already done)
# Edit .env if needed
```

#### 4. Start PostgreSQL (if not using Docker)
```bash
# Windows (using Docker):
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=smart_receipt_db \
  -p 5432:5432 \
  postgres:15-alpine
```

#### 5. Run Database Migrations
```bash
cd backend
alembic upgrade head
```

#### 6. Start FastAPI Server
```bash
uvicorn app.main:app --reload
```

---

## 🔧 Firebase Setup (Required for Authentication)

### Step 1: Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Follow setup wizard

### Step 2: Enable Authentication
1. In Firebase Console → Authentication
2. Click "Get Started"
3. Enable "Email/Password" provider

### Step 3: Generate Service Account Key
1. Go to Project Settings → Service Accounts
2. Click "Generate new private key"
3. Save file as `backend/firebase-service-account.json`
4. **NEVER commit this file to git** (already in .gitignore)

---

## 📝 Create First Migration

```bash
cd backend

# Auto-generate migration from models
alembic revision --autogenerate -m "initial migration"

# Apply migration
alembic upgrade head
```

---

## 🧪 Test the API

### Health Check
```bash
curl http://localhost:8000/api/v1/health
```

### View API Documentation
Open browser: http://localhost:8000/docs

---

## 🐛 Troubleshooting

### Database Connection Error
- Check PostgreSQL is running: `docker ps`
- Verify DATABASE_URL in `.env`

### Firebase Error
- Ensure `firebase-service-account.json` exists
- Verify Firebase project is active

### Import Errors
- Activate virtual environment: `venv\Scripts\activate`
- Reinstall dependencies: `pip install -r requirements.txt`

### Port Already in Use
```bash
# Windows - Kill process on port 8000
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Or change port in docker-compose.yml or uvicorn command
```

---

## 📚 Next Steps

1. ✅ Backend is running with mock AWS services
2. ✅ Flutter mobile app is implemented (core feature-complete)
3. ⏳ Add Firebase config files (`google-services.json` / `GoogleService-Info.plist`) and test auth end-to-end
4. ⏳ Configure real AWS S3 & Textract (set `USE_MOCK_AWS=false`)
5. ⏳ **Enable AWS Bedrock for AI warranty-text cleanup** (see below)
6. ⏳ Implement push notifications via Firebase Cloud Messaging
7. ⏳ Deploy to production environment

### Enabling AWS Bedrock (Claude Haiku OCR text cleanup)

When `USE_MOCK_AWS=false`, the backend uses AWS Bedrock to clean up
garbled warranty/notes text extracted from multi-column receipt layouts.

**One-time AWS setup:**
1. Open the [AWS Bedrock console](https://console.aws.amazon.com/bedrock/home)
   → **Model access** → request access to **Anthropic Claude 3 Haiku**
   (`anthropic.claude-3-haiku-20240307-v1:0`).
2. Add the following permissions to your IAM user/role policy:
   ```json
   {
     "Effect": "Allow",
     "Action": ["bedrock:InvokeModel"],
     "Resource": "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
   }
   ```
3. *(Optional)* Override the model or disable cleanup in `.env`:
   ```
   BEDROCK_MODEL_ID=anthropic.claude-3-haiku-20240307-v1:0
   LLM_CLEANUP_ENABLED=true
   ```
   Set `LLM_CLEANUP_ENABLED=false` to skip Bedrock if access is not yet
   provisioned — geometric column reconstruction still runs.

---

## 🔑 Important Notes

- **Mock Mode:** AWS services are mocked by default (USE_MOCK_AWS=true)
- **Firebase:** Required for authentication to work
- **Debug Mode:** Enabled by default (DEBUG=true)
- **Secret Key:** Change in production!

---

## 📱 Mobile App Quick Start

### 1. Install Flutter Dependencies
```bash
cd mobile
flutter pub get
```

### 2. Add Firebase Config Files
- **Android:** `mobile/android/app/google-services.json`
- **iOS:** `mobile/ios/Runner/GoogleService-Info.plist`

Download both from your Firebase Console → Project Settings → Your apps.

### 3. Update API Endpoint (if needed)
Edit `mobile/lib/core/constants/app_constants.dart`:
- Android emulator: `http://10.0.2.2:8000/api/v1` (default)
- iOS simulator: `http://localhost:8000/api/v1`
- Physical device: Use your computer's LAN IP (e.g. `http://192.168.1.x:8000/api/v1`)

### 4. Run the App
```bash
flutter run
```

---

**Happy Coding! 🎉**
