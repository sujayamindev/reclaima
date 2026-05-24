#!/usr/bin/env bash
set -euo pipefail

: "${GHCR_USERNAME:?GHCR_USERNAME is required}"
: "${GHCR_TOKEN:?GHCR_TOKEN is required}"
: "${IMAGE_REPOSITORY:?IMAGE_REPOSITORY is required}"
: "${IMAGE_TAG:?IMAGE_TAG is required}"
: "${INFISICAL_CLIENT_ID:?INFISICAL_CLIENT_ID is required}"
: "${INFISICAL_CLIENT_SECRET:?INFISICAL_CLIENT_SECRET is required}"
: "${INFISICAL_PROJECT_ID:?INFISICAL_PROJECT_ID is required}"

export INFISICAL_MACHINE_IDENTITY_CLIENT_ID="${INFISICAL_CLIENT_ID}"
export INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET="${INFISICAL_CLIENT_SECRET}"
export INFISICAL_PROJECT_ID="${INFISICAL_PROJECT_ID}"

echo "Fetching deploy-time credentials from Infisical..."
INFISICAL_TOKEN=$(infisical login \
  --method=universal-auth \
  --client-id="${INFISICAL_MACHINE_IDENTITY_CLIENT_ID}" \
  --client-secret="${INFISICAL_MACHINE_IDENTITY_CLIENT_SECRET}" \
  --silent --plain)
export INFISICAL_TOKEN

POSTGRES_PASSWORD=$(infisical secrets get POSTGRES_PASSWORD \
  --env=prod \
  --projectId="${INFISICAL_PROJECT_ID}" \
  --path=/ \
  --plain --silent)
export POSTGRES_PASSWORD

DATABASE_URL=$(infisical secrets get DATABASE_URL \
  --env=prod \
  --projectId="${INFISICAL_PROJECT_ID}" \
  --path=/ \
  --plain --silent)
export DATABASE_URL

DEPLOY_DIR="${DEPLOY_DIR:-/mnt/data/smart-receipt-and-warranty-manager/deploy}"
ENV_FILE="${ENV_FILE:-/mnt/data/smart-receipt-and-warranty-manager/.env.prod}"
COMPOSE_FILE="${COMPOSE_FILE:-${DEPLOY_DIR}/docker-compose.prod.yml}"
API_PORT="${API_PORT:-8000}"
BACKEND_IMAGE="${IMAGE_REPOSITORY}:${IMAGE_TAG}"
PREVIOUS_IMAGE_FILE="${DEPLOY_DIR}/.previous_backend_image"
PREVIOUS_ALEMBIC_REV_FILE="${DEPLOY_DIR}/.previous_alembic_rev"
HEALTH_URL="http://127.0.0.1:${API_PORT}/api/v1/health"
API_CONTAINER="${API_CONTAINER:-smart-receipt-api}"
SCHEDULER_CONTAINER="${SCHEDULER_CONTAINER:-smart-receipt-scheduler}"
SMOKE_TEST_URL="${SMOKE_TEST_URL:-http://127.0.0.1:${API_PORT}/api/v1/receipts?page=1&page_size=1}"
SMOKE_TEST_TOKEN="${SMOKE_TEST_TOKEN:-}"

container_health_status() {
  docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$1" 2>/dev/null || echo "missing"
}

container_running_status() {
  docker inspect --format='{{.State.Status}}' "$1" 2>/dev/null || echo "missing"
}

wait_for_runtime_health() {
  local context="$1"

  for attempt in $(seq 1 20); do
    local api_http_ok=0
    if curl --fail --silent "${HEALTH_URL}" >/dev/null; then
      api_http_ok=1
    fi

    local api_health scheduler_health api_state scheduler_state
    api_health="$(container_health_status "${API_CONTAINER}")"
    scheduler_health="$(container_health_status "${SCHEDULER_CONTAINER}")"
    api_state="$(container_running_status "${API_CONTAINER}")"
    scheduler_state="$(container_running_status "${SCHEDULER_CONTAINER}")"

    local api_ready=0
    local scheduler_ready=0

    if [[ "${api_http_ok}" -eq 1 ]] && [[ "${api_state}" = "running" ]] && { [[ "${api_health}" = "healthy" ]] || [[ "${api_health}" = "none" ]]; }; then
      api_ready=1
    fi

    if [[ "${scheduler_state}" = "running" ]] && { [[ "${scheduler_health}" = "healthy" ]] || [[ "${scheduler_health}" = "none" ]]; }; then
      scheduler_ready=1
    fi

    if [[ "${api_ready}" -eq 1 ]] && [[ "${scheduler_ready}" -eq 1 ]]; then
      echo "${context} succeeded."
      return 0
    fi

    echo "${context} health attempt ${attempt}/20 pending. api_http=${api_http_ok} api_state=${api_state} api_health=${api_health} scheduler_state=${scheduler_state} scheduler_health=${scheduler_health}"
    sleep 3
  done

  return 1
}

read_alembic_revision_from_output() {
  awk '/^[0-9a-f]+/ {print $1; exit}'
}

