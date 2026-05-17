# Reclaima

Reclaima is a Flutter mobile app for digitising receipts, tracking warranties and return windows per line item, and generating warranty claim PDFs with defect photo attachments. The backend handles OCR via AWS Textract, LLM cleanup via AWS Bedrock (Claude Haiku), and push notifications via Firebase Cloud Messaging.

---

## Architecture

```
Flutter Mobile (Drift/SQLite, offline-first)
    │  Firebase Auth JWT
    ▼
KrakenD API Gateway  :8080   (public-facing; rate-limited)
    │  proxies to backend by service name "backend:8000"
    ▼
FastAPI Backend  :8000        (never exposed directly)
    ├── /api/v1/auth          — Firebase token verification
    ├── /api/v1/receipts      — upload, OCR pipeline, line-item CRUD
    ├── /api/v1/warranties    — expiry calculations per line item
    ├── /api/v1/claims        — PDF generation + S3 pre-signed URLs
    ├── /api/v1/products      — Brave Search product image lookup
    ├── /api/v1/notifications — preferences + APScheduler reminders
    └── /api/v1/health        — liveness probe
    ▼
PostgreSQL 15 · AWS S3 · AWS Textract · AWS Bedrock · Firebase FCM
```

The mobile app must only communicate with the KrakenD gateway. The FastAPI port is intentionally commented out in both `docker-compose.yml` and `deploy/docker-compose.prod.yml`.

---

## Repository Structure

```
.
├── backend/                  FastAPI application (Python 3.11)
│   ├── app/
│   │   ├── api/v1/           Route handlers (one file per domain)
│   │   ├── core/             Config, security, LLM prompts
│   │   ├── db/               SQLAlchemy session and Alembic base
│   │   ├── models/           ORM models
│   │   ├── schemas/          Pydantic v2 request/response schemas
│   │   └── services/         Business logic layer
│   ├── alembic/              Database migration scripts
│   ├── tests/                Pytest test suite
│   ├── Dockerfile            Multi-stage build (python:3.11-slim)
│   ├── requirements.txt
│   └── .env.example          Template for backend environment variables
├── mobile/                   Flutter application (Dart)
│   ├── lib/
│   │   ├── core/             Constants and utilities
│   │   ├── data/             Drift database, models, repositories
│   │   ├── providers/        Riverpod 2 providers
│   │   ├── screens/          Feature screens (auth, home, receipt, claims, vault, settings)
│   │   ├── services/         Dio API client and local logic
│   │   └── widgets/          Shared UI components
│   └── pubspec.yaml
├── deploy/
│   ├── docker-compose.prod.yml        Production compose (api, scheduler, migrate, krakend, postgres)
│   ├── docker-compose.monitoring.yml  Prometheus, Loki, Promtail, cAdvisor, Grafana
│   ├── scripts/oci_deploy.sh          Deploy + health-check + rollback script
│   ├── monitoring/                    Prometheus and Promtail configs
│   └── .env.prod.example             Template for production environment variables
├── scripts/ci/               No-regression gate scripts called by the CI workflow
├── docs/                     GitHub Pages showcase site
├── krakend.json              KrakenD gateway configuration (v3, port 8080)
├── docker-compose.yml        Local development stack
└── .github/workflows/ci-cd.yml
```

---

## Prerequisites

| Tool | Required version |
|---|---|
| Flutter | 3.41.4, stable channel |
| Dart SDK | ^3.10.0 (bundled with Flutter) |
| Python | 3.11 |
| Docker + Docker Compose | any recent stable release |
| AWS CLI | for real S3/Textract/Bedrock access (not needed in mock mode) |
| Firebase project | service account JSON + `google-services.json` / `GoogleService-Info.plist` |
| Infisical | for production secret management (`infisicalsdk>=1.0.3`) |

Firebase config files (`firebase-service-account.json`, `google-services.json`, `GoogleService-Info.plist`) are not in the repository and must be obtained from the Firebase console.

---

## Environment Variables

Copy `backend/.env.example` to `backend/.env`. All variables below are read by `backend/app/core/config.py`.

