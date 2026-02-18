---
applyTo: '**'
---

# 📱 Smart Receipt & Warranty Manager

### Smart Consumer Warranty Tracking System

---

# 1. Project Overview

## 1.1 Vision

Smart Receipt & Warranty Manager is a production-oriented mobile application that:

* Digitizes paper and PDF receipts using OCR
* Extracts structured purchase information
* Tracks warranty and return deadlines
* Sends proactive reminders
* Generates claim-ready PDF documents

The system focuses on the complete **post-purchase lifecycle**, not just scanning.

---

# 2. System Architecture

## 2.1 High-Level Architecture

```
Flutter Mobile App
        ↓
Firebase Authentication
        ↓
FastAPI Backend (Dockerized Modular Monolith)
        ↓
---------------------------------------------
| PostgreSQL | AWS S3 | AWS Textract |
---------------------------------------------
```

---

## 2.2 Architecture Style

**Type:** Modular Monolith (Cloud Hosted)

### Why:

* Single domain context
* Small team
* 7-day prototype requirement
* Production-ready without overengineering
* Future extraction into microservices possible

---

# 3. Technology Stack

## 3.1 Frontend

* Flutter (Cross-platform)
* Firebase Auth SDK
* REST API communication via HTTPS

---

## 3.2 Backend

* Python 3.11+
* FastAPI
* Pydantic
* SQLAlchemy
* Alembic (DB migrations)
* boto3 (AWS SDK)
* Docker

---

## 3.3 Database

* PostgreSQL
* Managed or Dockerized (dev)
* Indexed properly for production load

---

## 3.4 Third-Party Services

| Service       | Purpose                             |
| ------------- | ----------------------------------- |
| Firebase Auth | User authentication                 |
| AWS Textract  | OCR & structured receipt extraction |
| AWS S3        | File storage (images + PDFs)        |

---

# 4. Authentication Design

## 4.1 Provider

Firebase Authentication

## 4.2 Flow

1. User logs in via Flutter (Firebase SDK)
2. Firebase returns JWT
3. Flutter sends JWT in `Authorization: Bearer <token>`
4. FastAPI verifies token using Firebase Admin SDK
5. Backend creates or retrieves internal user record

## 4.3 Responsibility Separation

| Layer      | Responsibility                 |
| ---------- | ------------------------------ |
| Firebase   | Identity verification          |
| FastAPI    | Authorization + business logic |
| PostgreSQL | User data persistence          |

---

# 5. Backend Structure (Modular Monolith)

```
app/
 ├── main.py
 ├── core/
 │    ├── config.py
 │    ├── security.py
 │
 ├── db/
 │    ├── session.py
 │    ├── base.py
 │
 ├── models/
 ├── schemas/
 ├── services/
 │    ├── receipt_service.py
 │    ├── textract_service.py
 │    ├── s3_service.py
 │
 ├── api/
 │    ├── v1/
 │         ├── auth.py
 │         ├── receipts.py
 │         ├── warranties.py
 │
 └── modules/
      ├── auth/
      ├── user/
      ├── receipt/
      ├── pdf/
      └── ocr/
```

---

# 6. Monitoring & Observability

## 6.1 Application Logging

* Structured JSON logs
* Log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
* Include request_id for tracing
* Log OCR processing times
* Log authentication attempts

## 6.2 Error Tracking

* Integrate error tracking service (Sentry/similar)
* Capture unhandled exceptions
* Track OCR failure rates
* Monitor S3 upload failures

## 6.3 Metrics & Health Checks

* `/health` endpoint for liveness
* `/ready` endpoint for readiness
* Track metrics:
  * Receipt processing time
  * OCR success/failure rates
  * API response times
  * Active users
  * Storage usage

## 6.4 Alerting

* Alert on high error rates
* Alert on OCR service downtime
* Alert on database connection issues
* Alert on S3 access failures

---

# 7. Rate Limiting & API Protection

