#!/usr/bin/env bash
set -euo pipefail

if [ "$EVENT_NAME" = "pull_request" ]; then
  BASE_SHA="$PR_BASE_SHA"
else
  BASE_SHA="$PUSH_BASE_SHA"
fi

ORIGINAL_SHA="$(git rev-parse HEAD)"

set +e
flutter analyze --machine --fatal-infos --fatal-warnings > /tmp/flutter_analyze_head.txt 2>&1
HEAD_STATUS=$?
set -e

if [ -z "$BASE_SHA" ] || [ "$BASE_SHA" = "0000000000000000000000000000000000000000" ]; then
  cat /tmp/flutter_analyze_head.txt
  exit $HEAD_STATUS
fi

if ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
  echo "Base SHA not available locally; running analyze on current revision only."
  cat /tmp/flutter_analyze_head.txt
  exit $HEAD_STATUS
fi

git checkout --quiet "$BASE_SHA"
set +e
flutter analyze --machine --fatal-infos --fatal-warnings > /tmp/flutter_analyze_base.txt 2>&1
BASE_STATUS=$?
set -e

git checkout --quiet "$ORIGINAL_SHA"

if [ $BASE_STATUS -ge 2 ]; then
  echo "Base revision Flutter analyze failed unexpectedly; skipping regression comparison."
  cat /tmp/flutter_analyze_head.txt
  exit 0
fi

awk -F' - ' '
  /^[[:space:]]*(error|warning|info) - / {
    sev = $1
    msg = $2
    loc = $3
    code = $4

    if (loc == "" || code == "") {
      next
    }

    gsub(/^[[:space:]]+|[[:space:]]+$/, "", sev)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", code)
    sub(/:[0-9]+:[0-9]+$/, ":<line>", loc)

    print sev " | " msg " | " loc " | " code
  }
' /tmp/flutter_analyze_base.txt | sort -u > /tmp/flutter_analyze_base_issues.txt || true

awk -F' - ' '
  /^[[:space:]]*(error|warning|info) - / {
    sev = $1
    msg = $2
    loc = $3
    code = $4

    if (loc == "" || code == "") {
      next
    }

    gsub(/^[[:space:]]+|[[:space:]]+$/, "", sev)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", code)
    sub(/:[0-9]+:[0-9]+$/, ":<line>", loc)

    print sev " | " msg " | " loc " | " code
  }
' /tmp/flutter_analyze_head.txt | sort -u > /tmp/flutter_analyze_head_issues.txt || true

comm -13 /tmp/flutter_analyze_base_issues.txt /tmp/flutter_analyze_head_issues.txt > /tmp/flutter_analyze_new_issues.txt || true

if [ -s /tmp/flutter_analyze_new_issues.txt ]; then
  echo "New Flutter analyzer findings introduced compared to base commit:"
  cat /tmp/flutter_analyze_new_issues.txt
  echo
  echo "Full Flutter analyze output on target revision:"
  cat /tmp/flutter_analyze_head.txt
  exit 1
fi

if [ $HEAD_STATUS -ne 0 ]; then
  echo "No new Flutter analyzer findings compared to base commit; existing baseline findings tolerated."
  cat /tmp/flutter_analyze_head.txt
  exit 0
fi

echo "Flutter analyze passed on target revision."
