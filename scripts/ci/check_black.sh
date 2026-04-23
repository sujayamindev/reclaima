#!/usr/bin/env bash
set -euo pipefail

if [ "$EVENT_NAME" = "pull_request" ]; then
  BASE_SHA="$PR_BASE_SHA"
  HEAD_SHA="$PR_HEAD_SHA"
else
  BASE_SHA="$PUSH_BASE_SHA"
  HEAD_SHA="$PUSH_HEAD_SHA"
fi

if [ -z "$BASE_SHA" ] || [ "$BASE_SHA" = "0000000000000000000000000000000000000000" ]; then
  echo "Base SHA unavailable; running Black on app and tests."
  black --check app tests
  exit 0
fi

mapfile -t changed_py_files < <(
  git diff --name-only --diff-filter=ACMR "$BASE_SHA" "$HEAD_SHA" -- '*.py' \
  | sed 's#^backend/##'
)

if [ ${#changed_py_files[@]} -eq 0 ]; then
  echo "No changed Python files detected for Black check."
  exit 0
fi

echo "Black checking changed Python files:"
printf '%s\n' "${changed_py_files[@]}"
black --check "${changed_py_files[@]}"
