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
bandit -r app -q > /tmp/bandit_head.txt 2>&1
HEAD_STATUS=$?
set -e

if [ -z "$BASE_SHA" ] || [ "$BASE_SHA" = "0000000000000000000000000000000000000000" ]; then
  cat /tmp/bandit_head.txt
  exit $HEAD_STATUS
fi

if ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
  echo "Base SHA not available locally; running Bandit on target revision only."
  cat /tmp/bandit_head.txt
  exit $HEAD_STATUS
fi

git checkout --quiet "$BASE_SHA"
set +e
bandit -r app -q > /tmp/bandit_base.txt 2>&1
BASE_STATUS=$?
set -e

git checkout --quiet "$ORIGINAL_SHA"

if [ $BASE_STATUS -ge 2 ]; then
  echo "Base revision Bandit scan failed; skipping regression comparison."
  cat /tmp/bandit_head.txt
  exit 0
fi

awk '
  /^>> Issue: \[/ {issue=$0}
  /^   Location: / {
    location=$0
    sub(/:[0-9]+:[0-9]+$/,":<line>", location)
    sub(/:[0-9]+$/,":<line>", location)
    if (issue != "") print issue " | " location
  }
' /tmp/bandit_base.txt | sort -u > /tmp/bandit_base_findings.txt || true

awk '
  /^>> Issue: \[/ {issue=$0}
  /^   Location: / {
    location=$0
    sub(/:[0-9]+:[0-9]+$/,":<line>", location)
    sub(/:[0-9]+$/,":<line>", location)
    if (issue != "") print issue " | " location
  }
' /tmp/bandit_head.txt | sort -u > /tmp/bandit_head_findings.txt || true

comm -13 /tmp/bandit_base_findings.txt /tmp/bandit_head_findings.txt > /tmp/bandit_new_findings.txt || true

if [ -s /tmp/bandit_new_findings.txt ]; then
  echo "New Bandit findings introduced compared to base commit:"
  cat /tmp/bandit_new_findings.txt
  echo
  echo "Full Bandit output on target revision:"
  cat /tmp/bandit_head.txt
  exit 1
fi

if [ $HEAD_STATUS -ne 0 ]; then
  echo "No new Bandit findings compared to base commit; existing baseline findings tolerated."
  cat /tmp/bandit_head.txt
  exit 0
fi

echo "Bandit passed on target revision."
