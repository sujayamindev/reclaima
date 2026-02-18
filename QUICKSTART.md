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
2. ⏳ Set up Flutter mobile app (coming next)
3. ⏳ Configure real AWS S3 & Textract (when ready)
4. ⏳ Deploy to production environment

---

## 🔑 Important Notes

- **Mock Mode:** AWS services are mocked by default (USE_MOCK_AWS=true)
- **Firebase:** Required for authentication to work
- **Debug Mode:** Enabled by default (DEBUG=true)
- **Secret Key:** Change in production!

---

**Happy Coding! 🎉**
