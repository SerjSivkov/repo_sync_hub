#!/usr/bin/env bash
# Disable macOS code signing for local unsigned release builds.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_FILE="${ROOT}/macos/Runner.xcodeproj/project.pbxproj"

if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "Missing ${PROJECT_FILE}" >&2
  exit 1
fi

echo "Disabling macOS code signing..."

if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' 's/"CODE_SIGN_IDENTITY\[sdk=macosx\*\]" = "Apple Development"/"CODE_SIGN_IDENTITY[sdk=macosx*]" = "-"/g' "$PROJECT_FILE"
  sed -i '' 's/CODE_SIGN_STYLE = Automatic/CODE_SIGN_STYLE = Manual/g' "$PROJECT_FILE"
  sed -i '' '/DEVELOPMENT_TEAM = /d' "$PROJECT_FILE"
else
  sed -i 's/"CODE_SIGN_IDENTITY\[sdk=macosx\*\]" = "Apple Development"/"CODE_SIGN_IDENTITY[sdk=macosx*]" = "-"/g' "$PROJECT_FILE"
  sed -i 's/CODE_SIGN_STYLE = Automatic/CODE_SIGN_STYLE = Manual/g' "$PROJECT_FILE"
  sed -i '/DEVELOPMENT_TEAM = /d' "$PROJECT_FILE"
fi

echo "macOS code signing disabled."
