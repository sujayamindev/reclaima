# 📋 Development Checklist

## Backend Setup ✅

### Phase 1: Initial Setup
- [x] Project structure created
- [x] Git repository initialized
- [x] .gitignore configured
- [x] README.md created
- [x] Docker environment configured

### Phase 2: Core Backend
- [x] FastAPI application setup
- [x] Database models (User, Receipt, ReceiptLineItem, ClaimDocument, NotificationPreference)
- [x] Pydantic schemas for validation
- [x] SQLAlchemy ORM configuration
- [x] Alembic migrations — 5 migrations applied
- [x] Database session management

### Phase 3: Authentication & Security
- [x] Firebase Admin SDK integration
- [x] JWT token verification
- [x] Security middleware
- [x] CORS configuration
- [x] Environment variables (.env)

### Phase 4: Business Logic
- [x] User service (CRUD operations)
- [x] Receipt service (CRUD + OCR + line items)
- [x] Mock S3 service + real S3 service
- [x] Mock Textract service + real Textract service
- [x] LLM service (`llm_service.py`) — Bedrock/Claude Haiku OCR cleanup (mock + real)
- [x] Product image service (`product_image_service.py`) — Brave Search image lookup (mock + real)
- [x] Warranty date calculations (per-line-item, server-side with `dateutil.relativedelta`)
- [x] Return date calculations (per-line-item)

### Phase 5: API Routes
- [x] Authentication endpoints (`auth.py`)
- [x] Receipt endpoints (full CRUD + upload + OCR-extract + image-url + retry)
- [x] Line item endpoints (`POST /receipts/{id}/items`, `PATCH /receipts/{id}/items/{id}`)
- [x] Products endpoint (`GET /products/image-search`)
- [x] Warranty & return tracking endpoints
- [x] Health check endpoints
- [ ] `DELETE /receipts/{id}/items/{item_id}` — line item deletion not yet implemented
- [ ] ClaimDocument API endpoints — model exists, no router
- [ ] NotificationPreference API endpoints — model exists, no router

### Phase 6: Docker & Deployment
- [x] Dockerfile created
- [x] docker-compose.yml configured
- [x] PostgreSQL container
- [x] Auto-migrations on startup
- [x] Health checks
- [x] Optional pgAdmin (`--profile tools`)

### Phase 7: Testing & Documentation
- [x] Basic test structure (`tests/test_api.py`)
- [x] API documentation (Swagger — auto-generated)
- [x] README with setup instructions
- [x] QUICKSTART guide
- [x] Implementation status document
- [ ] Comprehensive unit tests
- [ ] Integration tests
- [ ] Coverage ≥ 70%

---

## ✅ Firebase Setup Complete

### Firebase Configuration
- [x] Create Firebase project
- [x] Enable Email/Password authentication
- [x] Download service account JSON
- [x] Place as `backend/firebase-service-account.json`
- [x] Configure `android/app/google-services.json`
- [x] Configure `ios/Runner/GoogleService-Info.plist`

---

## 📱 Flutter Mobile App ✅

### Phase 1: Project Initialization ✅
- [x] `flutter create mobile`
- [x] Configure pubspec.yaml dependencies:
  - [x] flutter_riverpod 2.6.1
  - [x] drift 2.28.2
  - [x] firebase_auth 5.7.0
  - [x] firebase_messaging 15.2.10
  - [x] dio 5.9.1
  - [x] flutter_image_compress 2.4.0
  - [x] image_picker 1.2.1
  - [x] json_annotation & json_serializable
  - [x] logger 2.6.2
  - [x] path_provider 2.1.5
  - [x] uuid 4.5.2
  - [x] cached_network_image
  - [x] google_fonts (Inter)
  - [x] material_symbols_icons
- [x] Folder structure (core/, data/, services/, providers/, screens/, widgets/)

### Phase 2: State Management ✅
- [x] Auth providers: `authStateProvider`, `currentUserProvider`, `userProfileProvider`, `authControllerProvider`
- [x] Display/greeting: `displayNameProvider`, `greetingProvider`
- [x] Receipt providers: `receiptsProvider`, `receiptProvider(id)`, `receiptImageUrlProvider(id)`, `receiptControllerProvider`
- [x] Product providers: `productsProvider`, `productImageServiceProvider`
- [x] Service providers: `serviceProviders.dart` (DI)

