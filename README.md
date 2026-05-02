# 📱 Smart Receipt & Warranty Manager

> Smart Consumer Warranty Tracking System - Production-ready mobile application for digitizing receipts, tracking warranties, and managing product returns.

## 🎯 Project Overview

Smart Receipt & Warranty Manager is a full-stack mobile application that:
- ✅ Digitizes paper and PDF receipts using OCR (AWS Textract)
- ✅ Extracts structured purchase information (per-line-item)
- ✅ Tracks warranty and return deadlines at the per-item level
- ✅ Product image lookup via Brave Search Image API
- ✅ LLM-based OCR cleanup via AWS Bedrock (Claude Haiku)
- ✅ Push notification reminders (FCM)
- ✅ Claim-ready PDF document generation
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
- **Background Jobs:** APScheduler
- **Container:** Docker + Docker Compose

### Mobile
- **Framework:** Flutter
- **State Management:** Riverpod
- **Local Database:** Drift/SQLite (offline-first)
- **Authentication:** Firebase Auth SDK
- **Notifications:** Firebase Cloud Messaging
- **Image Search:** Brave Search Image API (via backend)
- **HTTP Client:** Dio

### Cloud Services
- **Authentication:** Firebase Authentication
- **OCR:** AWS Textract
- **Storage:** AWS S3
- **LLM:** AWS Bedrock — Claude Haiku
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
API docs: `http://localhost:8000/docs` (accessible in DEBUG mode only)

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

## 🧪 Testing

### Backend Tests
Run all tests with a single command:
```bash
cd backend && pytest
```

To run tests with coverage:
```bash
cd backend && pytest --cov=app tests/
```

### Mobile Tests
Run all tests:
```bash
cd mobile && flutter test
```

---

## 🔁 CI/CD and Deployment

- CI/CD runbook: `docs/CI_CD.md`
- Workflow file: `.github/workflows/ci-cd.yml`
- OCI production compose: `deploy/docker-compose.prod.yml`
- OCI deployment script: `deploy/scripts/oci_deploy.sh`

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
- **Swagger UI:** http://localhost:8000/docs (accessible in DEBUG mode only)
- **ReDoc:** http://localhost:8000/redoc (accessible in DEBUG mode only)

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
| Flutter Settings Screen (UI) | ✅ Complete |
| Vault Tab | ✅ Complete |
| Settings Persistence | ✅ Complete |
| Reminder System (APScheduler) | ✅ Complete |
| Push Notifications (FCM) | ✅ Complete |
| PDF Generation | ✅ Complete |
| Real AWS Integration | ✅ Complete |
| Social Login (Google/Apple) | ⏳ Google present, Apple hidden |
| Error Tracking (Sentry) | ⏳ Planned |

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
- [x] Settings screen
- [x] Multi-step add receipt flow (upload → review → confirm)
- [x] OCR result polling & review/edit form
- [x] Image capture & compression
- [x] `ProductViewModel` + `ProductImageCard` widget

### Phase 4: Vault, Stats & Notifications ✅
- [x] Vault tab — full receipt list with search/filter
- [x] Settings persistence — wired to backend
- [x] APScheduler background jobs
- [x] Firebase Cloud Messaging integration
- [x] Warranty expiry reminders
- [x] Return deadline reminders
- [ ] Social login (Apple Sign-In)

### Phase 5: Production ✅
- [x] CI/CD pipeline for backend and mobile quality gates
- [x] Automated backend image publish and OCI deployment workflow
- [x] Real AWS Textract & S3 integration
- [x] Claim PDF generation
- [x] Comprehensive testing (coverage ≥ 70%)
- [x] Security hardening
- [ ] Error tracking (Sentry)
- [ ] Monitoring & logging
