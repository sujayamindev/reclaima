# 📱 Smart Receipt & Warranty Manager

> Smart Consumer Warranty Tracking System - Production-ready mobile application for digitizing receipts, tracking warranties, and managing product returns.

## 🎯 Project Overview

Smart Receipt & Warranty Manager is a full-stack mobile application that:
- ✅ Digitizes paper and PDF receipts using OCR (AWS Textract)
- ✅ Extracts structured purchase information (per-line-item)
- ✅ Tracks warranty and return deadlines at the per-item level
- ✅ Product image lookup via Brave Search Image API
- ✅ LLM-based OCR cleanup via AWS Bedrock (Claude Haiku)
- ⏳ Push notification reminders (FCM — planned)
- ⏳ Claim-ready PDF document generation (planned)
- ✅ Offline-first mobile architecture (Drift/SQLite)

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
- **Migrations:** Alembic (5 migrations)
- **Authentication:** Firebase Admin SDK (JWT verification)
- **LLM:** AWS Bedrock (Claude Haiku) — OCR text cleanup
- **Background Jobs:** APScheduler (planned)
- **Container:** Docker + Docker Compose

### Mobile
- **Framework:** Flutter
- **State Management:** Riverpod
- **Local Database:** Drift/SQLite (offline-first)
- **Authentication:** Firebase Auth SDK
- **Notifications:** Firebase Cloud Messaging (planned)
- **Image Search:** Brave Search Image API (via backend)
- **HTTP Client:** Dio

### Cloud Services
- **Authentication:** Firebase Authentication
- **OCR:** AWS Textract (mock + real)
- **Storage:** AWS S3 (mock + real)
- **LLM:** AWS Bedrock — Claude Haiku (mock + real)
- **Notifications:** Firebase Cloud Messaging (planned)

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
│   │   │   ├── claim_document.py
│   │   │   └── notification_preference.py
│   │   ├── schemas/         # Pydantic schemas (__init__.py)
│   │   ├── services/        # Business logic layer
│   │   │   ├── s3_service.py
│   │   │   ├── textract_service.py
│   │   │   ├── llm_service.py        # Bedrock/Claude Haiku
│   │   │   ├── product_image_service.py  # Brave Search
│   │   │   ├── receipt_service.py
│   │   │   └── user_service.py
│   │   └── api/v1/          # Versioned API routes
│   │       ├── auth.py
│   │       ├── receipts.py
│   │       ├── warranties.py
│   │       ├── products.py
│   │       └── health.py
│   ├── alembic/             # Database migrations (5 applied)
│   ├── tests/               # Pytest tests
│   ├── requirements.txt
│   └── Dockerfile
│
├── mobile/                   # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/            # Constants, theme, utils
│   │   ├── data/
│   │   │   ├── models/      # Dart data models (+ .g.dart)
│   │   │   └── database/    # Drift local database
│   │   ├── providers/       # Riverpod providers
│   │   ├── services/        # API & auth services
│   │   ├── screens/
│   │   │   ├── main_shell.dart   # Bottom nav (4 tabs)
│   │   │   ├── auth/             # login_screen, signup_screen
│   │   │   ├── home/             # home_screen (redesigned)
│   │   │   ├── receipt/          # add / review / confirmation / product_detail
│   │   │   └── settings/         # settings_screen
│   │   └── widgets/         # step_progress_bar, product_image_card
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
| Database Models + 5 Migrations | ✅ Complete |
| Authentication (Email/Password) | ✅ Complete |
| Receipt Upload & OCR (Mock + Real) | ✅ Complete |
| Extended OCR Fields (vendor, line items) | ✅ Complete |
| Per-Line-Item Warranty & Return Tracking | ✅ Complete |
| LLM OCR Cleanup (Bedrock/Claude Haiku) | ✅ Complete |
| Product Image Search (Brave Search) | ✅ Complete |
| Flutter Bottom Nav Shell | ✅ Complete |
| Flutter Auth Screens (Email/Password) | ✅ Complete |
| Flutter Multi-Step Add Receipt Flow | ✅ Complete |
| Flutter Home Screen (Redesigned) | ✅ Complete |
| Flutter Product Detail Screen | ✅ Complete |
| Flutter Settings Screen (UI) | ✅ UI only (no persistence) |
| Social Login (Google/Apple) | ⏳ Buttons present, not wired |
| Vault Tab | ⏳ Stub |
| Stats Tab | ⏳ Stub |
| Settings Persistence | ⏳ Planned |
| Reminder System (APScheduler) | ⏳ Planned |
| Push Notifications (FCM) | ⏳ Planned |
| PDF Generation | ⏳ Planned |
| Real AWS Integration | ⏳ Planned |

---

## 🗓️ Roadmap

### Phase 1: Core Backend ✅
- [x] Project structure setup
- [x] Database models and migrations (5 applied)
- [x] Authentication with Firebase
- [x] Receipt CRUD operations
- [x] Mock AWS services (S3 + Textract)

### Phase 2: OCR & Processing ✅
- [x] Extended OCR field extraction (invoice no., vendor details, line items)
- [x] S3 file upload
- [x] OCR result parsing and structured field storage
- [x] Per-line-item warranty/return date calculation
- [x] LLM-based OCR cleanup (Bedrock/Claude Haiku)
- [x] Product image lookup (Brave Search Image API)
- [x] `POST /receipts/ocr-extract` — stateless OCR extract endpoint
- [x] `GET /receipts/{id}/image-url` — pre-signed S3 URL endpoint

### Phase 3: Mobile App ✅
- [x] Flutter project initialization
- [x] Offline-first architecture (Drift/SQLite)
- [x] Bottom nav shell with 4 tabs (`main_shell.dart`)
- [x] Redesigned home screen (attention required, stats, recent receipts)
- [x] Product detail screen
- [x] Settings screen (UI only)
- [x] Multi-step add receipt flow (upload → review → confirm)
- [x] OCR result polling & review/edit form
- [x] Image capture & compression
- [x] `ProductViewModel` + `ProductImageCard` widget

### Phase 4: Vault, Stats & Notifications
- [ ] Vault tab — full receipt list with search/filter
- [ ] Stats tab — spend charts, warranty calendar
- [ ] Settings persistence — wire to backend
- [ ] Social login (Google/Apple Sign-In)
- [ ] APScheduler background jobs
- [ ] Firebase Cloud Messaging integration
- [ ] Warranty expiry reminders
- [ ] Return deadline reminders

### Phase 5: Production
- [ ] Real AWS Textract & S3 integration
- [ ] Claim PDF generation
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

**Last Updated:** 2026-03-17
**Status:** ✅ Home screen, product detail, and settings UI complete — Next: Vault tab, Stats tab, Social Login, Settings persistence