### Required

| Variable | Description |
|---|---|
| `SECRET_KEY` | Random string for JWT signing |
| `DATABASE_URL` | PostgreSQL DSN, e.g. `postgresql://user:pass@host:5432/db` |
| `AWS_ACCESS_KEY_ID` | AWS credential |
| `AWS_SECRET_ACCESS_KEY` | AWS credential |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Path to the Firebase Admin SDK JSON (default: `./firebase-service-account.json`) |

### AWS / OCR / LLM

| Variable | Default | Description |
|---|---|---|
| `AWS_REGION` | `us-east-1` | AWS region |
| `AWS_S3_BUCKET` | `smart-receipt-storage` | S3 bucket for receipt images and claim PDFs |
| `USE_MOCK_AWS` | `false` | Set `true` to skip real AWS calls in development |
| `BEDROCK_MODEL_ID` | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | Bedrock model used for OCR cleanup |
| `LLM_CLEANUP_ENABLED` | `true` | Toggle Bedrock LLM cleanup step |
| `OCR_MAX_RETRIES` | `3` | Textract retry attempts |
| `OCR_RETRY_DELAY_SECONDS` | `5` | Delay between Textract retries |

### Application

| Variable | Default | Description |
|---|---|---|
| `DEBUG` | `false` | Enables `/docs`, `/redoc`, `/openapi.json` and verbose errors |
| `ENVIRONMENT` | `production` | Passed to Sentry |
| `ALLOWED_ORIGINS` | `http://localhost:8000` | Comma-separated CORS origins |
| `LOG_LEVEL` | `INFO` | Python logging level |
| `MAX_FILE_SIZE_MB` | `20` | Upload size cap |
| `ALLOWED_FILE_TYPES` | `image/jpeg,image/png,application/pdf` | Accepted MIME types |

### Scheduler / Notifications

| Variable | Default | Description |
|---|---|---|
| `ENABLE_SCHEDULER` | `true` | Enable APScheduler (set `false` on API replicas; only one process should run jobs) |
| `REMINDER_CHECK_HOUR` | `3` | Hour (UTC) for warranty and return reminder jobs |
| `CLEANUP_HOUR` | `2` | Hour (UTC) for hard-delete cleanup job |
| `WARRANTY_REMINDER_DAYS` | `30` | Lead-time for warranty expiry notifications |
| `RETURN_REMINDER_DAYS` | `3` | Lead-time for return window notifications |

### Optional

| Variable | Default | Description |
|---|---|---|
| `SENTRY_DSN` | _(none)_ | Sentry error tracking DSN |
| `BRAVE_SEARCH_API_KEY` | _(empty)_ | Brave Search API key for product image lookup |

### Production only (Infisical)

In production the backend fetches secrets from Infisical at startup before Pydantic parses the environment. The remaining variables (`SECRET_KEY`, AWS credentials, etc.) are pulled from Infisical and do not need to appear in `.env.prod`.

| Variable | Description |
|---|---|
| `INFISICAL_MACHINE_IDENTITY_CLIENT_ID` | Infisical machine identity client ID |
| `INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET` | Infisical machine identity client secret |
| `INFISICAL_PROJECT_ID` | Infisical project ID |

### Docker Compose (local dev only)

Read by `docker-compose.yml` from the shell environment or a `.env` file at the repo root:

| Variable | Description |
|---|---|
| `DEV_POSTGRES_PASSWORD` | **Required.** Postgres password |
| `DEV_PGADMIN_PASSWORD` | Required only when using the `tools` profile |
| `DEV_POSTGRES_USER` | Default: `postgres` |
| `DEV_POSTGRES_DB` | Default: `smart_receipt_db` |

---

## Local Development Setup

### 1. Clone and configure

```bash
git clone <repo-url>
cd smart-receipt-and-warranty-manager

# Backend environment
cp backend/.env.example backend/.env
# Edit backend/.env — at minimum set SECRET_KEY; leave USE_MOCK_AWS=true for local dev

# Place firebase-service-account.json in backend/
# Obtain from: Firebase console → Project settings → Service accounts → Generate new private key
```

