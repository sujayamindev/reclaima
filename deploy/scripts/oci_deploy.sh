#!/usr/bin/env bash
set -euo pipefail

: "${GHCR_USERNAME:?GHCR_USERNAME is required}"
: "${GHCR_TOKEN:?GHCR_TOKEN is required}"
: "${IMAGE_REPOSITORY:?IMAGE_REPOSITORY is required}"
: "${IMAGE_TAG:?IMAGE_TAG is required}"

DEPLOY_DIR="${DEPLOY_DIR:-/mnt/data/smart-receipt-and-warranty-manager/deploy}"
ENV_FILE="${ENV_FILE:-/mnt/data/smart-receipt-and-warranty-manager/.env.prod}"
COMPOSE_FILE="${COMPOSE_FILE:-${DEPLOY_DIR}/docker-compose.prod.yml}"
API_PORT="${API_PORT:-8000}"
BACKEND_IMAGE="${IMAGE_REPOSITORY}:${IMAGE_TAG}"
PREVIOUS_IMAGE_FILE="${DEPLOY_DIR}/.previous_backend_image"
HEALTH_URL="http://127.0.0.1:${API_PORT}/api/v1/health"
API_CONTAINER="${API_CONTAINER:-smart-receipt-api}"
SCHEDULER_CONTAINER="${SCHEDULER_CONTAINER:-smart-receipt-scheduler}"

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

CURRENT_IMAGE="$(docker inspect --format='{{.Config.Image}}' smart-receipt-api 2>/dev/null || true)"
if [[ -n "${CURRENT_IMAGE}" ]]; then
  echo "Saving current image for rollback: ${CURRENT_IMAGE}"
  printf '%s\n' "${CURRENT_IMAGE}" > "${PREVIOUS_IMAGE_FILE}"
fi

echo "Deploying image ${BACKEND_IMAGE}"
export BACKEND_IMAGE

docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" pull api scheduler migrate
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d postgres
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" run --rm migrate
docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d api scheduler

echo "Running post-deploy health checks: API endpoint and scheduler container"
if wait_for_runtime_health "Deployment"; then
  exit 0
fi

echo "Deployment health check failed. Starting rollback..."
if [[ -f "${PREVIOUS_IMAGE_FILE}" ]]; then
  ROLLBACK_IMAGE="$(cat "${PREVIOUS_IMAGE_FILE}")"
  export BACKEND_IMAGE="${ROLLBACK_IMAGE}"
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d api scheduler

  if wait_for_runtime_health "Rollback"; then
    echo "Rollback succeeded using ${ROLLBACK_IMAGE}."
    exit 1
  fi
fi

echo "Rollback failed. Manual intervention required."
exit 1