### Phase 3: Local Database ✅
- [x] Drift configured
- [x] Tables: Receipts, ReceiptLineItems, UploadQueue
- [x] Schema version 2 with migration from v1
- [x] Code generation run (`build_runner`)
- [ ] UploadQueue actively used by any service — **not yet wired**

### Phase 3b: Data Models ✅
- [x] `user_model.dart` (+ `.g.dart`)
- [x] `receipt_model.dart` (+ `.g.dart`) — full OCR fields; computed getters delegate to first `lineItems` entry
- [x] `receipt_line_item_model.dart` (+ `.g.dart`) — `warrantyDaysRemaining`, `returnDaysRemaining`, `isWarrantyExpired`, `isReturnExpired`, `displayName`, `fromOcrExtract`
- [x] `product_view_model.dart` — wraps `ReceiptModel + ReceiptLineItemModel?`; all display/warranty accessors

### Phase 4: Services ✅
- [x] `api_service.dart` — Dio + Firebase token interceptor
- [x] `auth_service.dart` — Firebase Auth + auto-register backend user
- [x] `receipt_service.dart` — full CRUD, OCR extract, line item create/update
- [x] `product_image_service.dart` — wraps `GET /products/image-search`
- [ ] `UploadService` (background uploads) — not implemented
- [ ] `NotificationService` (FCM) — not implemented

### Phase 5: UI Screens ✅
- [x] `main_shell.dart` — `IndexedStack` bottom nav (Home / Vault stub / Stats stub / Settings)
- [x] `screens/auth/login_screen.dart` — email/password sign in
- [x] `screens/auth/signup_screen.dart` — email/password registration
- [x] `screens/home/home_screen.dart` — **redesigned** 4-section layout (top bar, greeting, stats row, attention required, recent receipts)
- [x] `screens/receipt/add_receipt_screen.dart` — image picker (step 1 of 3)
- [x] `screens/receipt/review_receipt_screen.dart` — OCR polling + full form (step 2 of 3)
- [x] `screens/receipt/receipt_confirmation_screen.dart` — summary + save (step 3 of 3)
- [x] `screens/receipt/product_detail_screen.dart` — full product/warranty detail view
- [x] `screens/settings/settings_screen.dart` — notification toggles, preferences, data section (UI only; local state)
- [ ] Vault screen — stub only (shows text "Vault")
- [ ] Stats screen — stub only (shows text "Stats")
- [ ] Search screen — Search button on home has empty `onTap`
- [ ] Notifications screen — Notifications button on home has empty `onTap`

### Phase 5b: Widgets ✅
- [x] `widgets/step_progress_bar.dart`
- [x] `widgets/product_image_card.dart` — async image with shimmer + fallback

### Phase 6: Firebase Mobile ✅ (partial)
- [x] Firebase dependencies in pubspec.yaml
- [x] `android/app/google-services.json` configured
- [x] `ios/Runner/GoogleService-Info.plist` configured
- [x] Email/Password auth flow end-to-end
- [ ] Google Sign-In — button rendered; `onTap` has `// TODO`
- [ ] Apple Sign-In — button rendered; `onTap` has `// TODO`
- [ ] FCM push notifications — `firebase_messaging` dep present, no implementation
- [ ] Store FCM device tokens in backend

---

## 🚀 Next Up (Prioritized)

### High Priority (Core UX Gaps)
- [ ] **Vault tab** — searchable/filterable full receipt list
- [ ] **Stats tab** — spend charts, warranty expiry calendar, category breakdown
- [ ] **Settings persistence** — wire toggles/preferences to `PATCH /auth/me` and `notification_preferences` table
- [ ] **Social login** — wire Google/Apple Sign-In `onTap` handlers
- [ ] **Delete Account** — wire to `DELETE /auth/me` + local cleanup

### Medium Priority (Features)
- [ ] APScheduler background jobs (warranty/return reminders, hard-delete cleanup)
- [ ] FCM push notifications
- [ ] Background upload queue service (use existing `UploadQueue` Drift table)
- [ ] Claim PDF endpoint + mobile download flow
- [ ] `DELETE /receipts/{id}/items/{item_id}` backend endpoint
- [ ] ClaimDocument + NotificationPreference API endpoints