## 7.1 Backend Rate Limiting

* Use FastAPI middleware (slowapi)
* Rate limits:
  * Auth endpoints: 5 requests/minute
  * Receipt upload: 10 uploads/hour per user
  * General API: 100 requests/minute per user
* Return 429 Too Many Requests
* Include rate limit headers

## 7.2 Mobile App Protection

* Implement exponential backoff on failures
* Cache responses where appropriate
* Queue requests locally
* Respect 429 responses
* Implement request deduplication

## 7.3 Abuse Prevention

* Monitor unusual activity patterns
* Implement file size limits (5MB)
* Validate file types before upload
* Track per-user OCR usage
* Implement soft ban for abuse

---

# 8. Receipt Upload & OCR Flow

## 6.1 Upload Flow (Production Pattern)

1. User uploads image/PDF
2. Backend validates file
3. Store file in S3
4. Create receipt record (status = PROCESSING)
5. Send S3 reference to Textract
6. Parse response
7. Store structured data in PostgreSQL
8. Update status to PROCESSED or FAILED

---

## 8.2 Receipt Status Lifecycle

```
LOCAL_ONLY (Flutter only)
UPLOADED
PROCESSING
COMPLETED
OCR_FAILED
MANUAL_ENTRY
```

---

## 8.3 Retry Strategy

If OCR fails:

* Show "Retry" button in UI
* Option 1: Auto retry (up to 3 attempts)
* Option 2: Manual data entry
* Replace S3 object (with S3 versioning enabled)
* Update receipt status to OCR_FAILED
* If manual entry: status → MANUAL_ENTRY
* Track retry attempts in database

---

# 9. Warranty & Return Date Calculation

## 9.1 Core Logic

**Input Sources:**
* OCR-extracted warranty period (e.g., "12 months")
* Manual user entry
* Default values if not specified

**Calculation:**
```python
warranty_expiry = purchase_date + warranty_period
return_expiry = purchase_date + return_period (default: 30 days)
```

## 9.2 Implementation Details

* Store all dates as timezone-aware UTC
* Convert to user's local timezone for display
* Handle edge cases:
  * Leap years
  * Invalid dates
  * Dates in the past
* Default warranty period: 12 months
* Default return period: 30 days

## 9.3 Reminder Calculation

* Warranty reminder: 30 days before expiry
* Return reminder: 3 days before expiry
* Store reminder dates in database
* APScheduler checks daily for upcoming reminders

---

# 10. AWS Design

## 7.1 S3 Bucket Structure

```
smart-receipt-storage/
 ├── users/{user_id}/receipts/
 ├── users/{user_id}/claims/
 └── temp/
```

---

## 10.2 IAM Best Practices

* No root credentials
* Least privilege IAM user
* Permissions scoped to specific bucket
* Textract-specific permissions only

## 10.3 S3 Security

