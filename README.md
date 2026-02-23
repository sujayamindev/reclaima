# 📱 Smart Receipt & Warranty Manager

> Smart Consumer Warranty Tracking System - Production-ready mobile application for digitizing receipts, tracking warranties, and managing product returns.

## 🎯 Project Overview

Smart Receipt & Warranty Manager is a full-stack mobile application that:
- ✅ Digitizes paper and PDF receipts using OCR (AWS Textract)
- ✅ Extracts structured purchase information
- ✅ Tracks warranty and return deadlines
- ✅ Sends proactive reminders via push notifications
- ✅ Generates claim-ready PDF documents
- ✅ Provides offline-first mobile experience

---

## 🏗️ Architecture

**Type:** Modular Monolith (Cloud-Hosted) → Microservices-ready

```
Flutter Mobile App (Offline-first)
        ↓
Firebase Authentication
        ↓
FastAPI Backend (Dockerized)
        ↓
---------------------------------------------
| PostgreSQL | AWS S3 | AWS Textract | FCM |
---------------------------------------------
```

---

## 🛠️ Technology Stack

### Backend
- **Framework:** FastAPI (Python 3.11+)
- **Database:** PostgreSQL + SQLAlchemy ORM
- **Migrations:** Alembic
- **Authentication:** Firebase Admin SDK (JWT verification)
- **Background Jobs:** APScheduler
- **Container:** Docker + Docker Compose

### Mobile
- **Framework:** Flutter
- **State Management:** Riverpod
- **Local Database:** Drift (offline-first)
- **Authentication:** Firebase Auth SDK
- **Notifications:** Firebase Cloud Messaging (FCM)
- **Image Compression:** flutter_image_compress
- **HTTP Client:** Dio

### Cloud Services
- **Authentication:** Firebase Authentication
- **OCR:** AWS Textract
- **Storage:** AWS S3
- **Notifications:** Firebase Cloud Messaging

---

## 📂 Project Structure

```
smart-receipt-and-warranty-manager/
├── backend/                  # FastAPI backend
│   ├── app/
│   │   ├── main.py          # FastAPI application entry
│   │   ├── core/            # Core configuration & security
│   │   ├── db/              # Database session & base
│   │   ├── models/          # SQLAlchemy models
│   │   │   ├── user.py
│   │   │   ├── receipt.py
│   │   │   ├── receipt_line_item.py
│   │   │   └── claim_document.py
│   │   ├── schemas/         # Pydantic schemas (__init__.py)
│   │   ├── services/        # Business logic layer
│   │   └── api/v1/          # Versioned API routes
│   │       ├── auth.py
│   │       ├── receipts.py
│   │       ├── warranties.py
│   │       └── health.py
│   ├── alembic/             # Database migrations
│   ├── tests/               # Pytest tests
│   ├── requirements.txt
│   └── Dockerfile
│
├── mobile/                   # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/            # Constants, theme, utils
│   │   ├── data/
│   │   │   ├── models/      # Dart data models
│   │   │   └── database/    # Drift local database
│   │   ├── providers/       # Riverpod providers
│   │   ├── services/        # API & auth services
│   │   ├── screens/         # UI screens
│   │   │   ├── auth/        # Login screen
│   │   │   ├── home/        # Receipt list
│   │   │   └── receipt/     # Add / Review / Confirm / Detail
│   │   └── widgets/         # Reusable widgets
│   ├── test/
│   └── pubspec.yaml
│
├── docker-compose.yml        # Docker orchestration
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- Python 3.11+
- Docker & Docker Compose
- Flutter SDK (3.0+)
- PostgreSQL (via Docker)
- Firebase Account
- AWS Account (for S3 & Textract)

### Backend Setup

1. **Navigate to backend directory:**
```bash
cd backend
```

2. **Create virtual environment:**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. **Install dependencies:**
```bash
pip install -r requirements.txt
```

4. **Configure environment variables:**
```bash
cp .env.example .env
# Edit .env with your configuration
```

5. **Start services with Docker:**
```bash
cd ..
docker-compose up -d
```

6. **Run database migrations:**
```bash
cd backend
alembic upgrade head
```

7. **Start FastAPI development server:**
```bash
uvicorn app.main:app --reload
```

API will be available at: `http://localhost:8000`
API docs: `http://localhost:8000/docs`

### Mobile App Setup

1. **Navigate to mobile directory:**
```bash
cd mobile
```

2. **Install Flutter dependencies:**
```bash
flutter pub get
```

3. **Configure Firebase:**
- Create Firebase project at https://console.firebase.google.com
- Download `google-services.json` (Android) and place in `android/app/`
- Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`
- Enable Authentication (Email/Password)
- Enable Cloud Messaging

4. **Run the app:**
```bash
flutter run
```

---

## 🔧 Configuration

### Backend Environment Variables (.env)

```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/smart_receipt_db