### 2. Set Docker Compose variables

Create a `.env` file at the repo root (same directory as `docker-compose.yml`):

```env
DEV_POSTGRES_PASSWORD=localdevpassword
```

### 3. Start the local stack

```bash
# Start PostgreSQL, FastAPI backend (runs migrations automatically), and KrakenD
docker-compose up -d

# Optional: include pgAdmin at http://localhost:5050
docker-compose --profile tools up -d
```

The backend container runs `alembic upgrade head` before starting uvicorn. The backend is only reachable via KrakenD at `http://localhost:8080`.

### 4. Running Alembic manually

```bash
cd backend

# Apply all pending migrations
alembic upgrade head

# Generate a migration after model changes
alembic revision --autogenerate -m "description"

# Verify no unapplied migrations exist
alembic check
```

### 5. Running the backend directly (no Docker)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate    # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

With `DEBUG=true` in `backend/.env`, OpenAPI docs are at `http://localhost:8000/docs`.

### 6. Running the mobile app

```bash
cd mobile
flutter pub get

# Regenerate after modifying Drift schemas, Riverpod @riverpod providers, or @JsonSerializable models
flutter pub run build_runner build --delete-conflicting-outputs
dart format lib test   # normalise generated file formatting

flutter run
```

---

## Running Tests

### Backend

```bash
cd backend

# Run all tests with coverage
pytest tests --cov=app --cov-config=.coveragerc --cov-report=term-missing

# Minimum environment needed to run without real AWS or Firebase
USE_MOCK_AWS=true ENABLE_SCHEDULER=false \
  SECRET_KEY=test-secret \
  DATABASE_URL=postgresql://user:pass@localhost:5432/testdb \
  pytest tests --cov=app --cov-report=term-missing

# Static analysis
ruff check app tests
black --check app tests
mypy app
bandit -r app -ll
pip-audit
```

The CI enforces a **70% coverage floor** and a **no-regression gate**: coverage on HEAD must not drop below coverage on the base commit.

### Mobile

```bash
cd mobile

flutter test --coverage
flutter analyze
dart format --set-exit-if-changed lib test
```

The CI enforces a **60% coverage floor** with the same no-regression gate.

---

## CI/CD Pipeline

Single workflow: `.github/workflows/ci-cd.yml`. Triggers: pull requests to `main`, pushes to `main`, manual `workflow_dispatch` (with optional `deploy: true` input).

### Job dependency graph

```
secret_scan
    ├── backend_ci      (Python 3.11; postgres:15-alpine service container)
    ├── mobile_ci       (Flutter 3.41.4 stable)
    └── krakend_check   (validates krakend.json via devopsfaith/krakend:2 check)
              │
              └─── backend_image   ← needs all four above; main branch only
                        │
                        └─── deploy_backend_oci   ← needs backend_image; main branch only
```

### Job details

**`secret_scan`** — Runs Gitleaks across the full git history. Blocks all other jobs on failure.

**`backend_ci`** — Spins up a `postgres:15-alpine` service container, then runs in order:
1. Ruff lint (`ruff check app tests`)
2. Black format check (changed files only on PRs; full `app tests` scan when SHA is unavailable)
3. Mypy type check — no-regression gate (`scripts/ci/check_mypy.sh`)
4. Pytest + coverage — no-regression gate, 70% floor (`scripts/ci/check_pytest.sh`)
5. Alembic migration check (`alembic upgrade head && alembic check`)
6. Bandit security scan — no-regression gate (`scripts/ci/check_bandit.sh`)
7. pip-audit dependency vulnerability scan — no-regression gate (`scripts/ci/check_pip_audit.sh`)

Uploads `backend/coverage.xml` as a workflow artifact.