remove_orphaned_container() {
  local name="$1"
  if ! docker inspect "${name}" &>/dev/null; then
    return 0
  fi
  local project state
  project="$(docker inspect --format='{{index .Config.Labels "com.docker.compose.project"}}' "${name}" 2>/dev/null || true)"
  state="$(docker inspect --format='{{.State.Status}}' "${name}" 2>/dev/null || echo missing)"
  if [[ "${project}" = "smart-receipt-prod" ]]; then
    return 0
  fi
  if [[ "${state}" = "running" ]]; then
    echo "ERROR: Container ${name} is running but belongs to compose project '${project:-none}'." \
         "Remove or stop it manually before deploying." >&2
    exit 1
  fi
  echo "Removing orphaned stopped container ${name} (project: ${project:-none})..."
  docker rm "${name}"
}

run_authenticated_smoke_test() {
  if [[ -z "${SMOKE_TEST_TOKEN}" ]]; then
    echo "SMOKE_TEST_TOKEN not provided; skipping authenticated smoke test."
    return 0
  fi

  local status
  status="$(curl --silent --output /dev/null --write-out "%{http_code}" \
    -H "Authorization: Bearer ${SMOKE_TEST_TOKEN}" \
    "${SMOKE_TEST_URL}")"

  if [[ "${status}" != "200" ]]; then
    echo "Authenticated smoke test failed with HTTP ${status} at ${SMOKE_TEST_URL}."
    return 1
  fi

  echo "Authenticated smoke test passed."
  return 0
}

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "Compose file not found: ${COMPOSE_FILE}" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file not found: ${ENV_FILE}" >&2
  exit 1
fi

cd "${DEPLOY_DIR}"

echo "Logging in to GHCR..."
echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin >/dev/null

BACKEND_IMAGE="${IMAGE_REPOSITORY}:${IMAGE_TAG}"
export BACKEND_IMAGE

CURRENT_IMAGE="$(docker inspect --format='{{.Config.Image}}' smart-receipt-api 2>/dev/null || true)"
if [[ -n "${CURRENT_IMAGE}" ]]; then
  echo "Saving current image for rollback: ${CURRENT_IMAGE}"
  printf '%s\n' "${CURRENT_IMAGE}" > "${PREVIOUS_IMAGE_FILE}"
fi

# Remove any named containers that exist outside this compose project so that
# docker compose up can (re)create them cleanly.
for _orphan in smart-receipt-db smart-receipt-api smart-receipt-scheduler smart-receipt-gateway-prod; do
  remove_orphaned_container "${_orphan}"
done

docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d postgres

PREVIOUS_ALEMBIC_REV="base"
if [[ -n "${CURRENT_IMAGE}" ]]; then
  export BACKEND_IMAGE="${CURRENT_IMAGE}"
  if CURRENT_REVISION_OUTPUT="$(docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" run --rm migrate alembic current 2>&1)"; then
    PARSED_REVISION="$(printf '%s\n' "${CURRENT_REVISION_OUTPUT}" | read_alembic_revision_from_output || true)"
    if [[ -n "${PARSED_REVISION}" ]]; then
      PREVIOUS_ALEMBIC_REV="${PARSED_REVISION}"
    fi
  else
    echo "Warning: Unable to detect current Alembic revision; defaulting rollback target to base."
  fi
fi
printf '%s\n' "${PREVIOUS_ALEMBIC_REV}" > "${PREVIOUS_ALEMBIC_REV_FILE}"
echo "Recorded pre-deploy Alembic revision: ${PREVIOUS_ALEMBIC_REV}"

BACKEND_IMAGE="${IMAGE_REPOSITORY}:${IMAGE_TAG}"
echo "Deploying image ${BACKEND_IMAGE}"
export BACKEND_IMAGE

docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" pull api scheduler migrate krakend
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" run --rm migrate
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d api scheduler krakend
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" restart krakend

echo "Running post-deploy health checks: API endpoint and scheduler container"
if wait_for_runtime_health "Deployment" && run_authenticated_smoke_test; then
  # Start/update monitoring stack if it exists
  MONITORING_COMPOSE="${DEPLOY_DIR}/docker-compose.monitoring.yml"
  if [[ -f "${MONITORING_COMPOSE}" ]]; then
    echo "Starting monitoring stack..."
    docker compose -f "${MONITORING_COMPOSE}" --env-file "${ENV_FILE}" up -d
  fi
  exit 0
fi

echo "Deployment health check failed. Starting rollback..."
if [[ -f "${PREVIOUS_IMAGE_FILE}" ]]; then
  ROLLBACK_IMAGE="$(cat "${PREVIOUS_IMAGE_FILE}")"
  export BACKEND_IMAGE="${ROLLBACK_IMAGE}"

  if [[ -f "${PREVIOUS_ALEMBIC_REV_FILE}" ]]; then
    ROLLBACK_REVISION="$(cat "${PREVIOUS_ALEMBIC_REV_FILE}")"
    if [[ -z "${ROLLBACK_REVISION}" ]]; then
      ROLLBACK_REVISION="base"
    fi

    echo "Rolling back database schema to revision: ${ROLLBACK_REVISION}"
    if ! docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" run --rm migrate alembic downgrade "${ROLLBACK_REVISION}"; then
      echo "Database rollback failed for revision ${ROLLBACK_REVISION}."
      echo "Rollback failed. Manual intervention required."
      exit 1
    fi
  else
    echo "Previous Alembic revision file not found; skipping schema rollback."
  fi

  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d api scheduler

  if wait_for_runtime_health "Rollback" && run_authenticated_smoke_test; then
    echo "Rollback succeeded using ${ROLLBACK_IMAGE}."
    exit 1
  fi
fi

echo "Rollback failed. Manual intervention required."
exit 1
