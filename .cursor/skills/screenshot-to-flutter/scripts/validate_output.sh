#!/usr/bin/env bash
# Run flutter analyze for screenshot-to-flutter output validation.
set -euo pipefail

PROJECT_ROOT="${1:?Usage: validate_output.sh <project_root> [relative_dart_path]}"
REL_PATH="${2:-}"

cd "$PROJECT_ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: flutter not found in PATH" >&2
  exit 1
fi

echo "==> flutter pub get"
flutter pub get >/dev/null

echo "==> flutter analyze"
if [[ -n "$REL_PATH" ]]; then
  flutter analyze "$REL_PATH"
else
  flutter analyze
fi

echo "OK: analyze passed"