* **Pre-signed URLs**: Generate for uploads (don't expose IAM to client)
* **Bucket Encryption**: Enable SSE-S3 or SSE-KMS
* **Versioning**: Enable S3 versioning for file history
* **Lifecycle Policies**: Auto-delete temp/ files after 7 days
* **CORS Configuration**: Restrict to Flutter app domain only
* **Block Public Access**: Enable all block public access settings
* **Access Logging**: Enable S3 access logs for audit

## 10.4 Pre-signed URL Flow

1. Flutter requests upload URL from backend
2. Backend generates pre-signed URL (valid 15 minutes)
3. Flutter uploads directly to S3 using pre-signed URL
4. Flutter notifies backend of successful upload
5. Backend triggers OCR processing

---

# 8. Database Design (Core Entities)

## 8.1 User

* id (UUID)
* firebase_uid
* email
* created_at

---

## 8.2 Receipt

* id
* user_id
* s3_object_key
* store_name
* purchase_date
* total_amount
* warranty_expiry_date
* return_expiry_date
* status
* created_at

---

## 11.3 ClaimDocument

* id
* receipt_id
* issue_description
* generated_pdf_s3_key
* created_at

## 11.4 Database Indexes

**Critical Indexes:**
* `user_id` on receipts (for user queries)
* `warranty_expiry_date` on receipts (for reminder scheduler)
* `return_expiry_date` on receipts (for reminder scheduler)
* `firebase_uid` on users (for auth lookups)
* `status` on receipts (for filtering)
* Composite index: `(user_id, created_at)` for pagination

## 11.5 Data Deletion Policy

**Soft Delete:**
* Add `deleted_at` timestamp to all main tables
* Soft delete immediately on user request
* Exclude soft-deleted records from queries

**Hard Delete:**
* Background job runs daily (APScheduler)
* Permanently delete records where `deleted_at > 30 days`
* Delete associated S3 objects
* Log all deletion operations

## 11.6 GDPR Compliance

**Right to be Forgotten:**
* User-initiated account deletion
* Cascade delete:
  1. Soft delete user record
  2. Soft delete all receipts
  3. Soft delete all claim documents
  4. Schedule S3 cleanup
  5. Hard delete after 30 days

**Data Export:**
* Provide API endpoint to export user data
* Include all receipts, warranties, and documents
* Format: JSON or CSV

**Data Retention:**
* Active data: Indefinite (until user deletes)
* Soft-deleted data: 30 days
* Backup data: 90 days
* Logs: 30 days

---

# 9. API Design Standards

## 9.1 Versioning

```
/api/v1/receipts
/api/v1/warranties
```

---

## 12.2 REST Principles

* Use proper HTTP verbs
* 200 OK
* 201 Created
* 400 Bad Request
* 401 Unauthorized
* 404 Not Found
* 422 Unprocessable Entity (validation errors)
* 429 Too Many Requests
* 500 Internal Error

---

## 9.3 Authentication Header

```
Authorization: Bearer <firebase_jwt>
```

---

# 13. Security Best Practices

## 13.1 Authentication & Authorization

* Never store secrets in code
* Use `.env` files
* Validate Firebase JWT on every request
* Use HTTPS only
* Implement CORS properly

## 13.2 Input Validation

**File Validation:**
* File type whitelist: JPEG, PNG, PDF only
* File size limit: 5MB maximum
* Check MIME type, not just extension
* Validate image dimensions (min: 300x300, max: 4096x4096)

**API Input Validation:**
* Use Pydantic schemas for all API inputs
* Validate date formats (ISO 8601)
* Sanitize user input (strip HTML, validate email)
* Validate UUIDs and foreign keys
* Enforce string length limits

**SQL Injection Prevention:**
* Use SQLAlchemy ORM (parameterized queries)
* Never construct raw SQL from user input
* Use query builders and filters

**XSS Prevention:**
* Sanitize all user-generated content
* Escape HTML in responses
* Set proper Content-Security-Policy headers

---

# 11. Docker Strategy

## 11.1 Dockerized Backend

* Multi-stage build
* Use slim Python image
* Expose only required port
* Use environment variables

---

## 11.2 Docker Compose (Dev)

* FastAPI
* PostgreSQL
* Optional pgAdmin

---

# 12. Production Readiness Principles

* Stateless backend
* Externalized configuration
* Structured logging
* Proper error handling
* Background task handling
* Clear separation of concerns

---

# 14. Error Handling Strategy

## 14.1 Error Response Format

**Consistent JSON Structure:**
```json
{
  "error": "ERROR_CODE",
  "message": "User-friendly message",
  "details": {},  // Optional additional context
  "request_id": "uuid"  // For tracing
}
```

## 14.2 Error Categories

**Authentication Errors (401):**
* `INVALID_TOKEN`
* `TOKEN_EXPIRED`
* `UNAUTHORIZED`

**Validation Errors (422):**
* `INVALID_FILE_TYPE`
* `FILE_TOO_LARGE`
* `INVALID_DATE_FORMAT`
* `MISSING_REQUIRED_FIELD`

**OCR Errors (500):**
* `OCR_PROCESSING_FAILED` → Allow manual entry
* `TEXTRACT_SERVICE_UNAVAILABLE` → Retry later
* `OCR_NO_TEXT_FOUND` → Prompt manual entry

**Storage Errors (500):**
* `S3_UPLOAD_FAILED`
* `S3_ACCESS_DENIED`
* `FILE_NOT_FOUND`

## 14.3 Error Handling Flow

**OCR Failure Handling:**
1. Detect OCR failure
2. Update receipt status to `OCR_FAILED`
3. Return error to Flutter
4. Flutter shows:
   * "Unable to read receipt"
   * "Retry" button
   * "Enter manually" button
5. Log error with context for debugging

**Retry Logic:**
* OCR failures: Up to 3 automatic retries
* S3 uploads: Up to 3 retries with exponential backoff
* API calls: Exponential backoff (1s, 2s, 4s)

## 14.4 Logging Standards

**Do NOT Log:**
* Raw exception traces to users
* Sensitive data (passwords, tokens)
* Full file contents

**DO Log:**
* Request ID
* User ID (for tracing)
* Error code and message
* Stack trace (internal logs only)
* Timestamp
* Request parameters (sanitized)

---

# 15. Background Tasks & Scheduling

## 15.1 Task Scheduler: APScheduler

**Use Cases:**
* Warranty expiry reminders
* Return deadline reminders
* Hard delete cleanup (30-day soft-deleted data)
* OCR retry queue processing

## 15.2 Scheduled Jobs

**Daily Jobs:**
```python
# Check warranty reminders (runs at 9 AM UTC)
- Query receipts where warranty_expiry_date = today + 30 days
- Send push notifications via Firebase Cloud Messaging

# Check return reminders (runs at 9 AM UTC)
- Query receipts where return_expiry_date = today + 3 days
- Send push notifications

# Cleanup job (runs at 2 AM UTC)
- Hard delete records where deleted_at < now() - 30 days
- Delete associated S3 objects
```

**Retry Queue (every 5 minutes):**
```python
- Process receipts with status = OCR_FAILED
- Retry count < 3
- Increment retry count
- Update status on success/failure
```

## 15.3 Configuration

```python
from apscheduler.schedulers.asyncio import AsyncIOScheduler

scheduler = AsyncIOScheduler()
scheduler.add_job(check_warranty_reminders, 'cron', hour=9)
scheduler.add_job(cleanup_deleted_data, 'cron', hour=2)
scheduler.add_job(process_retry_queue, 'interval', minutes=5)
scheduler.start()
```

## 15.4 Error Handling

* Wrap all jobs in try-except
* Log failures with full context
* Send alerts on critical job failures
* Implement job-level retry logic

---

# 16. Future Scalability Plan

Phase 1 (Current):
* Modular Monolith
* APScheduler for background tasks
* Direct S3 integration

Phase 2 (Scale):
* Add Redis for caching
* Extract background workers (Celery)
* Add message queue (RabbitMQ/SQS)
* Database read replicas

Phase 3 (Microservices):
* Extract OCR module as separate service
* Extract reminder service
* API Gateway for routing
* Service mesh for inter-service communication

**Design Principle:**
* Keep modules loosely coupled
* Use interfaces/protocols
* Avoid tight dependencies
* Enable future extraction

---

# 17. Notification System

## 17.1 Push Notifications

**Provider:** Firebase Cloud Messaging (FCM)

**Notification Types:**
1. Warranty expiry reminder (30 days before)
2. Return deadline reminder (3 days before)
3. OCR processing complete
4. OCR processing failed

## 17.2 Implementation

**Flutter Setup:**
* Register device token with FCM
* Store token in backend database
* Handle foreground/background notifications
* Deep linking to specific receipt

**Backend Setup:**
* Store FCM tokens per user
* Use Firebase Admin SDK to send notifications
* APScheduler triggers notification jobs
* Track notification delivery status

## 17.3 Notification Content

**Warranty Reminder:**
```
Title: "Warranty Expiring Soon"
Body: "Your [Product Name] warranty expires in 30 days"
Action: Open receipt details
```

**Return Reminder:**
```
Title: "Return Deadline Approaching"
Body: "Only 3 days left to return [Product Name]"
Action: Open receipt details
```

## 17.4 User Preferences

* Allow users to enable/disable notification types
* Set reminder timing preferences
* Quiet hours support

---

# 16. Claim-Ready PDF Generation (Later Phase)

* Pull structured data
* Include:

  * Customer info
  * Receipt image
  * Warranty details
  * Issue description
* Generate PDF
* Store in S3
* Provide download URL

---

# 17. Development Standards

## 17.1 Code Quality

* Use type hints
* Follow PEP8
* Modular services
* No business logic in routes
* Service layer handles logic

---

## 17.2 Git Strategy

* Feature branches
* Meaningful commit messages
* No direct commits to main

---

## 18.3 Testing Strategy

## 18.3.1 Testing Layers

**1. Unit Tests (pytest)**
* Services and business logic
* Warranty calculation functions
* Date handling utilities
* OCR response parsers
* Input validators

**2. Integration Tests (pytest + TestClient)**
* API endpoints with test database
* Authentication flow
* Receipt upload and processing
* S3 mock integration
* Database transactions

**3. Contract Tests**
* Textract response parsing
* Mock various OCR response formats
* Handle edge cases (no text, poor quality)

**4. E2E Tests (Optional)**
* Flutter integration tests
* Critical user flows
* Upload → OCR → Notification flow

## 18.3.2 Coverage Targets

* **Minimum Coverage:** 70% overall
* **Critical Paths:** 100% coverage
  * Authentication logic
  * Warranty calculations
  * Date calculations
  * Payment/claim logic (if applicable)

## 18.3.3 Testing Tools

```python
# pytest - Testing framework
# pytest-asyncio - Async test support
# pytest-cov - Coverage reporting
# httpx - API test client
# factory_boy - Test data factories
# freezegun - Mock datetime
# moto - Mock AWS services
```

## 18.3.4 Test Database

* Use separate test database
* Reset between tests
* Use transactions (rollback after each test)
* Seed with factory data

## 18.3.5 CI/CD Integration

* Run tests on every PR
* Block merge if tests fail
* Generate coverage reports
* Run linting (ruff, black, mypy)

---

# 18. Non-Functional Requirements

* Secure
* Scalable
* Maintainable
* Cost-aware
* Production-deployable

---

# 19. Flutter Mobile App Architecture

## 19.1 State Management: Riverpod

**Why Riverpod:**
* Compile-safe
* Testable
* No BuildContext required
* Provider dependency injection

**Architecture:**
```dart
// Providers
- authProvider (Firebase Auth state)
- receiptProvider (Receipt list state)
- uploadQueueProvider (Upload queue management)

// Services
- AuthService
- ReceiptService
- UploadService
- NotificationService
```

## 19.2 Local Database: Drift

**Purpose:**
* Offline-first architecture
* Cache receipts locally
* Queue uploads
* Sync status tracking

**Tables:**
```sql
receipts (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  status TEXT,  -- LOCAL_ONLY, UPLOADED, COMPLETED, OCR_FAILED
  image_path TEXT,
  store_name TEXT,
  purchase_date TEXT,
  total_amount REAL,
  warranty_expiry TEXT,
  synced_at INTEGER
)

upload_queue (
  id TEXT PRIMARY KEY,
  receipt_id TEXT,
  retry_count INTEGER,
  created_at INTEGER
)
```

## 19.3 Image Compression

**Package:** `flutter_image_compress`

**Configuration:**
```dart
quality: 85  // Balance between size and OCR accuracy
minWidth: 1024  // Minimum width for OCR
minHeight: 1024
format: CompressFormat.jpeg
```

**Guidelines:**
* Do NOT over-compress (avoid pixelation)
* Maintain text readability
* Target: < 2MB after compression
* Preserve aspect ratio

## 19.4 Upload Flow

**Step-by-Step:**
```
1. User selects image from gallery/camera
2. Compress image using flutter_image_compress
3. Save compressed image locally
4. Save record in Drift with status: LOCAL_ONLY
5. Add to upload queue

[Background Worker]
6. Request pre-signed URL from backend
7. Upload to S3 using pre-signed URL
8. If success → Update status: UPLOADED
9. Notify backend to start OCR
10. Poll for OCR result or wait for notification
11. If OCR success → status: COMPLETED
12. If OCR failure → status: OCR_FAILED (show Retry button)
```

## 19.5 Upload Queue Management

**Features:**
* Non-blocking UI
* Background upload worker
* Retry failed uploads
* Show upload progress
* Pause/resume on network changes

**Retry Strategy:**
```dart
- Max retries: 3
- Exponential backoff: 2s, 4s, 8s
- Retry on: network errors, 5xx errors
- Don't retry on: 4xx errors (except 429)
- Show "Retry" button if all retries fail
```

## 19.6 Offline Support

* View locally cached receipts
* Queue uploads when offline
* Sync when back online
* Show sync status indicator
* Handle conflict resolution

## 19.7 Deep Linking

* Handle notification taps
* Navigate to specific receipt
* Handle app launch from notification
* Universal links support (future)

---

# 20. Cost Awareness & Optimization

## 20.1 Cost Drivers

| Service  | Cost Driver                 | Approximate Cost          |
| -------- | --------------------------- | ------------------------- |
| Textract | Per page processed          | $1.50 per 1,000 pages     |
| S3       | Storage + requests          | $0.023/GB/month           |
| Firebase | 50,000 MAUs free tier       | Free up to 50K MAUs       |
| RDS      | Database instance hours     | ~$15-50/month (t3.micro)  |

## 20.2 Cost Optimization Strategies

**1. OCR Result Caching**
```python
# Don't re-process the same receipt
- Check if receipt already processed
- Cache OCR results in database
- Use checksum to detect duplicate uploads
```

**2. Image Compression**
* Compress in Flutter before upload
* Reduce S3 storage costs
* Reduce Textract processing costs
* Target: < 2MB per image

**3. S3 Storage Optimization**
* Use S3 Intelligent-Tiering
* Archive old receipts to Glacier (receipts > 2 years)
* Lifecycle policy: Delete temp/ folder after 7 days
* Compress PDFs before storage

**4. Rate Limiting**
* Prevent abuse and excessive OCR usage
* 10 uploads per hour per user
* Block suspicious activity

**5. Request Batching**
* Batch notification sends
* Batch database queries
* Use connection pooling

**6. Monitor Usage**
* Track OCR usage per user
* Alert on unusual spikes
* Generate cost reports
* Set AWS billing alerts

**7. Free Tier Maximization**
* Firebase: Free up to 50K MAUs
* S3: 5GB free for 12 months
* Textract: 1,000 pages/month free for 3 months

**8. Prevent Redundant Processing**
* Deduplicate uploads (file hash)
* Cache API responses
* Implement idempotency keys

---

# 21. Engineering Philosophy for This Project

* Do not overengineer
* Do not prematurely optimize
* Build clean modular structure
* **Design for loose coupling** (enable future extraction)
* Think about scaling
* Keep responsibilities separated
* Always design for production
* Postpone deployment strategy until demo complete
* Focus on core functionality first

---

# 22. Core Principle

This is not a demo project.

This is:

A production-ready mobile system built with:

* Real cloud services
* Real architecture
* Real engineering discipline