**`mobile_ci`** — Runs:
1. `flutter pub get`
2. `build_runner build` followed by `dart format lib test` — fails if generated outputs differ from committed files
3. `dart format --set-exit-if-changed lib test`
4. Flutter analyze — no-regression gate (`scripts/ci/check_flutter_analyze.sh`)
5. `flutter test --coverage` — no-regression gate, 60% floor (`scripts/ci/check_mobile_coverage.sh`)
6. Android debug APK build — skipped if `google-services.json` is absent and `ANDROID_GOOGLE_SERVICES_JSON` secret is not set

Uploads `mobile/coverage/lcov.info` and the debug APK as workflow artifacts.

**`krakend_check`** — Validates `krakend.json` using `devopsfaith/krakend:2 check`.

**`backend_image`** — Runs only on pushes to `main` (or `workflow_dispatch` with `deploy: true`) after all CI jobs pass:
1. Multi-arch build (`linux/amd64`, `linux/arm64`) from `backend/Dockerfile`
2. Push to `ghcr.io/<owner>/smart-receipt-backend` with tags `sha-<SHA>` and `latest-prod`
3. Trivy vulnerability scan (CRITICAL/HIGH severity; exits 1 on findings)
4. SPDX SBOM generation via Anchore
5. Keyless image signing with Cosign

**`deploy_backend_oci`** — Runs only after `backend_image` succeeds, in the `production` GitHub environment (requires approval):
1. Configures SSH to the OCI VM (`OCI_SSH_PRIVATE_KEY`, `OCI_KNOWN_HOST` secrets; supports raw key text or base64-encoded)
2. Syncs compose files, `krakend.json`, monitoring configs, and `oci_deploy.sh` to the VM via SCP
3. Executes `oci_deploy.sh` over SSH with image tag and Infisical credentials passed as env vars
4. Sends a Slack notification to `SLACK_DEPLOY_WEBHOOK` on failure

---

## Deployment

The backend runs on an OCI Compute VM. The production compose file is `deploy/docker-compose.prod.yml`.

### Production containers

| Container | Image | Purpose |
|---|---|---|
| `postgres` | `postgres:15-alpine` | Database |
| `migrate` | backend image | One-shot Alembic migration runner; exits after `alembic upgrade head` |
| `api` | backend image | FastAPI workers (`ENABLE_SCHEDULER=false`) |
| `scheduler` | backend image | Single worker with `ENABLE_SCHEDULER=true` running APScheduler jobs on port 8010 |
| `krakend` | `devopsfaith/krakend:2.6.0` | API gateway; mapped to host port `API_PORT` (default 8000) |

The monitoring stack (`deploy/docker-compose.monitoring.yml`) is a separate compose project with Prometheus, node-exporter, cAdvisor, Loki, Promtail, and Grafana (port 3000). It is started automatically by the deploy script if `docker-compose.monitoring.yml` exists on the VM.

### Deploy script (`deploy/scripts/oci_deploy.sh`)

The script is called by CI but can also be run manually on the VM. It:

1. Logs in to GHCR and records the current Alembic revision for rollback
2. Runs the `migrate` container against the target image
3. Brings up `api`, `scheduler`, and `krakend`
4. Polls `GET /api/v1/health` and checks container states (20 attempts, 3 s apart)
5. Runs an authenticated smoke test if `SMOKE_TEST_TOKEN` is set
6. On failure: downgrades the database to the pre-deploy revision and restarts the previous image

### Manual production setup

```bash
# On the OCI VM — one-time setup
cp deploy/.env.prod.example /mnt/data/smart-receipt-and-warranty-manager/.env.prod
# Edit .env.prod with real values

# Place the Firebase service account on the VM
mkdir -p /mnt/data/smart-receipt-and-warranty-manager/secrets
# Copy firebase-service-account.json to that secrets/ directory
```

Then trigger the workflow manually in GitHub Actions with `deploy: true`, or execute `oci_deploy.sh` directly.

---

## Project Status

Core features are implemented: receipt scanning with the Textract + Bedrock OCR pipeline, per-line-item warranty and return window tracking, claim PDF generation with defect photo attachments, FCM push notifications, and offline-first sync via Drift/SQLite. The app is targeting Google Play launch.

Showcase page: https://sujayamindev.github.io/reclaima
