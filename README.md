<div align="center">

# Reclaima

Scan receipts. Track warranties. File claims — before deadlines expire.<br/>
Receipt OCR with per-item warranty tracking and one-tap claim generation.

![Flutter](https://img.shields.io/badge/Flutter-3.41.4-54C5F8?logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-Python%203.11-009688?logo=fastapi&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Textract%20·%20Bedrock%20·%20S3-FF9900?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI4MDAiIGhlaWdodD0iODAwIiBmaWxsPSIjZmZmIiB2aWV3Qm94PSIwIDAgMzIgMzIiPjxwYXRoIGQ9Ik02LjU4NCA5LjAxYy0xLjM2IDAtMi43NC41My0yLjk3LjgyLS4wNi4xMi0uMiAxLjA5LjEzIDEuMDkuMTEgMCAuMTYuMDIuNDgtLjEzIDEuMi0uNDcgMS45Ni0uNDYgMi4wNy0uNDYgMS4zNS0uMTMgMi4xMy43OSAyLjAxIDEuOTh2LjdjLTEuMTQtLjI3LTEuNzktLjI4LTIuMTEtLjI4LTEuNjYtLjEtMy4xOTQuNzc2LTMuMTk0IDIuNyAwIDIuMTEgMS44ODMgMi41NiAyLjYxMyAyLjUzIDEuMDkuMDEgMi4xMy0uNDggMi44Mi0xLjMzLjU1IDEuMjMuOSAxLjE1LjkxIDEuMTUuMSAwIC4xOC0uMDQuMjYtLjA5bC41Ny0uNGMuMS0uMDYuMTgtLjE2LjE5LS4yOC0uMDEtLjI5LS41My0uNzQtLjQ5LTEuNzV2LTMuMTJhMy4xOCAzLjE4IDAgMCAwLS43OTktMi4zNSAzLjQyIDMuNDIgMCAwIDAtMi40OS0uNzhtMTkuMzczIDBjLTIgMC0zLjE1IDEuMjUtMy4xMiAyLjUyIDAgMS43NCAxLjc2IDIuMjkgMS45NiAyLjM1IDEuNjkuNTMgMS45Mi41NSAyLjM5Ljk1LjQuNDEuMzUgMS4yMS0uMjQgMS41Ni0uMTcuMS0uOS41NC0yLjU1LjItLjU1LS4xMS0uODQtLjI0LTEuMjktLjQzLS4xMi0uMDQtLjQtLjExLS40LjI2di40OWMwIC4yMy4xNC40NC4zNS41NCAxLjA1LjUzIDIuMzEuNTUgMi41OC41NS4wNCAwIDIuMzQuMDAxIDMuMTEtMS41NS4xNTgtLjMyLjU3LTEuNDktLjItMi40OS0uNjQtLjc1LTEuMTktLjgzLTIuODMtMS4zMy0uMTQtLjA0LTEuMzUtLjM1LTEuMzQtMS4yLS4wNi0xLjA5IDEuNDItMS4xNSAxLjczLTEuMTMgMS4yNS0uMDIgMS44Ny40NSAyLjIxLjQ4LjE1IDAgLjIyLS4wOS4yMi0uMjl2LS40NmEuNS41IDAgMCAwLS4wOS0uMzFjLS40LS41Mi0xLjkzLS43MS0yLjQ5LS43MW0tMTUuMTguMjVjLS4xMS4wMi0uMTkuMTMtLjE3LjI0LjAyLjEzLjA0LjI2LjA5LjM5bDIuMjQgNy4zOWMuMDUuMjQuMjEuNS41Ni40NmguODJjLjUuMDUuNTctLjQzLjU4LS40OGwxLjQ3LTYuMTYgMS40OSA2LjE3Yy4wMS4wNS4wOC41My41Ny40OGguODNjLjM2LjA0LjUzLS4yMi41OC0uNDYgMi41Mi04LjExIDIuMzUtNy41NiAyLjM3LTcuNjQuMDQtLjQyLS4yLS4zOS0uMjQtLjM4aC0uODljLS40NS0uMDUtLjU0LjM2LS41Ni40NmwtMS42NiA2LjQxLTEuNS02LjQxYy0uMDctLjQ5LS40Ny0uNDctLjU3LS40NmgtLjc3Yy0uNDQtLjA0LS41NS4zMS0uNTguNDZsLTEuNDkgNi4zMi0xLjYtNi4zMmMtLjA0LS4yLS4xNy0uNTEtLjU2LS40N3ptLTQuMjU0IDQuNjNjLjcyLjAxIDEuMzQyLjEyIDEuNzcyLjIyIDAgLjUuMDE4Ljc4LS4wOTIgMS4yMy0uMTQuNDgtLjc1OSAxLjM1LTIuMjE5IDEuMzctLjg0LjA0LTEuMzktLjYyLTEuMzQtMS4zNy0uMDUtMS4yIDEuMTktMS41IDEuODgtMS40NW0yMi41MTggNi4xMTJjLS45MzMuMDEzLTIuMDM1LjIyMi0yLjg3MS44MDktLjI1OC4xNzktLjIxMy40MjcuMDc0LjM5NC45NC0uMTEzIDMuMDMyLS4zNjcgMy40MDYuMTExcy0uNDE0IDIuNDUtLjc2MyAzLjMzMmMtLjEwOC4yNjMuMTIuMzcyLjM2MS4xNzIgMS41NjQtMS4zMSAxLjk3LTQuMDU2IDEuNjUtNC40NS0uMTYtLjE5OC0uOTI0LS4zODEtMS44NTctLjM2OG0tMjcuODI0IDFjLS4yMTguMDMtLjMxMi4zMDYtLjA4NC41MjVDNS4wNSAyNS4yMDEgMTAuMjI2IDI3IDE1Ljk3MyAyN2M0LjA5OSAwIDguODU3LTEuMzM3IDEyLjE0Mi0zLjg1Ny41NDMtLjQyLjA4LTEuMDQ3LS40NzYtLjgtMy42ODMgMS42MjYtNy42ODQgMi40MDktMTEuMzI1IDIuNDA5LTUuMzk2IDAtMTAuNjItMS4xMjctMTQuODQ1LTMuNjg2YS40LjQgMCAwIDAtLjI1Mi0uMDY0Ii8+PC9zdmc+)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![OCI](https://img.shields.io/badge/OCI-ARM%20VM-F80000?logo=oracle&logoColor=white)
![CI/CD](https://github.com/sujayamindev/reclaima/actions/workflows/ci-cd.yml/badge.svg)

<a href="https://sujaya.dev/reclaima/"> <img alt="Static Badge" src="https://img.shields.io/badge/%F0%9F%94%97%20Project%20Page-brightgreen?style=for-the-badge"> </a>

</div>

---

## Table of Contents

- [What is Reclaima?](#what-is-reclaima)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Key Technical Decisions](#key-technical-decisions)
- [CI/CD Pipeline](#cicd-pipeline)

---

## What is Reclaima?

Most people lose warranties because nothing tracks them. Expense apps treat receipts as financial records. Warranty trackers rely on manual entry and stop at the reminder. No consumer app handles the complete lifecycle — scan, extract per-item details, track deadlines, and produce a claim document.

Reclaima fills that gap. Scan a paper or PDF receipt and Reclaima extracts every line item individually using AWS Textract with a Claude Haiku cleanup layer. Each item gets its own warranty period, return window, and push notification schedule. When something fails, one tap generates a structured PDF claim — purchase details, defect photos, retailer contact — ready to submit.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│               Flutter Mobile App  ·  iOS & Android              │
│   Riverpod · Drift/SQLite offline · Firebase Auth SDK · FCM     │
│                    Dio HTTP · image_cropper                     │
└──────────────────────────────┬──────────────────────────────────┘
                               │  ↕  Firebase JWT · HTTPS
┌──────────────────────────────┴──────────────────────────────────┐
│                     KrakenD API Gateway                         │
│       port 8080 · JWT validation · rate limiting · routing      │
└──────────────────────────────┬──────────────────────────────────┘
                               │  ↕  proxied requests · port 8000
┌──────────────────────────────┴──────────────────────────────────┐
│             FastAPI Backend  ·  OCI Compute (Docker)            │
│       Python 3.11 · SQLAlchemy ORM · Alembic · APScheduler      │
│           Pydantic v2 · Firebase Admin JWT verification         │
└─────┬────────────┬─────────────┬──────────────┬────────────┬────┘
      │            │             │              │            │
      ▼            ▼             ▼              ▼            ▼
  PostgreSQL     AWS S3     AWS Textract    AWS Bedrock     FCM
  ──────────     ──────     ────────────    ──────────      ───
  Receipts       Receipt    AnalyzeExp.     Claude Haiku   Push
  Items          images     Structured      OCR cleanup    reminders
  Claims         PDFs       expense                        Device
  Users          Cascade    fields                         tokens
                 deletion   Line items
```

Flutter authenticates with Firebase and passes JWTs to KrakenD. KrakenD validates the token using Firebase's public JWK endpoint and proxies to FastAPI — the backend port is intentionally never exposed directly. FastAPI handles all request-response logic and runs APScheduler jobs for warranty and return deadline reminders.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile** | Flutter 3.41.4 · Dart · Riverpod 2 · Drift/SQLite · Dio |
| **API Gateway** | KrakenD 2.6.0 |
| **Backend** | FastAPI · Python 3.11 · SQLAlchemy · Alembic · Pydantic v2 |
| **Database** | PostgreSQL 15 |
| **OCR & AI** | AWS Textract (AnalyzeExpense) · AWS Bedrock (Claude Haiku) |
| **Storage** | AWS S3 — receipt images and generated PDFs |
| **Auth** | Firebase Auth · Google Sign-In |
| **Notifications** | Firebase Cloud Messaging (FCM) |
| **Infrastructure** | OCI ARM Ampere VM (Always Free) · Docker Compose |
| **Secrets** | Infisical |
| **CI/CD** | GitHub Actions · GHCR · Gitleaks |
| **Monitoring** | Prometheus · Loki · Promtail · cAdvisor · Grafana |

---

## Key Technical Decisions

<details>
<summary><strong>Why a dedicated secrets manager, and why Infisical specifically?</strong></summary>

Storing credentials in a `.env` file on the server means they sit on disk permanently, get included in VM snapshots, and require manual SSH access to rotate. AWS Secrets Manager solves the disk problem but charges per secret per month plus per API call — costs that add up quickly when secrets are fetched on every container restart. HashiCorp Vault is powerful but moved from open-source to a source-available licence in 2023, requires running your own server or paying for a managed plan, and has significant engineering overhead to configure workflows and integrations from scratch. Infisical is MIT-licensed, self-hostable, and has a free cloud tier that covers unlimited secrets, environments, machine identity auth, GitHub Actions integration, and a CLI — everything this stack needs at no cost. In practice, the deploy script fetches database credentials from Infisical before containers start, and the application fetches the remaining secrets at startup. No credentials are written to the server filesystem at any point.

</details>

<details>
<summary><strong>Why KrakenD instead of a plain reverse proxy like Nginx or Caddy?</strong></summary>

KrakenD validates Firebase JWTs at the gateway using Firebase's public JWK endpoint — FastAPI never sees an unauthenticated request. Rate limits are also enforced per endpoint at this layer, with tighter limits on auth routes and looser limits on read endpoints. With a plain reverse proxy you'd have to reimplement both in every service or add middleware. The backend port is also intentionally not exposed in the production compose file — all traffic must enter through the gateway.

</details>

<details>
<summary><strong>Why a separate container for the scheduler instead of running it inside the FastAPI process?</strong></summary>

APScheduler running inside the same uvicorn process means a misbehaving job — a memory leak, an unhandled exception loop, a slow DB query — competes directly with request handling and can bring down the API. A separate container isolates that: the API stays up regardless of what the scheduler does. The alternative would be Celery with Redis, which gives you a proper job queue, distributed workers, and retry visibility — but that's significant infrastructure overhead for three nightly reminder jobs. For the current scale, two containers achieve the failure isolation without the complexity.

</details>

<details>
<summary><strong>Why OCI ARM VM instead of AWS EC2?</strong></summary>

OCI's Always Free tier gives a 4-core ARM Ampere VM with 24 GB RAM and no 12-month expiry. AWS Free Tier expires after a year and the equivalent instance size costs money beyond that. For a pre-revenue app, eliminating infrastructure cost entirely while still running a full production stack — gateway, API, scheduler, database, monitoring — is the obvious call.

</details>

<details>
<summary><strong>Why a modular monolith over microservices?</strong></summary>

Microservices introduce network calls between services, distributed tracing, separate deployment pipelines, and eventually separate databases — all of which add operational complexity that has to be justified by the scale or team size. The backend has clean internal module boundaries (receipts, warranties, claims, notifications, users) without any of that overhead. A single deployment unit, a single database with proper schema separation, and straightforward debugging. Microservices would be the right call if different modules needed to scale independently or if separate teams owned them — neither applies here.

</details>

<details>
<summary><strong>Why AWS Textract with a Claude Haiku cleanup layer instead of a single solution?</strong></summary>

Textract's `AnalyzeExpense` API is purpose-built for receipts — it returns vendor name, total, individual line items, dates, and tax as structured fields without needing a custom model or training data. Google Document AI and Azure AI Document Intelligence both offer custom model training, but that requires labelled training data and ongoing maintenance that's unnecessary when a prebuilt expense model already covers the use case. The stack is also already on AWS, so Textract integrates directly with S3 and Bedrock without cross-cloud authentication or egress costs. Where Textract falls short is bilingual receipts and multi-column layouts where text gets garbled. Claude Haiku handles that with six targeted cleanup passes — each with its own prompt. Using only an LLM would be slower and more expensive for structured extraction; using only Textract leaves the cleanup problem unsolved.

</details>

<details>
<summary><strong>Why does secret scanning gate every other CI job?</strong></summary>

A credential leak in a commit is a more serious problem than a failing test — it's an immediate security incident that requires key rotation regardless of whether the code works. Running backend CI and mobile CI in parallel with the secret scan means those jobs execute against a potentially compromised commit. Gitleaks as the first job, with all other jobs depending on it, ensures nothing else runs until the commit is confirmed clean. Gitleaks also scans the full git history, not just the diff — catching credentials that were added in an earlier commit and "removed" with a follow-up commit, which still exist in the history.

</details>

<details>
<summary><strong>Why smoke test with auto-rollback on deploy?</strong></summary>

A deployment can pass every CI check, build a valid image, and still fail to start in production — a bad migration, a missing environment variable, or a startup exception would leave the app down. The smoke test polls the health endpoint after the new containers start, giving the app time to fetch secrets and the database time to accept connections. If the health check doesn't pass within that window, the deploy script automatically rolls back to the previous image and reverts the database migration. Production is restored without manual intervention.

</details>

---

## CI/CD Pipeline

```
┌──────────┐  ┌──────────────┐  ┌─── PARALLEL ──────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ TRIGGER  │  │   SECURITY   │  │  Backend CI                   │  │  BUILD · main   │  │  DEPLOY · main  │
│          │  │              │  │  ruff · black · mypy          │  │                 │  │                 │
│ Push/PR  ├─>│ Secret Scan  ├─>│  pytest ≥70% · alembic        ├─>│ Docker Build    ├─>│ OCI Deploy      │
│ main     │  │ Gitleaks     │  │  bandit · pip-audit           │  │ arm64 + amd64   │  │ SCP assets      │
│ open PRs │  │ gates all    │  ├───────────────────────────────┤  │ Trivy · SBOM    │  │ deploy script   │
│ manual   │  │ downstream   │  │  Mobile CI                    │  │ Cosign · GHCR   │  │ smoke test      │
└──────────┘  └──────────────┘  │  build_runner · dart format   │  │ sha+latest-prod │  │ Slack on fail   │
                                │  flutter analyze · test ≥60%  │  └─────────────────┘  └─────────────────┘
                                │  Android APK                  │
                                ├───────────────────────────────┤
                                │  KrakenD Config               │
                                │  krakend check                │
                                │  official Docker image        │
                                └───────────────────────────────┘
```

Secret Scan gates all downstream jobs — if Gitleaks finds a credential anywhere in the commit or history, nothing else runs. The three parallel quality gates must all pass before Docker Build starts. Build and deploy only trigger on pushes to `main`.

---

<div align="center">

<a href="https://sujaya.dev/reclaima/"> <img alt="Static Badge" src="https://img.shields.io/badge/%F0%9F%94%97%20Project%20Page-brightgreen?style=for-the-badge"> </a>

<sub>Built with Flutter & FastAPI · Deployed on OCI · Powered by AWS · © 2026 Sujaya Mindev</sub>

</div>