### Lower Priority (Production Hardening)
- [ ] Comprehensive unit + integration tests (coverage ≥ 70%)
- [ ] Offline sync mechanism
- [ ] Real AWS integration (`USE_MOCK_AWS=false`)
- [ ] Rate limiting (slowapi)
- [ ] Sentry error tracking
- [ ] CI/CD pipeline
- [ ] Production deployment

---

## 🚧 Future Enhancements

### Push Notifications
- [ ] FCM device token registration
- [ ] Warranty expiry reminders (30 days before)
- [ ] Return deadline reminders (3 days before)
- [ ] Deep linking from notification to receipt detail

### PDF Generation
- [ ] Claim document generator
- [ ] PDF template design
- [ ] S3 storage for PDFs
- [ ] Download endpoint + mobile viewer

### Real AWS Integration
- [ ] AWS account + IAM user
- [ ] S3 bucket creation + security config
- [ ] Textract API access
- [ ] Bedrock access (Claude Haiku)
- [ ] Brave Search API key
- [ ] Set `USE_MOCK_AWS=false`

### Security Hardening
- [ ] Rate limiting (slowapi)
- [ ] API key rotation
- [ ] Security audit
- [ ] HTTPS enforcement
- [ ] Change `SECRET_KEY` for production

### Performance
- [ ] Database query optimization
- [ ] Caching layer (Redis)
- [ ] Load testing

### Production Deployment
- [ ] Cloud provider selection
- [ ] CI/CD pipeline
- [ ] SSL certificates + domain
- [ ] Backup strategy
- [ ] Monitoring dashboard

---

## 📊 Progress Tracking

**Estimated Overall Progress:** ~75% of full production scope

### Completed ✅
- Backend API (100%)
- Database models + 5 migrations (100%)
- Mock + real AWS services — S3, Textract, LLM, Product Image (100%)
- Docker setup (100%)
- Firebase backend + mobile auth (email/password) (100%)
- Flutter project structure + state management (100%)
- Flutter data models (100%)
- Flutter core services (100%)
- Flutter receipt 3-step add flow (100%)
- Flutter home screen — redesigned (100%)
- Flutter product detail screen (100%)
- Flutter settings screen — UI (80% — no persistence)
- LLM OCR cleanup service (100%)
- Product image search (Brave Search) (100%)

### In Progress / Partial ⏳
- Settings screen — backend persistence (0%)
- Social login — buttons present, logic not wired (0%)

### Pending ⏳
- Vault tab (0%)
- Stats tab (0%)
- FCM / Push notifications (0%)
- APScheduler background jobs (0%)
- Offline upload queue (0%)
- PDF generation (0%)
- Real AWS integration (0%)
- Comprehensive tests (0%)
- Production deployment (0%)

---

## 🐛 Known Issues / TODOs

### Flutter
- [ ] Google Sign-In + Apple Sign-In `onTap` not implemented
- [ ] Settings preferences not persisted to backend
- [ ] Vault and Stats tabs are stubs
- [ ] Search and Notifications buttons on home have no target screen
- [ ] Background upload service not implemented (UploadQueue table defined but unused)
- [ ] Export Data + Delete Account show "Coming soon" snackbar

### Backend
- [ ] `DELETE /receipts/{id}/items/{item_id}` not implemented
- [ ] ClaimDocument router not created
- [ ] NotificationPreference router not created
- [ ] APScheduler commented out in `main.py`
- [ ] Add `DELETE /auth/me` cascade to clean up S3 objects

### Nice to Have
- [ ] Request ID tracing across all log lines
- [ ] Development seed data script
- [ ] Biometric authentication (Flutter)
- [ ] Receipt categories (Flutter + Backend)
- [ ] Multi-image receipt support

---

## 📝 Notes

- Backend fully functional with mock AWS services; switch to real via `USE_MOCK_AWS=false` + credentials
- Firebase is required for authentication
- Mobile API base URL is hardcoded in `api_service.dart` (`http://168.138.170.92:8000/api/v1`) — update for local dev or new deployment
- Drift local database is defined but only used for schema; all data flows through REST API currently
- See [CONTRIBUTING.md](CONTRIBUTING.md) for git commit message standards

---

**Last Updated:** 2026-03-17
**Status:** Core receipt flow + home screen complete — Next: Vault, Stats, Settings persistence, Social Login
