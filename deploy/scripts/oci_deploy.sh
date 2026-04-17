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

echo "Running post-deploy health check: ${HEALTH_URL}"
for attempt in $(seq 1 20); do
  if curl --fail --silent "${HEALTH_URL}" >/dev/null; then
    echo "Deployment succeeded."
    exit 0
  fi
  echo "Health check attempt ${attempt}/20 failed. Retrying..."
  sleep 3
done

echo "Deployment health check failed. Starting rollback..."
if [[ -f "${PREVIOUS_IMAGE_FILE}" ]]; then
  ROLLBACK_IMAGE="$(cat "${PREVIOUS_IMAGE_FILE}")"
  export BACKEND_IMAGE="${ROLLBACK_IMAGE}"
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d api scheduler

  for attempt in $(seq 1 20); do
    if curl --fail --silent "${HEALTH_URL}" >/dev/null; then
      echo "Rollback succeeded using ${ROLLBACK_IMAGE}."
      exit 1
    fi
    echo "Rollback health check attempt ${attempt}/20 failed. Retrying..."
    sleep 3
  done
fi

echo "Rollback failed. Manual intervention required."
exit 1
