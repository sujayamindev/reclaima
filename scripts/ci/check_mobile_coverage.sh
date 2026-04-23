#!/usr/bin/env bash
set -euo pipefail

EXCLUDE_ARGS=(
  --exclude "**/*.g.dart"
  --exclude "**/*.freezed.dart"
  --exclude "**/generated_plugin_registrant.dart"
)

ORIGINAL_SHA="$(git rev-parse HEAD)"
cp mobile/coverage/lcov.info /tmp/mobile_lcov_head.info

HEAD_COVERAGE="$(python scripts/ci/check_lcov.py /tmp/mobile_lcov_head.info --threshold 0 "${EXCLUDE_ARGS[@]}" | awk '/^Coverage:/ {gsub("%", "", $2); print $2}')"
if [ -z "$HEAD_COVERAGE" ]; then
  echo "Unable to compute head mobile coverage."
  exit 1
fi

printf 'Head mobile coverage: %.2f%%\n' "$HEAD_COVERAGE"

set +e
python -c "import sys; floor=float('${MOBILE_COVERAGE_FLOOR:-60.0}'); head=float('$HEAD_COVERAGE'); sys.exit(0 if head + 1e-9 >= floor else 2)"
COVERAGE_FLOOR_STATUS=$?
set -e
if [ $COVERAGE_FLOOR_STATUS -ne 0 ]; then
  echo "Mobile coverage ${HEAD_COVERAGE}% is below floor ${MOBILE_COVERAGE_FLOOR}%."
  exit 1
fi

if [ "$EVENT_NAME" = "pull_request" ]; then
  BASE_SHA="$PR_BASE_SHA"
else
  BASE_SHA="$PUSH_BASE_SHA"
fi

if [ -z "$BASE_SHA" ] || [ "$BASE_SHA" = "0000000000000000000000000000000000000000" ]; then
  echo "Base SHA unavailable; skipping mobile coverage regression comparison."
  exit 0
fi

if ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
  echo "Base SHA not available locally; skipping mobile coverage regression comparison."
  exit 0
fi

git checkout --quiet "$BASE_SHA"
set +e
(cd mobile && flutter test --coverage > /tmp/flutter_test_base.txt 2>&1)
BASE_TEST_STATUS=$?
set -e

if [ $BASE_TEST_STATUS -ne 0 ]; then
  git checkout --quiet "$ORIGINAL_SHA"
  echo "Base revision mobile tests failed; skipping coverage regression comparison."
  exit 0
fi

cp mobile/coverage/lcov.info /tmp/mobile_lcov_base.info
git checkout --quiet "$ORIGINAL_SHA"

BASE_COVERAGE="$(python scripts/ci/check_lcov.py /tmp/mobile_lcov_base.info --threshold 0 "${EXCLUDE_ARGS[@]}" | awk '/^Coverage:/ {gsub("%", "", $2); print $2}')"
if [ -z "$BASE_COVERAGE" ]; then
  echo "Unable to compute base mobile coverage."
  exit 1
fi

printf 'Base mobile coverage: %.2f%%\n' "$BASE_COVERAGE"

set +e
python -c "import sys; base=float('$BASE_COVERAGE'); head=float('$HEAD_COVERAGE'); sys.exit(0 if head + 1e-9 >= base else 2)"
COVERAGE_COMPARE_STATUS=$?
set -e
if [ $COVERAGE_COMPARE_STATUS -ne 0 ]; then
  echo "Mobile coverage regressed compared to base revision."
  exit 1
fi

echo "Mobile coverage did not regress compared to base revision."
