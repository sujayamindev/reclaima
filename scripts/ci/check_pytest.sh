#!/usr/bin/env bash
set -euo pipefail

if [ "$EVENT_NAME" = "pull_request" ]; then
  BASE_SHA="$PR_BASE_SHA"
  TARGET_SHA="$PR_HEAD_SHA"
else
  BASE_SHA="$PUSH_BASE_SHA"
  TARGET_SHA="$PUSH_HEAD_SHA"
fi

ORIGINAL_SHA="$(git rev-parse HEAD)"

if [ -n "$TARGET_SHA" ] && [ "$TARGET_SHA" != "$ORIGINAL_SHA" ]; then
  git checkout --quiet "$TARGET_SHA"
fi

set +e
pytest tests \
  --cov=app \
  --cov-config=.coveragerc \
  --cov-report=term-missing \
  --cov-report=xml:/tmp/coverage_head.xml > /tmp/pytest_head.txt 2>&1
HEAD_STATUS=$?
set -e

if [ $HEAD_STATUS -ne 0 ]; then
  cat /tmp/pytest_head.txt
  exit $HEAD_STATUS
fi

if [ -z "$BASE_SHA" ] || [ "$BASE_SHA" = "0000000000000000000000000000000000000000" ]; then
  cat /tmp/pytest_head.txt
  cp /tmp/coverage_head.xml coverage.xml
  exit 0
fi

if ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
  echo "Base SHA not available locally; skipping backend coverage regression comparison."
  cat /tmp/pytest_head.txt
  cp /tmp/coverage_head.xml coverage.xml
  exit 0
fi

git checkout --quiet "$BASE_SHA"
set +e
pytest tests \
  --cov=app \
  --cov-config=.coveragerc \
  --cov-report=term \
  --cov-report=xml:/tmp/coverage_base.xml > /tmp/pytest_base.txt 2>&1
BASE_STATUS=$?
set -e

git checkout --quiet "$ORIGINAL_SHA"

if [ $BASE_STATUS -ne 0 ]; then
  echo "Base revision tests failed; skipping coverage regression comparison."
  cat /tmp/pytest_head.txt
  cp /tmp/coverage_head.xml coverage.xml
  exit 0
fi

COVERAGE_COMPARE_STATUS=0
COVERAGE_FLOOR_STATUS=0
BASE_COVERAGE="$(python -c "import xml.etree.ElementTree as ET; print(float(ET.parse('/tmp/coverage_base.xml').getroot().attrib.get('line-rate', '0')) * 100.0)")"
HEAD_COVERAGE="$(python -c "import xml.etree.ElementTree as ET; print(float(ET.parse('/tmp/coverage_head.xml').getroot().attrib.get('line-rate', '0')) * 100.0)")"
COVERAGE_FLOOR="${BACKEND_COVERAGE_FLOOR:-33.0}"
printf 'Base coverage: %.2f%%\n' "$BASE_COVERAGE"
printf 'Head coverage: %.2f%%\n' "$HEAD_COVERAGE"
printf 'Coverage floor: %.2f%%\n' "$COVERAGE_FLOOR"

python -c "import sys; floor=float('$COVERAGE_FLOOR'); head=float('$HEAD_COVERAGE'); sys.exit(0 if head + 1e-9 >= floor else 2)" || COVERAGE_FLOOR_STATUS=$?

if [ $COVERAGE_FLOOR_STATUS -ne 0 ]; then
  echo "Coverage is below the minimum floor."
  cat /tmp/pytest_head.txt
  exit 1
fi

python -c "import sys; base=float('$BASE_COVERAGE'); head=float('$HEAD_COVERAGE'); sys.exit(0 if head + 1e-9 >= base else 2)" || COVERAGE_COMPARE_STATUS=$?

if [ $COVERAGE_COMPARE_STATUS -ne 0 ]; then
  echo "Coverage regressed compared to base revision."
  cat /tmp/pytest_head.txt
  exit 1
fi

cat /tmp/pytest_head.txt
cp /tmp/coverage_head.xml coverage.xml
