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
pip-audit -r requirements.txt > /tmp/pip_audit_head.txt 2>&1
HEAD_STATUS=$?
set -e

if [ $HEAD_STATUS -ge 2 ]; then
  cat /tmp/pip_audit_head.txt
  exit $HEAD_STATUS
fi

if [ -z "$BASE_SHA" ] || [ "$BASE_SHA" = "0000000000000000000000000000000000000000" ]; then
  cat /tmp/pip_audit_head.txt
  exit $HEAD_STATUS
fi

if ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
  echo "Base SHA not available locally; running pip-audit on target revision only."
  cat /tmp/pip_audit_head.txt
  exit $HEAD_STATUS
fi

git checkout --quiet "$BASE_SHA"
set +e
pip-audit -r requirements.txt > /tmp/pip_audit_base.txt 2>&1
BASE_STATUS=$?
set -e

git checkout --quiet "$ORIGINAL_SHA"

if [ $BASE_STATUS -ge 2 ]; then
  echo "Base revision pip-audit scan failed; skipping regression comparison."
  cat /tmp/pip_audit_head.txt
  exit 0
fi

awk 'NR > 2 && NF >= 3 {print $1 " | " $3}' /tmp/pip_audit_base.txt \
  | sort -u > /tmp/pip_audit_base_findings.txt || true
awk 'NR > 2 && NF >= 3 {print $1 " | " $3}' /tmp/pip_audit_head.txt \
  | sort -u > /tmp/pip_audit_head_findings.txt || true
comm -13 /tmp/pip_audit_base_findings.txt /tmp/pip_audit_head_findings.txt > /tmp/pip_audit_new_findings.txt || true

if [ -s /tmp/pip_audit_new_findings.txt ]; then
  echo "New dependency vulnerabilities introduced compared to base commit:"
  cat /tmp/pip_audit_new_findings.txt
  echo
  echo "Full pip-audit output on target revision:"
  cat /tmp/pip_audit_head.txt
  exit 1
fi

if [ $HEAD_STATUS -ne 0 ]; then
  echo "No new dependency vulnerabilities compared to base commit; existing baseline findings tolerated."
  cat /tmp/pip_audit_head.txt
  exit 0
fi

echo "pip-audit passed on target revision."
