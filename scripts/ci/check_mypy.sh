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
mypy app > /tmp/mypy_head.txt 2>&1
HEAD_STATUS=$?
set -e

if [ -z "$BASE_SHA" ] || [ "$BASE_SHA" = "0000000000000000000000000000000000000000" ]; then
  cat /tmp/mypy_head.txt
  exit $HEAD_STATUS
fi

if ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
  echo "Base SHA not available locally; running mypy on target revision only."
  cat /tmp/mypy_head.txt
  exit $HEAD_STATUS
fi

git checkout --quiet "$BASE_SHA"
set +e
mypy app > /tmp/mypy_base.txt 2>&1
set -e

git checkout --quiet "$ORIGINAL_SHA"

if [ $HEAD_STATUS -eq 0 ]; then
  echo "Mypy passed on target revision."
  exit 0
fi

grep -E '^[^:]+:[0-9]+: error:' /tmp/mypy_base.txt \
  | sed -E 's#:[0-9]+: error:#: error:#' \
  | sort -u > /tmp/mypy_base_errors.txt || true
grep -E '^[^:]+:[0-9]+: error:' /tmp/mypy_head.txt \
  | sed -E 's#:[0-9]+: error:#: error:#' \
  | sort -u > /tmp/mypy_head_errors.txt || true
comm -13 /tmp/mypy_base_errors.txt /tmp/mypy_head_errors.txt > /tmp/mypy_new_errors.txt || true

if [ -s /tmp/mypy_new_errors.txt ]; then
  echo "New mypy errors introduced compared to base commit:"
  cat /tmp/mypy_new_errors.txt
  echo
  echo "Full mypy output on target revision:"
  cat /tmp/mypy_head.txt
  exit 1
fi

echo "No new mypy errors compared to base commit; existing baseline debt tolerated."
echo "Mypy summary on target revision:"
tail -n 5 /tmp/mypy_head.txt || true