# Firebase
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json

# AWS (Mock mode for development)
AWS_ACCESS_KEY_ID=mock_access_key
AWS_SECRET_ACCESS_KEY=mock_secret_key
AWS_REGION=us-east-1
AWS_S3_BUCKET=smart-receipt-storage
USE_MOCK_AWS=true

# Application
SECRET_KEY=your-secret-key-here
DEBUG=true
ALLOWED_ORIGINS=http://localhost:8000,http://localhost:3000

# Scheduler
ENABLE_SCHEDULER=true
```

### Firebase Setup

1. Create a Firebase project
2. Enable Authentication (Email/Password provider)
3. Enable Cloud Messaging
4. Download service account JSON:
   - Go to Project Settings → Service Accounts
   - Generate new private key
   - Save as `backend/firebase-service-account.json`

### AWS Setup (Production)

1. Create S3 bucket: `smart-receipt-storage`
2. Enable S3 encryption (SSE-S3)
3. Enable versioning
4. Create IAM user with:
   - S3 read/write permissions
   - Textract read permissions
5. Generate access keys
6. Update `.env` with real credentials
7. Set `USE_MOCK_AWS=false`

---

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest
pytest --cov=app tests/
```

### Mobile Tests
```bash
cd mobile
flutter test
```

---

## 🐳 Docker Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild containers
docker-compose up -d --build

# View running containers
docker-compose ps
```

---

## 📊 Database Migrations

```bash
# Create new migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# View migration history
alembic history
```

---

## 🔐 Security Notes

- ✅ Never commit `.env` files
- ✅ Never commit Firebase service account JSON
- ✅ Never commit AWS credentials
- ✅ Use pre-signed URLs for S3 uploads
- ✅ Validate JWT tokens on every request
- ✅ Enable HTTPS in production
- ✅ Implement rate limiting
- ✅ Sanitize all user inputs

---

## 📖 API Documentation

Once the backend is running, visit:
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

---

## 🎯 Development Status

| Feature | Status |
|---------|--------|
| Backend API Structure | ✅ Complete |
| Database Models | ✅ Complete |
| Authentication | ✅ Complete |
| Receipt Upload & OCR (Mock) | ✅ Complete |
| Extended OCR Fields (vendor, line items) | ✅ Complete |
| Warranty & Return Tracking | ✅ Complete |
| Flutter App (Core) | ✅ Complete |
| Flutter Multi-Step Add Flow | ✅ Complete |
| OCR Polling & Review Screen | ✅ Complete |
| Reminder System (APScheduler) | ⏳ Pending |
| Push Notifications (FCM) | ⏳ Pending |
| Real AWS Integration | ⏳ Pending |
| PDF Generation | ⏳ Pending |

---

## 🗓️ Roadmap

### Phase 1: Core Backend ✅
- [x] Project structure setup
- [x] Database models and migrations
- [x] Authentication with Firebase
- [x] Receipt CRUD operations
- [x] Mock AWS services (S3 + Textract)

### Phase 2: OCR & Processing ✅
- [x] Extended OCR field extraction (invoice no., vendor details, line items)
- [x] S3 file upload
- [x] OCR result parsing and structured field storage
- [x] Warranty/return date calculation

### Phase 3: Mobile App ✅
- [x] Flutter project initialization
- [x] Offline-first architecture (Drift)
- [x] Receipt list & detail screens
- [x] Multi-step add receipt flow (upload → review → confirm)
- [x] OCR result polling & review/edit form
- [x] Image capture & compression

### Phase 4: Reminders & Notifications
- [ ] APScheduler background jobs
- [ ] Firebase Cloud Messaging integration
- [ ] Warranty expiry reminders
- [ ] Return deadline reminders

### Phase 5: Production
- [ ] Real AWS Textract & S3 integration
- [ ] Comprehensive testing (coverage ≥ 70%)
- [ ] Error tracking (Sentry)
- [ ] Monitoring & logging
- [ ] Deployment configuration
- [ ] Security hardening

---

## 📝 License

This project is proprietary and confidential.

---

## 👥 Team

**Project Type:** Production-ready mobile application
**Timeline:** 7-day prototype → Production deployment
**Architecture:** Modular Monolith → Microservices-ready

---

## 📞 Support

For questions or issues, please contact the development team.

---

**Built with ❤️ using FastAPI, Flutter, Firebase, and AWS**

---

**Last Updated:** 2026-02-23  
**Status:** ✅ Backend + Flutter Core Complete — Next: Notifications & Real AWS Integration
